# Pipeline de Geocodificación y Reparación de Coordenadas

Este documento describe la arquitectura y las reglas de validación del script `reparador_automatico.py`, diseñado para resolver dos problemas críticos en el dataset de instituciones educativas (`auditoria_escuelas.csv`): la corrupción de formatos numéricos introducida por Excel y la falta de coordenadas precisas en direcciones de intersección.

## 1. Arquitectura y Herramientas

- **Motor de Geocodificación:** ArcGIS (vía la librería `geopy`). Seleccionado por su superioridad frente a Nominatim para interpretar el formato de direcciones argentinas e intersecciones de calles.
- **Gestión de Caché:** Sistema idempotente basado en `reparador_geocode_cache.json`. Almacena las respuestas de ArcGIS para evitar solicitudes redundantes, acelerar ejecuciones posteriores y prevenir bloqueos por exceso de peticiones.
- **Tolerancia a Fallos:** 2 intentos por consulta (`REINTENTOS = 2`), con espera duplicada entre intentos (`DELAY_ARCGIS = 0.5 s`, luego `1 s`) y un `timeout` de 20 s por request.

## 2. Fase 1: Reparación de Formatos Numéricos (Daño de Excel)

Excel, al guardar archivos CSV con configuración regional local, corrompió las coordenadas transformando puntos en separadores de miles y alterando la precisión decimal.

**Lógica de reparación:**

1. Se extraen exclusivamente los caracteres numéricos de la cadena (ignorando puntos y comas mal ubicados).
2. Se verifica que los dígitos comiencen con el prefijo esperado (34 para latitud, 58 para longitud).
3. Se reinserta el punto decimal exactamente después de los dos primeros dígitos, reconstruyendo la precisión GPS original.

- *Ejemplo:* `-347.581.943` -> `-34.7581943`

Si el prefijo no coincide, la fila se reporta como error y se conserva el valor original sin tocarla.

## 3. Fase 2: Geocodificación Estructural

Las direcciones que indican intersecciones (contienen " Y " o " e/ ") son enviadas a ArcGIS. Para evitar que el motor devuelva ubicaciones erróneas o "matches degradados", el resultado pasa por un validador estructural estricto.

### Criterios de Aceptación y Rechazo

- **Bounding Box (Bbox) Excluyente:** La latitud y longitud devueltas deben caer dentro del rectángulo geográfico configurado para Lomas de Zamora (`LAT_MIN, LAT_MAX = -34.90, -34.62`; `LON_MIN, LON_MAX = -58.60, -58.28`). Todo punto fuera de ese rectángulo se rechaza automáticamente.
- **Filtro de Partido Ajeno:** Un punto puede caer dentro del bbox y aun así pertenecer a otro partido, porque el bbox es un rectángulo y los límites son irregulares (Burzaco, por ejemplo, está pegado a Lomas). Si el `address` devuelto menciona un partido o localidad vecina (Almirante Brown, Lanús, Avellaneda, Quilmes, Esteban Echeverría, Ezeiza, La Matanza, Berazategui, Florencio Varela, Burzaco, Adrogué, Longchamps, Glew, Monte Grande, etc.), el match se rechaza aunque las coordenadas estén dentro del bbox.
- **Validación Estructural (Rechazo de Centroides):** ArcGIS tiene la tendencia a devolver el punto medio de una calle (centroide) cuando no encuentra el cruce exacto. El script evalúa la cadena `address` devuelta:
  - **Aprobado:** Contiene el símbolo `&` (indicador nativo de intersección en ArcGIS) o un número de altura de calle válido (`\b\d{1,5}\b`).
  - **Rechazado:** Direcciones con un solo nombre de calle sin altura (ej: "Olimpo" o "Camino de Cintura").
  - *Nota:* el patrón de altura está anclado con `\b`, así que no confunde códigos postales como `B1834` con una altura real.
- **Coincidencia de Calle:** Se requiere que *al menos un lado* de la calle original coincida estructuralmente en el resultado. Exigir ambos lados era demasiado rígido y descartaba matches correctos por typos del nomenclador (ej: "Pareja" vs "Ramón Pareta"); esos casos se aceptan pero se marcan como coincidencia parcial.

### Reglas de Advertencia (No excluyentes)

- **Cruce de Localidades:** Se extrae el barrio reportado por ArcGIS (el componente anterior a "Lomas de Zamora" en el `address`) y se cruza contra la columna `zone` del CSV. Dado que los límites barriales de ArcGIS difieren ligeramente de los administrativos, las discrepancias generan una advertencia, pero no rechazan el match.
- **Desvío Kilométrico:** Se calcula la distancia geodésica entre la coordenada original reparada y la nueva de ArcGIS. Si supera los 3 km (`AVISO_DESVIO_M = 3000`), se marca como advertencia para revisión humana, asumiendo que la coordenada original del CSV probablemente estaba mal ubicada de origen.

## 4. Archivos de Salida

El proceso genera dos *artifacts* principales:

