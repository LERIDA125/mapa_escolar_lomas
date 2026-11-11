import csv
import json
from pathlib import Path

ARCHIVO_CSV = Path("escuelas_reparadas_final.csv")
ARCHIVO_JSON = Path("assets/escuelas_seed.json")
ENCODING = "utf-8-sig"
DELIMITADOR = ";"

def convertir_csv_a_json():
    if not ARCHIVO_CSV.exists():
        print(f"Error: No se encuentra el archivo {ARCHIVO_CSV}")
        return

    escuelas = []
    
    with ARCHIVO_CSV.open(encoding=ENCODING, newline="") as f:
        lector = csv.DictReader(f, delimiter=DELIMITADOR)
        for fila in lector:
            # Limpieza y mapeo de tipos de datos básicos para el modelo de la app
            escuela = {
                "id": fila.get("id") or fila.get("codigo") or str(len(escuelas) + 1),
                "nombre": fila.get("nombre", "").strip(),
                "nivel": fila.get("level") or fila.get("nivel", "").strip(),
                "zona": fila.get("zone") or fila.get("zona", "").strip(),
                "direccion": fila.get("address") or fila.get("direccion", "").strip(),
                "latitude": float(fila["latitude"]) if fila.get("latitude") else 0.0,
                "longitude": float(fila["longitude"]) if fila.get("longitude") else 0.0,
                # Podés mapear o incluir otros campos si tu app los consume (ej. tel, matrícula, etc.)
            }
            escuelas.append(escuela)

    # Asegurar que el directorio de assets exista
    ARCHIVO_JSON.parent.mkdir(parents=True, exist_ok=True)

    # Escribir el JSON formateado
    ARCHIVO_JSON.write_text(
        json.dumps(escuelas, ensure_ascii=False, indent=2),
        encoding="utf-8"
    )

    print(f"¡Conversión exitosa! Se generaron {len(escuelas)} registros en {ARCHIVO_JSON}")

if __name__ == "__main__":
    convertir_csv_a_json()