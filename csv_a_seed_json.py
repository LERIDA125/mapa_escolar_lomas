"""Convierte el CSV reparado al seed JSON que consume la app.

El contrato de salida es el de `School.fromJson`
(`lib/domain/models/school_models.dart`), documentado en
`docs/02_Architecture.md` §3.1:

    id, name, level, address, phone, latitude, longitude,
    locality { id, name, zone },
    transportLines [ { id, line } ]

`turnos`, `modalidad` y `codigoOficial` se omiten a propósito: el modelo los
lee como `null` y el nomenclador de origen todavía no los trae.

Reglas:
- El script nunca escribe un seed inválido: valida todo antes de tocar
  `assets/escuelas_seed.json` y aborta con código 1 si algo no cierra.
- Los ids de localidades y líneas se derivan con `uuid5`, así que dos corridas
  sobre el mismo CSV producen un archivo idéntico.
- `phone` no viene en el CSV reparado: se recupera del seed histórico
  (`assets/escuelas_seed.backup.json`) por nombre y, si no hay match, por
  dirección cuando la dirección no es ambigua.
"""

import csv
import json
import re
import sys
import unicodedata
import uuid
from pathlib import Path

ARCHIVO_CSV = Path("escuelas_reparadas_final.csv")
ARCHIVO_JSON = Path("assets/escuelas_seed.json")
ARCHIVO_TELEFONOS = Path("assets/escuelas_seed.backup.json")
ENCODING = "utf-8-sig"
DELIMITADOR = ";"

# Bbox del partido de Lomas de Zamora: un punto fuera de este rectángulo es un
# error de geocodificación, no una escuela.
LAT_MIN, LAT_MAX = -34.90, -34.62
LON_MIN, LON_MAX = -58.60, -58.28

# Agrupación administrativa por localidad. No está en el CSV (su columna `zone`
# guarda el nombre de la localidad): se recuperó del seed histórico y cubre las
# 43 localidades presentes en `escuelas_reparadas_final.csv`.
ZONA_POR_LOCALIDAD = {
    '2 DE ABRIL': '4 - Fiorito/Budge/Albertina',
    'B NUEVA ESPERANZA': 'Sin Especificar',
    'B. EL FARO': '5 - Lomas Oeste/Banfield Oeste',
    'BANFIELD': '1 - Lomas/Banfield',
    'BO ODISA': '5 - Lomas Oeste/Banfield Oeste',
    'BO. 2 DE ABRIL': '4 - Fiorito/Budge/Albertina',
    'BO. EL FARO': '5 - Lomas Oeste/Banfield Oeste',
    'BO. LA LOMA': '5 - Lomas Oeste/Banfield Oeste',
    'BO. ODISA': '5 - Lomas Oeste/Banfield Oeste',
    'BO. OLIMPO': '4 - Fiorito/Budge/Albertina',
    'BUDGE': '4 - Fiorito/Budge/Albertina',
    'CEMENTERIO': '5 - Lomas Oeste/Banfield Oeste',
    'CTEL IX': '5 - Lomas Oeste/Banfield Oeste',
    'CTEL. IX': '5 - Lomas Oeste/Banfield Oeste',
    'FIORITO': '4 - Fiorito/Budge/Albertina',
    'J. M de Rosas': '4 - Fiorito/Budge/Albertina',
    'J. M. DE ROSAS': '4 - Fiorito/Budge/Albertina',
    'JUAN M. DE ROS': '4 - Fiorito/Budge/Albertina',
    'JUAN M. DE ROSA': '4 - Fiorito/Budge/Albertina',
    'LLAVALLOL': '3 - Temperley Oeste/Turdera/Llavallol',
    'LOMAS DE Z': '1 - Lomas/Banfield',
    'LOMAS DE Z.': '5 - Lomas Oeste/Banfield Oeste',
    'LOMAS DE ZAMORA': '1 - Lomas/Banfield',
    'OLIMPO': '4 - Fiorito/Budge/Albertina',
    'PQUE LOMAS': '5 - Lomas Oeste/Banfield Oeste',
    'PQUE. LOMAS': '5 - Lomas Oeste/Banfield Oeste',
    'SAN JOSE': '2 - Temperley Este/Pasco/San José',
    'STA CATALINA': '4 - Fiorito/Budge/Albertina',
    'STA. CATALINA': '4 - Fiorito/Budge/Albertina',
    'STA. MARTA': '5 - Lomas Oeste/Banfield Oeste',
    'TEMPERLEY': '2 - Temperley Este/Pasco/San José',
    'TRIBUNALES': '5 - Lomas Oeste/Banfield Oeste',
    'TURDERA': '3 - Temperley Oeste/Turdera/Llavallol',
    'V LAMADRID': '4 - Fiorito/Budge/Albertina',
    'V URBANA': '4 - Fiorito/Budge/Albertina',
    'V. ALBERTINA': '4 - Fiorito/Budge/Albertina',
    'V. CENTENARIO': '5 - Lomas Oeste/Banfield Oeste',
    'V. INDEP': '5 - Lomas Oeste/Banfield Oeste',
    'V. INDEPENDEN': '5 - Lomas Oeste/Banfield Oeste',
    'V. LAMADRID': '4 - Fiorito/Budge/Albertina',
    'V. URBANA': '4 - Fiorito/Budge/Albertina',
    'V.CENTENARIO': '5 - Lomas Oeste/Banfield Oeste',
    'V.FIORITO': '4 - Fiorito/Budge/Albertina',
}