1. `escuelas_reparadas_final.csv`: El dataset principal consolidado y listo para producción. Conserva la estructura exacta de columnas del archivo de origen.
2. `revision_manual.csv`: Un reporte analítico (con separador `;` y codificación UTF-8-SIG) que aísla únicamente los casos que requieren supervisión humana (ej. desvíos mayores a 3 km, discrepancias de localidad, coincidencias parciales y las direcciones que resultaron en centroides rechazados).

Las columnas del reporte son: `fila`, `nombre`, `direccion`, `zona`, `motivos`, `lat_csv`, `lon_csv`, `lat_final`, `lon_final`, `desvio_m`, `score`, `address`. La columna `motivos` acumula todas las advertencias de una fila separadas por ` | `, así que sirve para filtrar en Excel por tipo de problema.

## 5. Overrides Manuales

Algunas intersecciones no se pueden resolver automáticamente: ArcGIS devuelve el centroide de una calle, la localidad entera o un punto de otro partido. Esas escuelas se revisan a mano y su coordenada se guarda en `overrides_manual.json`, indexada por el nombre exacto de la escuela:

```json
{
  "EEE 503": {
    "lat": -34.7762052,
    "lon": -58.4092203,
    "fuente": "Google Maps, revision manual TICK-036"
  }
}
```

- El override tiene prioridad sobre ArcGIS: si la escuela está en el archivo, el script no consulta el servicio.
- Al cargar, cada entrada se valida: `lat`/`lon` numéricos y dentro del bbox del partido. Una entrada inválida se descarta con un aviso y la escuela sigue el camino automático.
- Si un override no coincide con ninguna fila del CSV, se reporta como huérfano al final de la corrida.
- Las escuelas con override no se agregan a `revision_manual.csv`: la coordenada manual es la resolución del caso.

Esto evita editar el CSV de salida a mano, que la próxima corrida pisaría.

## 6. Resultado de la Última Corrida

| Métrica | Valor |
| --- | --- |
| Filas procesadas | 310 |
| Coordenadas reparadas | 310 |
| Geocodificadas por ArcGIS | 68 |
| Coordenadas manuales aplicadas | 10 |
| Sin match confiable | 0 |
| Filas con desvío mayor a 3 km | 18 |
| Filas en `revision_manual.csv` | 44 |
| Errores de parseo de coordenada | 0 |

De las 44 filas del reporte, 31 marcan localidad distinta (18 de ellas sin otro motivo), 8 tienen coincidencia parcial de calles y 18 superan los 3 km de desvío. Los motivos se solapan.

Una corrida posterior reutiliza el caché y produce archivos byte a byte idénticos.

## 7. Conversión al Seed de la App

`escuelas_reparadas_final.csv` es el dataset de trabajo; la app consume `assets/escuelas_seed.json`. El puente entre ambos es `csv_a_seed_json.py`, y su contrato de salida **no** son los headers del CSV sino el modelo de dominio (`docs/02_Architecture.md` §3.1):

```json
{
  "id": "1",
  "name": "901",
  "level": "Jardines de Infantes",
  "address": "PENNA 93",
  "phone": "4244-4244",
  "latitude": -34.7581943,
  "longitude": -58.4109198,
  "locality": { "id": "<uuid5>", "name": "LOMAS DE Z", "zone": "1 - Lomas/Banfield" },
  "transportLines": [{ "id": "<uuid5>", "line": "543" }]
}
```

### Mapeo

| CSV | Seed | Regla |
| --- | --- | --- |
| `nombre` | `name` | `strip()` |
| `level` | `level` | `strip()` |
| `address` | `address` | `strip()` |
| `latitude` / `longitude` | idem | `float`, tolera coma decimal |
| `zone` | `locality.name` | `strip()` |
| — | `locality.zone` | agrupación desde `ZONA_POR_LOCALIDAD` (no viene en el CSV) |
| `colectivos` | `transportLines[].line` | split por `,`, `strip`, deduplicado |
| — | `phone` | recuperado del seed histórico por nombre y, si falta, por dirección no ambigua |

`locality.id` y `transportLines[].id` se derivan con `uuid5`, así que dos corridas sobre el mismo CSV producen un archivo idéntico.

`turnos`, `modalidad` y `codigoOficial` se omiten a propósito: el modelo los lee como `null`.

### Validación Fail-Fast

El script valida todo antes de escribir y aborta con código 1 sin tocar `assets/escuelas_seed.json` si encuentra:

- `name`, `level`, `address` o `locality.name` vacíos;
- una localidad sin entrada en `ZONA_POR_LOCALIDAD`;
- coordenadas no numéricas o fuera del bbox del partido;
- ids duplicados;
- un CSV vacío.

Esto existe porque `School.fromJson` es tolerante (`as String? ?? ''`): un seed con las claves equivocadas no lanza excepción, deja el catálogo con tarjetas sin nombre. Un seed generado con nombres en castellano (`nombre`, `nivel`, `direccion`) se ve idéntico a un seed válido para el compilador.

### Uso

```powershell
python csv_a_seed_json.py
```

Salida esperada con el dataset actual:

| Métrica | Valor |
| --- | --- |
| Registros | 310 |
| Teléfono recuperado | 293 / 310 |
| Con colectivos | 310 / 310 |
| Localidades | 43 |

El seed que produce este script se versiona junto con el CSV: si cambia uno, cambia el otro en el mismo commit.

