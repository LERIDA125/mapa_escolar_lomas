#!/usr/bin/env python3
"""Reparador automático del nomenclador escolar.

El CSV de auditoría salió de Excel con las coordenadas rotas: el separador de
miles y la precisión del double movieron el punto decimal (-34.7581943 quedó
como -347.581.943). Este script:

1. Deshace ese daño en TODAS las filas.
2. Vuelve a geolocalizar con ArcGIS (geopy) las direcciones que son una
   intersección ("CALLE Y CALLE" o "CALLE e/ CALLE"), porque ahí la coordenada
   exportada no es confiable.
3. Exporta escuelas_reparadas_final.csv conservando el resto de las columnas.

Uso:
    python reparador_automatico.py

Entrada:  auditoria_escuelas.csv
Salida:   escuelas_reparadas_final.csv
"""

from __future__ import annotations

import csv
import json
import re
import sys
import time
import unicodedata
from pathlib import Path

from geopy.distance import geodesic
from geopy.exc import GeocoderServiceError, GeocoderTimedOut, GeocoderUnavailable
from geopy.geocoders import ArcGIS

# --- Configuración ---------------------------------------------------------

ARCHIVO_ENTRADA = "auditoria_escuelas.csv"
ARCHIVO_SALIDA = "escuelas_reparadas_final.csv"
ARCHIVO_REVISION = "revision_manual.csv"
ARCHIVO_CACHE = "reparador_geocode_cache.json"

BASE_DIR = Path(__file__).resolve().parent
RUTA_ENTRADA = BASE_DIR / ARCHIVO_ENTRADA
RUTA_SALIDA = BASE_DIR / ARCHIVO_SALIDA
RUTA_REVISION = BASE_DIR / ARCHIVO_REVISION
RUTA_CACHE = BASE_DIR / ARCHIVO_CACHE

DELIMITADOR = ";"
ENCODING = "utf-8-sig"
USER_AGENT = "MapaEscolarLomas/1.2 (reparador-automatico)"
DELAY_ARCGIS = 0.5
TIMEOUT = 20
REINTENTOS = 2
AVISO_DESVIO_M = 3000.0

PARTIDO = "Lomas de Zamora, Buenos Aires, Argentina"

# Caja que contiene al partido de Lomas de Zamora. Sirve para descartar
# homónimos de otras localidades: ArcGIS devuelve "Colón y Guido Spano" en
# Moreno si no se acota.
LAT_MIN, LAT_MAX = -34.90, -34.62
LON_MIN, LON_MAX = -58.60, -58.28

# Palabras que no identifican una calle: se descartan al comparar la dirección
# pedida contra la que devuelve ArcGIS.
STOPWORDS = {
    "calle", "avenida", "av", "avda", "camino", "diagonal", "pasaje",
    "de", "del", "la", "las", "los", "el", "y", "e", "entre",
    "barrio", "bo", "b", "provincia", "buenos", "aires", "argentina",
    "lomas", "zamora", "general", "gral", "coronel", "cnel",
    "teniente", "tte", "presidente", "pte", "almirante", "alte",
    "santa", "sta", "santos", "stos", "san", "santo", "soldado",
    "intendente", "doctor", "dr", "ingeniero", "ing",
}

# Si ArcGIS devuelve una dirección de otro partido, el match no sirve aunque
# caiga dentro del bounding box (Burzaco, por ejemplo, está al lado).
PARTIDOS_AJENOS = (
    "almirante brown", "lanus", "avellaneda", "quilmes",
    "esteban echeverria", "ezeiza", "presidente peron", "la matanza",
    "berazategui", "florencio varela",
)

LOCALIDADES_AJENAS = (
    "burzaco", "adrogue", "longchamps", "glew", "jose marmol",
    "ministro rivadavia", "san francisco solano", "ravino",
    "monte grande", "el jaguel", "canning", "san vicente",
    "tristan suarez", "la union", "quilmes", "berazategui",
)

