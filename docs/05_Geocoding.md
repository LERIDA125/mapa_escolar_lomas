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

`normalize_locality()` traduce las abreviaturas del nomenclador. El mapping
se amplió en TICK-008:

| Seed                            | Consulta               |
| ------------------------------- | ---------------------- |
| `LOMAS DE Z`                    | `Lomas de Zamora`      |
| `V. ALBERTINA`                  | `Villa Albertina`      |
| `BO. EL FARO`                   | `Barrio El Faro`       |
| `V. CENTENARIO`                 | `Villa Centenario`     |
| `ING. BUDGE`                    | `Ingeniero Budge`      |
| `V. URBANA`                     | `Villa Urbana`         |
| `STA. MARTA`                    | `Santa Marta`          |
| `V. LAMADRID`                   | `Villa Lamadrid`       |
| `V. INDEP`, `V. INDEPENDEN`     | `Villa Independencia`  |
| `V. FIORITO`                    | `Villa Fiorito`        |
| `BANFIELD O/E/OESTE/ESTE`       | `Banfield`             |
| `TEMPERLEY O/E/OESTE/ESTE`      | `Temperley`            |
| `LAVALLOL` (dentro de `LLAVALLOL`) | `Llavallol`         |
| `S. JOSE`, `SAN JOSE`           | `Barrio San José`      |
| `CTEL IX`, `CTEL. IX`           | `Lomas de Zamora`      |

El matching es por substring sobre la localidad en mayúsculas, así que las
variantes sin punto o sin espacio (`V URBANA`, `V LAMADRID`, `V.FIORITO`,
`V.CENTENARIO`, `BO EL FARO`) **no** entran en el mapping y caen en
`title()`. `BUDGE` tampoco está mapeado; solo `ING. BUDGE`.

Si la localidad normalizada es `Lomas de Zamora`, la query no repite el
partido. Para el resto se arma:

```text
<calle>, <localidad>, Lomas de Zamora, Buenos Aires, Argentina
```

### Fallback en cascada (TICK-008)

`geocode_address()` intenta dos veces antes de rendirse:

1. **Intento 1 — dirección exacta:** `<calle>, <localidad>, Lomas de Zamora,
   Buenos Aires, Argentina`. Si Nominatim devuelve un resultado, se guarda tal
   cual y el log dice `-> EXACTO`.
2. **Intento 2 — centroide de barrio:** `<localidad>, Lomas de Zamora, Buenos
   Aires, Argentina`. Si resuelve, se le suma un offset determinístico de hasta
   ±0.005 grados generado con MD5 del nombre de la escuela. El log dice
   `-> FALLBACK BARRIO`.
3. Si ambos fallan, la escuela conserva el default y el log dice
   `-> FALLO TOTAL`.

El offset es reproducible: correr el script dos veces produce las mismas
coordenadas para la misma escuela. Sirve para que los pines de un mismo barrio
no queden apilados en un único punto.

`requests.get()` usa un timeout de 30 segundos.

## 7. Resultados de la corrida (TICK-008)

Corrida del fallback en cascada sobre las 106 escuelas que seguían en el
default:

```text
Total: 307 | Ya geocodificadas: 201
Exactos: 6 | Fallback barrio: 86 | Fallos totales: 14
Exitosos: 92 | Fallidos: 14
```

- 293 de 307 escuelas tienen coordenadas propias.
- 226 pares de coordenadas únicos (varias escuelas comparten dirección exacta).
- Quedan 14 escuelas en el default, concentradas en localidades que no
  resuelven ni como centroide: `BO. 2 DE ABRIL` (2), `BO. LA LOMA` (3),
  `BO EL FARO` (4), `BO. EL FARO` (1), `V URBANA` (1), `JUAN M. DE ROS/Rosa`
  (2) y `Sin Especificar` (1).

## 8. Limitaciones conocidas

- El mapping ampliado (TICK-008) cubre las abreviaturas más frecuentes, pero
  quedan variantes sin punto/espacio y barrios sin mapear (`BUDGE`,
  `BO. LA LOMA`, `BO. 2 DE ABRIL`, `OLIMPO`, `CEMENTERIO`, `TRIBUNALES`,
  `Sin Especificar`).
- **La normalización de localidades no es el cuello de botella principal.**
  De las 106 escuelas que quedaron en el default, 50 ya tenían una localidad
  que se normalizaba bien (`BANFIELD`, `TEMPERLEY`, `LOMAS DE Z`) y aun así
  fallaron. El problema es que Nominatim no tiene esas calles/números.
- Prueba empírica sobre 18 muestras de las 106 fallidas con el mapping nuevo:
  **1 recuperada**. Quitar el número de la calle no mejora el resultado. El
  centroide de la localidad sí resuelve en 11 de 12 casos; por eso el fallback
  en cascada lo usa.
- **El fallback tiene precisión de barrio, no de puerta.** El pin puede quedar
  a unos 500 metros de la escuela real. Es aceptable para decidir durante un
  acto, pero no para navegación.
- No hay validación por bounding box: un resultado puede pertenecer a otra
  localidad del partido.
- Las intersecciones se reducen a la primera calle; se pierde la esquina
  exacta.
- Nominatim no tiene todas las calles del nomenclador.

## 9. Verificación posterior

1. Leer el resumen `Exactos / Fallback barrio / Fallos totales` que imprime el
   script. Un `FALLO TOTAL` significa que ni la dirección ni la localidad
   resolvieron en Nominatim.
2. Confirmar que el seed dejó de tener un único par de coordenadas:

   ```powershell
   $j = Get-Content -Raw assets\escuelas_seed.json | ConvertFrom-Json
   ($j | Group-Object latitude,longitude).Count
   ```

3. Reiniciar la app para que Flutter vuelva a empaquetar el asset. Hot reload
   no recarga el JSON.

Si aparecen nuevos `FALLO TOTAL`, revisar el mapping de localidades o mapear
el barrio a una localidad que Nominatim reconozca antes de volver a correr el
script.
