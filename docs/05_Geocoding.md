# 05_Geocoding.md (Geocodificación del seed)

## 1. Objetivo

Reemplazar las coordenadas default (`-34.7628, -58.4022`) que comparten las
307 escuelas del seed por coordenadas reales obtenidas de OpenStreetMap.

Sin este paso, el mapa dibuja 307 marcadores apilados en un único punto.

## 2. Entrada y salida

- **Entrada:** `assets/escuelas_seed.json`.
- **Salida:** el mismo archivo con `latitude` y `longitude` actualizados.
- **Registros que ya tienen coordenadas distintas del default:** se saltan,
  por lo que la corrida es reanudable.

## 3. Requisitos

- Python 3.10 o superior.
- Paquete `requests`.

## 4. Uso

```powershell
cd C:\Users\Ferar\OneDrive\Desktop\mapa_escolar
Copy-Item assets\escuelas_seed.json assets\escuelas_seed.backup.json -Force
python -m pip install requests
python geocoder.py
```

La corrida completa tarda alrededor de 8 minutos porque el script espera
1.5 segundos entre requests.

## 5. Política de uso de Nominatim

Nominatim es un servicio público gratuito. Para no abusar:

- Máximo 1 request por segundo. El script usa 1.5 segundos.
- Enviar un `User-Agent` identificable con un contacto real.
- No ejecutar el script en producción de forma intensiva sin permiso.
- Guardar un backup del JSON antes de correrlo.

## 6. Normalización aplicada

### Direcciones

`clean_address_string()` corta la dirección en la primera intersección,
ignorando mayúsculas y minúsculas:

- `GARONA Y PIAGGIO` → `GARONA`
- `GOLONDRINA 3607 y Sta Cruz` → `GOLONDRINA 3607`
- `ENTRE COLON Y GUIDO SPANO` → `ENTRE COLON`

### Localidades

`normalize_locality()` traduce las abreviaturas del nomenclador:

| Seed            | Consulta              |
| --------------- | --------------------- |
| `LOMAS DE Z`    | `Lomas de Zamora`     |
| `V. ALBERTINA`  | `Villa Albertina`     |
| `CTEL IX`       | `Cuartel IX`          |
| `BO. EL FARO`   | `Barrio El Faro`      |
| `V. CENTENARIO` | `Villa Centenario`    |
| `ING. BUDGE`    | `Ingeniero Budge`     |

Si la localidad normalizada es `Lomas de Zamora`, la query no repite el
partido. Para el resto se arma:

```text
<calle>, <localidad>, Lomas de Zamora, Buenos Aires, Argentina
```

## 7. Limitaciones conocidas

- El mapping cubre solo seis abreviaturas. El resto cae en `title()`, que
  puede no coincidir con el nombre que espera Nominatim (por ejemplo
  `V. URBANA`, `STA. MARTA`, `V. LAMADRID`).
- No hay validación por bounding box: un resultado puede pertenecer a otra
  localidad del partido.
- Las intersecciones se reducen a la primera calle; se pierde la esquina
  exacta.
- `requests.get()` no tiene timeout explícito.
- Nominatim no tiene todas las calles del nomenclador.

## 8. Verificación posterior

1. Leer el resumen `Exitosos / Fallidos` que imprime el script.
2. Confirmar que el seed dejó de tener un único par de coordenadas:

   ```powershell
   $j = Get-Content -Raw assets\escuelas_seed.json | ConvertFrom-Json
   ($j | Group-Object latitude,longitude).Count
   ```

3. Reiniciar la app para que Flutter vuelva a empaquetar el asset. Hot reload
   no recarga el JSON.

Si la cantidad de fallidos es alta, revisar el mapping de localidades antes
de volver a correr el script.