# Abreviaturas del nomenclador -> nombre que ArcGIS reconoce.
LOCALIDADES = {
    "LOMAS DE Z": "Lomas de Zamora",
    "LOMAS DE Z.": "Lomas de Zamora",
    "LOMAS DE ZAMORA": "Lomas de Zamora",
    "BANFIELD": "Banfield",
    "TEMPERLEY": "Temperley",
    "LLAVALLOL": "Llavallol",
    "TURDERA": "Turdera",
    "SAN JOSE": "Barrio San José",
    "S. JOSE": "Barrio San José",
    "FIORITO": "Villa Fiorito",
    "V.FIORITO": "Villa Fiorito",
    "V. FIORITO": "Villa Fiorito",
    "BUDGE": "Ingeniero Budge",
    "ING. BUDGE": "Ingeniero Budge",
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
    "LA LOMA": "La Loma",
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
    "B NUEVA ESPERANZA": "Barrio Nueva Esperanza",
    "B. NUEVA ESPERANZA": "Barrio Nueva Esperanza",
    "CEMENTERIO": "Lomas de Zamora",
    "CTEL IX": "Lomas de Zamora",
    "CTEL. IX": "Lomas de Zamora",
    "TRIBUNALES": "Lomas de Zamora",
    "SIN ESPECIFICAR": "Lomas de Zamora",
}

# Localidades y barrios que pertenecen al partido. Sólo se comparan los que
# están acá: si la zona del CSV es una abreviatura que no reconocemos, no hay
# con qué contrastar y no se emite aviso.
LOCALIDADES_CONOCIDAS = {
    "lomas de zamora",
    "banfield",
    "temperley",
    "turdera",
    "llavallol",
    "ingeniero budge",
    "villa fiorito",
    "villa albertina",
    "villa urbana",
    "villa lamadrid",
    "villa independencia",
    "villa centenario",
    "santa marta",
    "santa catalina",
    "san jose",
    "la loma",
    "parque lomas",
    "el faro",
    "2 de abril",
    "olimpo",
    "odisea",
    "juan manuel de rosas",
    "nueva esperanza",
}

ABREVIATURAS = {
    "ALTE.": "Almirante",
    "ANT.": "Antártida",
    "AV.": "Avenida",
    "AVDA.": "Avenida",
    "CNO.": "Camino",
    "GRAL.": "General",
    "CNEL.": "Coronel",
    "TTE.": "Teniente",
    "PTE.": "Presidente",
    "STA.": "Santa",
    "STOS.": "Santos",
    "DIAG.": "Diagonal",
    "PJE.": "Pasaje",
}

PATRON_INTERSECCION = re.compile(r"(?i)\s+y\s+|\s+e/\s*")
PATRON_E_ENTRE = re.compile(r"(?i)\s+e/\s*")
PATRON_Y = re.compile(r"(?i)\s+y\s+")
# ArcGIS devuelve "Calle A & Calle B" cuando resolvió una esquina.
PATRON_ESQUINA = re.compile(r"&")
# Y "Calle A 879" cuando resolvió una altura sobre la calle.
PATRON_ALTURA = re.compile(r"\b\d{1,5}\b")


# --- Utilidades de texto ---------------------------------------------------


def colapsar(texto: str) -> str:
    """Normaliza espacios (incluido el NBSP que mete Excel)."""
    return re.sub(r"\s+", " ", (texto or "").replace("\xa0", " ")).strip()


def sin_duplicados(items: list[str]) -> list[str]:
    vistos: set[str] = set()
    resultado: list[str] = []
    for item in items:
        clave = item.casefold()
        if clave not in vistos:
            vistos.add(clave)
            resultado.append(item)
    return resultado


def normalizar_texto(texto: str) -> str:
    """Minúsculas y sin acentos, para comparar direcciones."""
    descompuesto = unicodedata.normalize("NFKD", texto or "")
    plano = "".join(c for c in descompuesto if not unicodedata.combining(c))
    return plano.lower()


def tokens_significativos(direccion: str) -> set[str]:
    """Nombres de calle utilizables, sin artículos ni abreviaturas genéricas."""
    palabras = re.findall(r"[a-z0-9]+", normalizar_texto(direccion))
    return {p for p in palabras if len(p) >= 4 and p not in STOPWORDS}


def palabras(texto: str) -> set[str]:
    """Palabras normalizadas de un texto, sin acentos ni puntuación."""
    return set(re.findall(r"[a-z0-9]+", normalizar_texto(texto)))


