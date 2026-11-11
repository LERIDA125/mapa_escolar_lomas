#!/usr/bin/env python3
"""Auditoría GPS del seed de escuelas.

Contrapone las coordenadas guardadas en `auditoria_escuelas.csv` contra las que
devuelve Nominatim para esa misma dirección. Todo desvío mayor al umbral
(400 m por defecto) se reporta en rojo, igual que una dirección que Nominatim
no logra resolver.

Uso:
    python auditoria_gps.py
    python auditoria_gps.py --limit 10
    python auditoria_gps.py --threshold 250 --delay 1.2

Salida: código 1 si hubo al menos una alerta, 0 si todas las escuelas quedaron
dentro del umbral (sirve para encadenarlo en CI).
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
import time
from pathlib import Path

from geopy.distance import geodesic
from geopy.exc import GeocoderServiceError, GeocoderTimedOut, GeocoderUnavailable
from geopy.geocoders import Nominatim

BASE_DIR = Path(__file__).resolve().parent
CSV_PATH = BASE_DIR / "auditoria_escuelas.csv"
CACHE_PATH = BASE_DIR / "auditoria_gps_cache.json"

# Nominatim exige identificar la app y no superar 1 request por segundo.
USER_AGENT = "MapaEscolarLomas/1.2 (auditoria-gps)"
DEFAULT_DELAY = 1.2
DEFAULT_THRESHOLD_M = 400.0

# Abreviaturas del CSV -> nombre que Nominatim reconoce. Sin esto, "V. ALBERTINA"
# o "BO. EL FARO" no resuelven y la auditoría se llena de falsos positivos.
LOCALITY_ALIASES = {
    "LOMAS DE Z": "Lomas de Zamora",
    "LOMAS DE Z.": "Lomas de Zamora",
    "LOMAS DE ZAMORA": "Lomas de Zamora",
    "BANFIELD": "Banfield",
    "TEMPERLEY": "Temperley",
    "LLAVALLOL": "Llavallol",
    "TURDERA": "Turdera",
    "SAN JOSE": "Barrio San José",
    "FIORITO": "Villa Fiorito",
    "V.FIORITO": "Villa Fiorito",
    "V. FIORITO": "Villa Fiorito",
    "BUDGE": "Ingeniero Budge",
    "V. ALBERTINA": "Villa Albertina",
    "V. URBANA": "Villa Urbana",
    "V URBANA": "Villa Urbana",
    "V. LAMADRID": "Villa Lamadrid",
    "V LAMADRID": "Villa Lamadrid",
    "V. INDEP": "Villa Independencia",
    "V. INDEPENDEN": "Villa Independencia",
    "STA. MARTA": "Santa Marta",
    "STA CATALINA": "Santa Catalina",
    "STA. CATALINA": "Santa Catalina",
    "BO. EL FARO": "Barrio El Faro",
    "B. EL FARO": "Barrio El Faro",
    "BO. LA LOMA": "La Loma",
    "BO. 2 DE ABRIL": "Barrio 2 de Abril",
    "2 DE ABRIL": "Barrio 2 de Abril",
    "BO. OLIMPO": "Barrio Olimpo",
    "OLIMPO": "Barrio Olimpo",
    "BO ODISA": "Barrio Odisea",
    "BO. ODISA": "Barrio Odisea",
    "J. M. DE ROSAS": "Barrio Juan Manuel de Rosas",
    "J. M DE ROSAS": "Barrio Juan Manuel de Rosas",
    "JUAN M. DE ROS": "Barrio Juan Manuel de Rosas",
    "JUAN M. DE ROSA": "Barrio Juan Manuel de Rosas",
    "PQUE LOMAS": "Parque Lomas",
    "PQUE. LOMAS": "Parque Lomas",
    "V.CENTENARIO": "Villa Centenario",
    "V. CENTENARIO": "Villa Centenario",
}


STREET_ALIASES = {
    "ALTE.": "Almirante",
    "AV.": "Avenida",
    "AVDA.": "Avenida",
    "CNO.": "Camino",
    "GRAL.": "General",
    "CNEL.": "Coronel",
    "TTE.": "Teniente",
}


class Color:
    """ANSI mínimo, desactivable con NO_COLOR o cuando no hay terminal."""

    enabled = sys.stdout.isatty() and not os.environ.get("NO_COLOR")
    RED = "\033[91m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    RESET = "\033[0m"

    @classmethod
    def paint(cls, text: str, *styles: str) -> str:
        if not cls.enabled:
            return text
        return "".join(styles) + text + cls.RESET


def enable_windows_ansi() -> None:
    """Habilita secuencias ANSI en consolas viejas de Windows."""
    if sys.platform != "win32" or not Color.enabled:
        return
    try:
        import ctypes

        kernel32 = ctypes.windll.kernel32
        kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
    except Exception:
        Color.enabled = False


def repair_coord(raw: str, prefix: str) -> float:
    """Deshace el daño de Excel sobre latitude/longitude.

    Excel exportó los decimales con separador de miles y a veces con la
    precisión completa del double: -34.7581943 -> -347.581.943,
    y -34.7441280507186 -> -3.474.412.805.071.860. En todos los casos el valor
    conserva sus dígitos, sólo se movió el punto, así que alcanza con quitar
    todo lo que no sea dígito y reinsertar un punto después de los dos dígitos
    enteros (34 para latitud, 58 para longitud).
    """
    digits = re.sub(r"\D", "", raw)
    if not digits.startswith(prefix):
        raise ValueError(f"coordenada inesperada: {raw!r}")
    value = float(f"{prefix}.{digits[len(prefix):]}")
    return -value if raw.strip().startswith("-") else value


def collapse(text: str) -> str:
    return re.sub(r"\s+", " ", (text or "").replace("\xa0", " ")).strip()


def normalize_address(address: str) -> str:
    """Expande abreviaturas de calle que Nominatim no reconoce (ALTE. BROWN)."""
    text = collapse(address)
    for short, full in STREET_ALIASES.items():
        text = re.sub(
            rf"(?<![A-Za-z]){re.escape(short)}", full, text, flags=re.IGNORECASE
        )
    return text


def build_queries(row: dict) -> list[str]:
    """Escalera de queries: barrio primero, partido como red de contención.

    El CSV trae barrios abreviados o con el barrio equivocado (907 figura en
    Banfield pero la calle es de Lomas), así que si la query anclada al barrio
    no resuelve, se reintenta sólo con el partido antes de declararla perdida.
    """
    address = normalize_address(row["address"])
    zone = collapse(row["zone"])
    locality = LOCALITY_ALIASES.get(zone.upper(), zone.title())
    queries = [f"{address}, {locality}, Lomas de Zamora, Buenos Aires, Argentina"]
    if locality.lower() != "lomas de zamora":
        queries.append(f"{address}, Lomas de Zamora, Buenos Aires, Argentina")
    return queries


class Cache:
    """Resultados por query: evita repetir 310 requests en cada corrida."""

    def __init__(self, path: Path):
        self.path = path
        try:
            self.data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            self.data = {}

    def get(self, query: str):
        return self.data.get(query)

    def put(self, query: str, value) -> None:
        self.data[query] = value
        try:
            self.path.write_text(
                json.dumps(self.data, ensure_ascii=False, indent=2), encoding="utf-8"
            )
        except OSError:
            pass


def geocode(geolocator: Nominatim, cache: Cache, query: str, delay: float):
    """Devuelve (lat, lon) o None si Nominatim no encuentra la dirección."""
    if query in cache.data:
        return cache.get(query)

    time.sleep(delay)  # política de uso de Nominatim: 1 req/s como máximo
    result = None
    for attempt in (1, 2):
        try:
            location = geolocator.geocode(query, exactly_one=True, timeout=20)
            if location is not None:
                result = [location.latitude, location.longitude]
            break
        except (GeocoderTimedOut, GeocoderUnavailable, GeocoderServiceError) as exc:
            if attempt == 2:
                print(Color.paint(f"    ! Nominatim falló: {exc}", Color.YELLOW))
            else:
                time.sleep(delay * 2)

    cache.put(query, result)
    return result


def alert_school(label: str, address: str, coords: str, detail: str) -> None:
    print(Color.paint(f"  ALERTA: {label}", Color.BOLD, Color.RED))
    print(Color.paint(f"    Direccion:    {address}", Color.RED))
    print(Color.paint(f"    CSV:          {coords}", Color.RED))
    print(Color.paint(f"    Desvio:       {detail}", Color.RED))


def audit(threshold: float, delay: float, limit: int | None) -> int:
    with CSV_PATH.open(encoding="utf-8-sig", newline="") as handle:
        rows = list(csv.DictReader(handle, delimiter=";"))
    if limit:
        rows = rows[:limit]

    geolocator = Nominatim(user_agent=USER_AGENT)
    cache = Cache(CACHE_PATH)

    total = len(rows)
    alerts = 0
    unresolved = 0
    ok = 0

    print(
        f"Auditando {total} escuelas | umbral {threshold:.0f} m | "
        f"delay {delay:.1f}s"
    )

    for index, row in enumerate(rows, start=1):
        name = collapse(row["nombre"]) or "(sin nombre)"
        address = collapse(row["address"])
        print(f"[{index}/{total}] {name} - {address}")

        try:
            csv_lat = repair_coord(row["latitude"], "34")
            csv_lon = repair_coord(row["longitude"], "58")
        except ValueError:
            alerts += 1
            print(Color.paint(f"  ALERTA: {name}", Color.BOLD, Color.RED))
            print(
                Color.paint(
                    f"    Coordenada ilegible en el CSV: "
                    f"{row['latitude']} / {row['longitude']}",
                    Color.RED,
                )
            )
            continue

        queries = build_queries(row)
        hit = None
        for query in queries:
            hit = geocode(geolocator, cache, query, delay)
            if hit is not None:
                break

        if hit is None:
            unresolved += 1
            alerts += 1
            alert_school(
                name,
                address,
                f"({csv_lat}, {csv_lon})",
                f'sin resultado de Nominatim para "{queries[0]}"',
            )
            continue

        meters = geodesic((csv_lat, csv_lon), tuple(hit)).meters
        if meters > threshold:
            alerts += 1
            alert_school(
                name,
                address,
                f"({csv_lat}, {csv_lon})",
                f"{meters:.0f} m - Nominatim ({hit[0]:.6f}, {hit[1]:.6f})",
            )
        else:
            ok += 1
            print(Color.paint(f"    ok - {meters:.0f} m", Color.DIM, Color.GREEN))

    print()
    print(
        f"Total: {total} | Dentro del umbral: {ok} | "
        f"Alertas: {alerts} (sin resultado: {unresolved})"
    )
    return 1 if alerts else 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Auditoría GPS del seed escolar.")
    parser.add_argument(
        "--threshold",
        type=float,
        default=DEFAULT_THRESHOLD_M,
        help="desvío máximo tolerado en metros (default: 400)",
    )
    parser.add_argument(
        "--delay",
        type=float,
        default=DEFAULT_DELAY,
        help="segundos entre requests a Nominatim (default: 1.2)",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="auditar sólo las primeras N escuelas (para probar)",
    )
    args = parser.parse_args()

    if not CSV_PATH.exists():
        print(Color.paint(f"No existe {CSV_PATH}", Color.RED), file=sys.stderr)
        return 2

    enable_windows_ansi()
    return audit(args.threshold, args.delay, args.limit)


if __name__ == "__main__":
    raise SystemExit(main())