def normalizar(texto):
    """Normaliza para comparar nombres y direcciones sin tildes ni puntuación."""
    sin_tildes = (
        unicodedata.normalize("NFKD", texto)
        .encode("ascii", "ignore")
        .decode("ascii")
        .upper()
    )
    return re.sub(r"[^A-Z0-9 ]", " ", sin_tildes).strip()


def cargar_telefonos():
    """Devuelve (por_nombre, por_direccion) con los teléfonos del seed viejo.

    `por_direccion` solo incluye direcciones que apuntan a un único teléfono:
    si dos escuelas de la misma dirección declaran números distintos, no hay
    forma de saber cuál corresponde y se descarta el fallback.
    """
    if not ARCHIVO_TELEFONOS.exists():
        print(f"Aviso: no existe {ARCHIVO_TELEFONOS}; los teléfonos quedarán vacíos.")
        return {}, {}

    with ARCHIVO_TELEFONOS.open(encoding="utf-8") as f:
        historico = json.load(f)

    por_nombre = {}
    telefonos_por_direccion = {}
    for escuela in historico:
        telefono = (escuela.get("phone") or "").strip()
        if not telefono:
            continue
        por_nombre.setdefault(escuela["name"].strip(), telefono)
        direccion = normalizar(escuela.get("address") or "")
        if direccion:
            telefonos_por_direccion.setdefault(direccion, set()).add(telefono)

    por_direccion = {
        direccion: next(iter(telefonos))
        for direccion, telefonos in telefonos_por_direccion.items()
        if len(telefonos) == 1
    }
    return por_nombre, por_direccion


def parsear_coordenada(valor, campo, nombre_fila):
    """Convierte una coordenada del CSV a float, tolerando comas decimales."""
    texto = (valor or "").strip().replace(",", ".")
    if not texto:
        raise ValueError(f"{nombre_fila}: {campo} vacía")
    try:
        return float(texto)
    except ValueError as error:
        raise ValueError(f"{nombre_fila}: {campo} no numérica ({valor!r})") from error


def parsear_lineas(valor):
    """Convierte la columna `colectivos` ("543, 544") en una lista limpia."""
    lineas = []
    for parte in (valor or "").split(","):
        linea = parte.strip()
        if linea and linea not in lineas:
            lineas.append(linea)
    return lineas


def id_localidad(nombre):
    return str(uuid.uuid5(uuid.NAMESPACE_URL, f"mapa-escolar:locality:{nombre}"))


def id_linea(linea):
    return str(uuid.uuid5(uuid.NAMESPACE_URL, f"mapa-escolar:transport-line:{linea}"))