def aparece(token: str, vocabulario: set[str]) -> bool:
    """True si el token está en el vocabulario o comparte raíz con una palabra."""
    if token in vocabulario:
        return True
    if len(token) < 4:
        return False
    return any(
        palabra.startswith(token) or token.startswith(palabra)
        for palabra in vocabulario
        if len(palabra) >= 4
    )


def lados_de_interseccion(direccion: str) -> list[set[str]]:
    """Tokens significativos de cada lado de la esquina, sin lados vacíos."""
    texto = normalizar_direccion(direccion)
    separador = PATRON_E_ENTRE.search(texto)
    if separador:
        # "CALLE e/ CRUCE1 Y CRUCE2" -> lados: CALLE y CRUCE1.
        calle = texto[: separador.start()]
        primer_cruce = PATRON_Y.split(texto[separador.end() :], maxsplit=1)[0]
        lados = [calle, primer_cruce]
    elif PATRON_Y.search(texto):
        lados = PATRON_Y.split(texto, maxsplit=1)
    else:
        lados = [texto]

    resultado: list[set[str]] = []
    for lado in lados:
        tokens = tokens_significativos(lado)
        if tokens:
            resultado.append(tokens)
    return resultado


def evaluar_match(direccion_pedida: str, direccion_match: str) -> tuple[bool, list[str]]:
    """Decide si el match sirve y devuelve los avisos que correspondan.

    El criterio es estructural: un resultado válido es una esquina
    ("Calle A & Calle B") o una altura sobre la calle ("Calle A 879").
    Un centroide de calle ("Olimpo", "Camino de Cintura") no sirve: no tiene
    ni cruce ni altura, y era lo que se colaba con la validación anterior.
    """
    lados = lados_de_interseccion(direccion_pedida)
    vocabulario = palabras(direccion_match)

    lados_ok = [any(aparece(token, vocabulario) for token in lado) for lado in lados]
    if lados and not any(lados_ok):
        return False, ["ninguna de las calles pedidas aparece en el match"]

    if not (PATRON_ESQUINA.search(direccion_match) or PATRON_ALTURA.search(direccion_match)):
        return False, ["el match es un centroide de calle, no una esquina ni una altura"]

    avisos: list[str] = []
    if lados and not all(lados_ok):
        avisos.append("coincidencia parcial: falta un lado de la esquina en el match")
    return True, avisos


def canon_localidad(texto: str) -> str:
    """Normaliza una localidad o barrio para poder compararlos entre sí."""
    limpio = re.sub(r"^(barrio|bo\.?|b\.)\s+", "", normalizar_texto(texto))
    return limpio.strip()


def localidad_del_match(direccion_match: str) -> str:
    """Localidad que ArcGIS ubica justo antes de "Lomas de Zamora"."""
    partes = [colapsar(parte) for parte in (direccion_match or "").split(",")]
    for indice, parte in enumerate(partes):
        if indice > 0 and "lomas de zamora" in normalizar_texto(parte):
            return canon_localidad(partes[indice - 1])
    return ""


def aviso_localidad(zona: str, direccion_match: str) -> str | None:
    """Aviso cuando la localidad del match no coincide con la zona del CSV.

    Es un aviso y no un rechazo: las abreviaturas de barrio del nomenclador
    ("BO. 2 DE ABRIL") no siempre tienen un equivalente en el callejero, y
    rechazar por eso tiraría matches buenos.
    """
    esperada = canon_localidad(normalizar_localidad(zona))
    obtenida = localidad_del_match(direccion_match)
    if esperada not in LOCALIDADES_CONOCIDAS or obtenida not in LOCALIDADES_CONOCIDAS:
        return None
    if esperada == obtenida:
        return None
    return f"localidad distinta: CSV dice {esperada!r}, ArcGIS devolvio {obtenida!r}"


def menciona_partido_ajeno(direccion_match: str) -> bool:
    """True si el match pertenece a otro partido o a una localidad vecina."""
    texto = normalizar_texto(direccion_match)
    if "lomas de zamora" in texto:
        return False
    return any(
        nombre in texto for nombre in (*PARTIDOS_AJENOS, *LOCALIDADES_AJENAS)
    )


