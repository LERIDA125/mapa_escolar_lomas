"""Deriva un índice de calles offline a partir del seed de escuelas.

El aspirante no puede geocodificar su domicilio sin internet (la app es
offline-first), así que en vez de salir a la red se reutiliza lo que ya está
en el padrón: cada escuela trae dirección y coordenadas. Agrupando las
escuelas por calle se obtiene un punto representativo por calle, suficiente
para que el selector de origen vuele al barrio correcto y el usuario afine
arrastrando el pin.

Entrada: `assets/escuelas_seed.json`
Salida:  `assets/calles_lomas.json`

    [{ "name": "CAMPANA", "search": "campana",
       "latitude": -34.76, "longitude": -58.40,
       "bounds": { "south": ..., "west": ..., "north": ..., "east": ... } }]

`search` viene prenormalizado (minúsculas, sin tildes, sin puntuación) para
que el lado Dart no tenga que replicar exactamente la normalización de Python.
"""

import json
import re
import sys
import unicodedata
from pathlib import Path

ARCHIVO_SEED = Path("assets/escuelas_seed.json")
ARCHIVO_INDICE = Path("assets/calles_lomas.json")

# Una calle cuyos puntos de referencia están más lejos que esto probablemente
# sea un nombre repetido en dos localidades distintas: el centroide cae en el
# medio de la nada y conviene revisarlo a mano.
SPREAD_ALERTA_KM = 2.0


def sin_tildes(texto):
    return (
        unicodedata.normalize("NFKD", texto)
        .encode("ascii", "ignore")
        .decode("ascii")
    )


def normalizar(texto):
    """Clave de búsqueda: minúsculas, sin tildes, solo alfanumérico y espacios."""
    limpio = sin_tildes(texto).lower()
    limpio = re.sub(r"[^a-z0-9 ]", " ", limpio)
    return re.sub(r"\s+", " ", limpio).strip()


def calle_de(direccion):
    """Extrae el nombre de calle de una dirección del padrón.

    Soporta las tres formas que aparecen en el dataset:

        "PENNA 93"                              -> "PENNA"
        "ELIZALDE Y CALLE 7"                    -> "ELIZALDE"
        "CAMPANA 534 E/PLUMERILLO Y M BRAVO"    -> "CAMPANA"
    """
    original = re.sub(r"\s+", " ", direccion.strip().upper())

    # Cortar en la intersección: la primera calle es la que identifica.
    principal = re.split(r"\s+Y\s+|\s+E/|\s+ESQ\.?\s+", original)[0].strip()

    # Quitar la altura final ("PENNA 93" -> "PENNA").
    coincidencia = re.match(r"^(.*?)\s+(\d{1,5})$", principal)
    if coincidencia:
        calle = coincidencia.group(1).strip(" .,-")
        # "CALLE 7" no es la calle "CALLE": se conserva el número.
        if calle.upper() in {"CALLE", "AV", "AV.", "AVENIDA"}:
            return principal.strip(" .,-")
        return calle

    return principal.strip(" .,-")


def distancia_km(a, b):
    from math import asin, cos, radians, sin, sqrt

    lat1, lon1 = radians(a[0]), radians(a[1])
    lat2, lon2 = radians(b[0]), radians(b[1])
    dlat, dlon = lat2 - lat1, lon2 - lon1
    h = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    return 2 * 6371.0 * asin(sqrt(min(1.0, h)))


def main():
    if not ARCHIVO_SEED.exists():
        print(f"Error: no se encuentra {ARCHIVO_SEED}")
        sys.exit(1)

    escuelas = json.loads(ARCHIVO_SEED.read_text(encoding="utf-8"))

    grupos = {}
    for escuela in escuelas:
        nombre = calle_de(escuela["address"])
        if not nombre:
            continue
        grupos.setdefault(nombre, []).append(
            (escuela["latitude"], escuela["longitude"])
        )

    calles = []
    sospechosas = []
    for nombre, puntos in grupos.items():
        latitud = sum(p[0] for p in puntos) / len(puntos)
        longitud = sum(p[1] for p in puntos) / len(puntos)

        if len(puntos) > 1:
            spread = max(
                distancia_km(a, b) for a in puntos for b in puntos
            )
            if spread > SPREAD_ALERTA_KM:
                sospechosas.append((nombre, round(spread, 2), len(puntos)))

        # Los bounds permiten que el mapa encuadre la calle entera: una
        # avenida de 5 km no se puede representar con un solo punto.
        calles.append(
            {
                "name": nombre,
                "search": normalizar(nombre),
                "latitude": round(latitud, 6),
                "longitude": round(longitud, 6),
                "bounds": {
                    "south": round(min(p[0] for p in puntos), 6),
                    "west": round(min(p[1] for p in puntos), 6),
                    "north": round(max(p[0] for p in puntos), 6),
                    "east": round(max(p[1] for p in puntos), 6),
                },
            }
        )

    calles.sort(key=lambda c: c["name"])
    calles = [c for c in calles if c["search"]]

    ARCHIVO_INDICE.write_text(
        json.dumps(calles, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"Índice generado: {len(calles)} calles en {ARCHIVO_INDICE}")
    print(f"  escuelas usadas: {len(escuelas)}")
    if sospechosas:
        print(f"  calles con puntos dispersos (>{SPREAD_ALERTA_KM} km):")
        for nombre, spread, cantidad in sorted(sospechosas, key=lambda x: -x[1]):
            print(f"    {spread:5.2f} km  {nombre}  ({cantidad} escuelas)")


if __name__ == "__main__":
    main()