def construir_escuela(fila, indice, telefonos_por_nombre, telefonos_por_direccion):
    nombre = (fila.get("nombre") or "").strip()
    etiqueta_fila = f"fila {indice} ({nombre or 'sin nombre'})"

    nivel = (fila.get("level") or fila.get("nivel") or "").strip()
    direccion = (fila.get("address") or fila.get("direccion") or "").strip()
    localidad = (fila.get("zone") or fila.get("zona") or "").strip()

    telefono = telefonos_por_nombre.get(nombre, "")
    if not telefono:
        telefono = telefonos_por_direccion.get(normalizar(direccion), "")

    return {
        "id": str(fila.get("id") or fila.get("codigo") or indice),
        "name": nombre,
        "level": nivel,
        "address": direccion,
        "phone": telefono,
        "latitude": parsear_coordenada(fila.get("latitude"), "latitude", etiqueta_fila),
        "longitude": parsear_coordenada(fila.get("longitude"), "longitude", etiqueta_fila),
        "locality": {
            "id": id_localidad(localidad),
            "name": localidad,
            "zone": ZONA_POR_LOCALIDAD.get(localidad, ""),
        },
        "transportLines": [
            {"id": id_linea(linea), "line": linea}
            for linea in parsear_lineas(fila.get("colectivos"))
        ],
    }


def validar(escuelas):
    """Devuelve la lista de errores que impiden escribir el seed."""
    errores = []

    if not escuelas:
        return ["el CSV no produjo ningún registro"]

    ids = {}
    for escuela in escuelas:
        referencia = f"{escuela['id']} ({escuela['name'] or 'sin nombre'})"

        for campo in ("name", "level", "address"):
            if not escuela[campo]:
                errores.append(f"{referencia}: {campo} vacío")

        if not escuela["locality"]["name"]:
            errores.append(f"{referencia}: locality.name vacío")
        elif not escuela["locality"]["zone"]:
            errores.append(
                f"{referencia}: localidad {escuela['locality']['name']!r} "
                "sin agrupación en ZONA_POR_LOCALIDAD"
            )

        if not (LAT_MIN <= escuela["latitude"] <= LAT_MAX):
            errores.append(
                f"{referencia}: latitude {escuela['latitude']} fuera del bbox del partido"
            )
        if not (LON_MIN <= escuela["longitude"] <= LON_MAX):
            errores.append(
                f"{referencia}: longitude {escuela['longitude']} fuera del bbox del partido"
            )

        if escuela["id"] in ids:
            errores.append(f"{referencia}: id duplicado")
        ids[escuela["id"]] = True

    return errores


def convertir_csv_a_json():
    if not ARCHIVO_CSV.exists():
        print(f"Error: no se encuentra {ARCHIVO_CSV}")
        sys.exit(1)

    telefonos_por_nombre, telefonos_por_direccion = cargar_telefonos()

    escuelas = []
    errores = []

    with ARCHIVO_CSV.open(encoding=ENCODING, newline="") as f:
        for indice, fila in enumerate(csv.DictReader(f, delimiter=DELIMITADOR), start=1):
            try:
                escuelas.append(
                    construir_escuela(
                        fila,
                        indice,
                        telefonos_por_nombre,
                        telefonos_por_direccion,
                    )
                )
            except ValueError as error:
                errores.append(str(error))

    errores.extend(validar(escuelas))
    if errores:
        print(f"Error: el seed no se generó. {len(errores)} problema(s):")
        for error in errores:
            print(f"  - {error}")
        sys.exit(1)

    ARCHIVO_JSON.parent.mkdir(parents=True, exist_ok=True)
    ARCHIVO_JSON.write_text(
        json.dumps(escuelas, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    con_telefono = sum(1 for escuela in escuelas if escuela["phone"])
    con_lineas = sum(1 for escuela in escuelas if escuela["transportLines"])
    localidades = {escuela["locality"]["name"] for escuela in escuelas}
    print(f"Conversión exitosa: {len(escuelas)} registros en {ARCHIVO_JSON}")
    print(
        f"  teléfono recuperado: {con_telefono}/{len(escuelas)} | "
        f"con colectivos: {con_lineas}/{len(escuelas)} | "
        f"localidades: {len(localidades)}"
    )


if __name__ == "__main__":
    convertir_csv_a_json()