def normalizar_direccion(direccion: str) -> str:
    """Limpia paréntesis, 'ENTRE' inicial y abreviaturas de calle."""
    texto = colapsar(direccion)
    texto = re.sub(r"\([^)]*\)", "", texto).strip()
    texto = re.sub(r"(?i)^entre\s+", "", texto)
    for abreviatura, completa in ABREVIATURAS.items():
        texto = re.sub(
            rf"(?<![A-Za-z]){re.escape(abreviatura)}",
            completa,
            texto,
            flags=re.IGNORECASE,
        )
    return colapsar(texto)


def normalizar_localidad(zona: str) -> str:
    clave = colapsar(zona).upper()
    if clave in LOCALIDADES:
        return LOCALIDADES[clave]
    for prefijo, valor in LOCALIDADES.items():
        if prefijo in clave:
            return valor
    return colapsar(zona).title()


def es_interseccion(direccion: str) -> bool:
    return bool(PATRON_INTERSECCION.search(direccion))


def construir_variantes(direccion: str) -> list[str]:
    """Genera variantes de búsqueda, de la más precisa a la más laxa."""
    direccion = normalizar_direccion(direccion)
    variantes: list[str] = []

    if PATRON_E_ENTRE.search(direccion):
        # "CALLE e/ CRUCE1 Y CRUCE2" significa "CALLE entre CRUCE1 y CRUCE2".
        separador = PATRON_E_ENTRE.search(direccion)
        assert separador is not None
        calle = direccion[: separador.start()].strip()
        cruces = direccion[separador.end() :].strip()
        primer_cruce = PATRON_Y.split(cruces, maxsplit=1)[0].strip()
        if calle and primer_cruce:
            variantes.append(f"{calle} y {primer_cruce}")
        if calle:
            variantes.append(calle)
        variantes.append(direccion)
    elif PATRON_Y.search(direccion):
        variantes.append(direccion)
        variantes.extend(
            lado.strip() for lado in PATRON_Y.split(direccion, maxsplit=1) if lado.strip()
        )
    else:
        variantes.append(direccion)

    return sin_duplicados(variantes)


def construir_consultas(direccion: str, zona: str) -> list[str]:
    variantes = construir_variantes(direccion)
    localidad = normalizar_localidad(zona)
    if localidad.lower() == "lomas de zamora":
        return sin_duplicados([f"{variante}, {PARTIDO}" for variante in variantes])
    consultas = [f"{variante}, {localidad}, {PARTIDO}" for variante in variantes]
    consultas.extend(f"{variante}, {PARTIDO}" for variante in variantes)
    return sin_duplicados(consultas)


# --- Reparación de coordenadas ---------------------------------------------


def reparar_coordenada(valor: str, prefijo: str) -> float:
    """Deshace el daño de Excel sobre latitude/longitude.

    Excel exportó los decimales con separador de miles y a veces con la
    precisión completa del double: -34.7581943 -> -347.581.943,
    y -34.7441280507186 -> -3.474.412.805.071.860. En todos los casos el valor
    conserva sus dígitos, sólo se movió el punto, así que alcanza con quitar
    todo lo que no sea dígito y reinsertar un punto después de los dos dígitos
    enteros (34 para latitud, 58 para longitud).
    """
    digitos = re.sub(r"\D", "", valor or "")
    if not digitos.startswith(prefijo):
        raise ValueError(f"coordenada inesperada: {valor!r}")
    numero = float(f"{prefijo}.{digitos[len(prefijo):]}")
    return -numero if (valor or "").strip().startswith("-") else numero


def dentro_del_partido(lat: float, lon: float) -> bool:
    return LAT_MIN <= lat <= LAT_MAX and LON_MIN <= lon <= LON_MAX


CAMPOS_REVISION = [
    "fila",
    "nombre",
    "direccion",
    "zona",
    "motivos",
    "lat_csv",
    "lon_csv",
    "lat_final",
    "lon_final",
    "desvio_m",
    "score",
    "address",
]


def armar_revision(
    indice: int,
    fila: dict,
    nombre: str,
    direccion: str,
    motivos: list[str],
    lat_csv: float,
    lon_csv: float,
    lat_final: float,
    lon_final: float,
    resultado: dict | None,
) -> dict[str, str]:
    """Arma una fila del reporte de revisión manual."""
    return {
        "fila": str(indice),
        "nombre": nombre,
        "direccion": direccion,
        "zona": colapsar(fila.get("zone", "")),
        "motivos": " | ".join(motivos),
        "lat_csv": f"{lat_csv:.7f}",
        "lon_csv": f"{lon_csv:.7f}",
        "lat_final": f"{lat_final:.7f}",
        "lon_final": f"{lon_final:.7f}",
        "desvio_m": f"{geodesic((lat_csv, lon_csv), (lat_final, lon_final)).meters:.0f}",
        "score": str((resultado or {}).get("score") or ""),
        "address": (resultado or {}).get("address") or "",
    }


# --- Geocodificación -------------------------------------------------------


class Cache:
    """Resultados por consulta: evita repetir requests en cada corrida."""

    def __init__(self, ruta: Path):
        self.ruta = ruta
        try:
            self.datos = json.loads(ruta.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            self.datos = {}

    def contiene(self, consulta: str) -> bool:
        return consulta in self.datos

    def get(self, consulta: str):
        return self.datos.get(consulta)

    def set(self, consulta: str, valor) -> None:
        self.datos[consulta] = valor
        try:
            self.ruta.write_text(
                json.dumps(self.datos, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )
        except OSError:
            pass


def geocodificar(
    geolocalizador: ArcGIS,
    cache: Cache,
    consultas: list[str],
    direccion_pedida: str,
    delay: float,
):
    """Devuelve (resultado, consulta, rechazadas, avisos) del primer match válido."""
    rechazadas: list[tuple[str, float, float, str]] = []

    for consulta in consultas:
        if cache.contiene(consulta):
            resultado = cache.get(consulta)
        else:
            time.sleep(delay)
            resultado = None
            for intento in range(1, REINTENTOS + 1):
                try:
                    ubicacion = geolocalizador.geocode(consulta, timeout=TIMEOUT)
                    if ubicacion is not None:
                        resultado = {
                            "lat": ubicacion.latitude,
                            "lon": ubicacion.longitude,
                            "score": (ubicacion.raw or {}).get("score"),
                            "address": ubicacion.address,
                        }
                    break
                except (GeocoderTimedOut, GeocoderUnavailable, GeocoderServiceError) as exc:
                    if intento == REINTENTOS:
                        print(f"    ! ArcGIS falló: {exc}")
                    else:
                        time.sleep(delay * 2)
            cache.set(consulta, resultado)

        if resultado is None:
            continue

        lat, lon = resultado["lat"], resultado["lon"]
        if not dentro_del_partido(lat, lon):
            rechazadas.append((consulta, lat, lon, "fuera del bounding box"))
            continue

        matched_address = resultado.get("address") or ""
        if menciona_partido_ajeno(matched_address):
            rechazadas.append((consulta, lat, lon, "pertenece a otro partido"))
            continue

        aceptable, avisos = evaluar_match(direccion_pedida, matched_address)
        if not aceptable:
            rechazadas.append((consulta, lat, lon, avisos[0]))
            continue

        return resultado, consulta, rechazadas, avisos

    return None, None, rechazadas, []


# --- Programa principal ----------------------------------------------------


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    if not RUTA_ENTRADA.exists():
        print(f"No existe {RUTA_ENTRADA}", file=sys.stderr)
        return 2

    with RUTA_ENTRADA.open(encoding=ENCODING, newline="") as archivo:
        lector = csv.DictReader(archivo, delimiter=DELIMITADOR)
        campos = lector.fieldnames or []
        filas = list(lector)

    geolocalizador = ArcGIS(user_agent=USER_AGENT)
    cache = Cache(RUTA_CACHE)

    total = len(filas)
    reparadas = 0
    geocodificadas = 0
    sin_resultado = 0
    candidatas_descartadas = 0
    errores = 0
    revisiones: list[dict[str, str]] = []

    print(f"Reparando {total} escuelas desde {ARCHIVO_ENTRADA}...")

    for indice, fila in enumerate(filas, start=1):
        nombre = colapsar(fila.get("nombre", "")) or "(sin nombre)"
        direccion = colapsar(fila.get("address", ""))

        try:
            lat_reparada = reparar_coordenada(fila.get("latitude", ""), "34")
            lon_reparada = reparar_coordenada(fila.get("longitude", ""), "58")
            reparadas += 1
        except ValueError as exc:
            errores += 1
            print(f"[{indice}/{total}] {nombre}: {exc}; se conserva la fila original")
            continue

        lat, lon = lat_reparada, lon_reparada

        if es_interseccion(direccion):
            consultas = construir_consultas(direccion, fila.get("zone", ""))
            resultado, usada, rechazadas, avisos_match = geocodificar(
                geolocalizador,
                cache,
                consultas,
                direccion,
                DELAY_ARCGIS,
            )
            for consulta, rlat, rlon, motivo in rechazadas:
                candidatas_descartadas += 1
                print(
                    f"    - descartada {consulta!r}: {motivo} "
                    f"({rlat:.5f}, {rlon:.5f})"
                )

            if resultado is None:
                sin_resultado += 1
                print(
                    f"[{indice}/{total}] {nombre}: sin match confiable, "
                    f"uso coordenada reparada ({lat:.7f}, {lon:.7f})"
                )
                revisiones.append(
                    armar_revision(
                        indice,
                        fila,
                        nombre,
                        direccion,
                        ["sin match confiable: se conserva la coordenada del CSV"],
                        lat_reparada,
                        lon_reparada,
                        lat,
                        lon,
                        None,
                    )
                )
            else:
                lat = resultado["lat"]
                lon = resultado["lon"]
                desvio = geodesic((lat_reparada, lon_reparada), (lat, lon)).meters
                geocodificadas += 1

                motivos: list[str] = list(avisos_match)
                if desvio > AVISO_DESVIO_M:
                    motivos.append(f"desvio de {desvio / 1000:.2f} km")
                aviso_loc = aviso_localidad(
                    fila.get("zone", ""), resultado.get("address") or ""
                )
                if aviso_loc:
                    motivos.append(aviso_loc)

                aviso = "  <-- revisar" if motivos else ""
                print(
                    f"[{indice}/{total}] {nombre}: ArcGIS -> {lat:.7f}, {lon:.7f} "
                    f"(score {resultado.get('score')}, {desvio:.0f} m del CSV){aviso}"
                )
                print(f"      match: {resultado.get('address')}")
                for motivo in motivos:
                    print(f"      aviso: {motivo}")

                if motivos:
                    revisiones.append(
                        armar_revision(
                            indice,
                            fila,
                            nombre,
                            direccion,
                            motivos,
                            lat_reparada,
                            lon_reparada,
                            lat,
                            lon,
                            resultado,
                        )
                    )
        else:
            print(f"[{indice}/{total}] {nombre}: coordenada reparada")

        fila["latitude"] = f"{lat:.7f}"
        fila["longitude"] = f"{lon:.7f}"

    with RUTA_SALIDA.open("w", encoding=ENCODING, newline="") as archivo:
        escritor = csv.DictWriter(
            archivo, fieldnames=campos, delimiter=DELIMITADOR
        )
        escritor.writeheader()
        escritor.writerows(filas)

    with RUTA_REVISION.open("w", encoding=ENCODING, newline="") as archivo:
        escritor = csv.DictWriter(
            archivo, fieldnames=CAMPOS_REVISION, delimiter=DELIMITADOR
        )
        escritor.writeheader()
        escritor.writerows(revisiones)

    print()
    print("--- FIN ---")
    print(
        f"Total: {total} | Coordenadas reparadas: {reparadas} | "
        f"Geocodificadas: {geocodificadas}"
    )
    print(
        f"Sin match confiable: {sin_resultado} | "
        f"Candidatas descartadas: {candidatas_descartadas} | Errores: {errores}"
    )
    print(f"Para revisar a mano: {len(revisiones)} filas")
    print(f"Archivo generado: {RUTA_SALIDA}")
    print(f"Reporte de revisión: {RUTA_REVISION}")
    return 0 if errores == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
