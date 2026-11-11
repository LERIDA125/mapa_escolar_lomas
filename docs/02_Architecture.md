# 02_Architecture.md (Arquitectura de la Solución)

## 1. Visión general

Mapa Escolar Lomas es una aplicación Flutter offline-first para consultar el
nomenclador de escuelas del partido de Lomas de Zamora durante los actos
públicos de auxiliares. El catálogo de escuelas viaja dentro del binario; el
mapa consume tiles de OpenStreetMap cuando hay conectividad.

## 2. Stack tecnológico

| Capa            | Tecnología                                      |
| --------------- | ----------------------------------------------- |
| UI              | Flutter + Material Design 3                     |
| Gestión de estado | Riverpod (`flutter_riverpod`)                 |
| Mapas           | `flutter_map` + `latlong2`                      |
| Tiles           | OpenStreetMap raster (`tile.openstreetmap.org`) |
| Datos locales   | JSON embebido (`assets/escuelas_seed.json`)     |
| Geocodificación | Python + ArcGIS (ETL, fuera del runtime)         |

No se utiliza Google Maps ni ninguna API key de mapas.

## 3. Capas y dependencias

```text
lib/
├── main.dart                     # ProviderScope + rutas nombradas
├── domain/models/                # School, Locality, TransportLine,
│                                 # UserOrigin, StreetIndexEntry
├── data/repositories/            # SchoolRepository, StreetIndexRepository
├── providers/                    # schoolRepositoryProvider, schoolsProvider,
│                                 # searchQueryProvider, filteredSchoolsProvider,
│                                 # userOriginProvider, streetIndexProvider
└── presentation/
    ├── screens/                  # Splash, Login, Home, Perfil
    ├── widgets/                  # Componentes reutilizables
    └── theme/                    # Tokens y ThemeData
```

Flujo de datos del mapa y la búsqueda:

```text
HomeScreen
  ├── ref.watch(filteredSchoolsProvider)
  │     ├── ref.watch(schoolsProvider)
  │     │     └── SchoolRepository.getSchools()
  │     │           └── rootBundle.loadString('assets/escuelas_seed.json')
  │     │                 └── List<School> con latitude / longitude
  │     └── ref.watch(searchQueryProvider)   // texto del buscador
  └── _SearchBar.onChanged
        └── ref.read(searchQueryProvider.notifier).state = value
```

Regla de oro: los widgets no leen archivos, no calculan distancias y no
conocen la fuente de datos. Solo consumen providers.

### 3.1 Modelo de dominio `School`

| Campo            | Tipo                   | Origen                          | Ausencia |
| ---------------- | ---------------------- | ------------------------------- | -------- |
| `id`             | `String`               | seed                            | `''`     |
| `name`           | `String`               | seed                            | `''`     |
| `level`          | `String`               | seed                            | `''`     |
| `address`        | `String`               | seed                            | `''`     |
| `phone`          | `String`               | seed                            | `''`     |
| `latitude`       | `double`               | seed / geocoder                 | `0`      |
| `longitude`      | `double`               | seed / geocoder                 | `0`      |
| `locality`       | `Locality`             | seed (`locality`)               | objeto vacío |
| `transportLines` | `List<TransportLine>`  | seed (`transportLines`)         | lista vacía |
| `turnos`         | `String?`              | seed (`turnos`), pendiente ETL   | `null`   |
| `modalidad`      | `String?`              | seed (`modalidad`), pendiente ETL | `null`  |
| `codigoOficial`  | `String?`              | seed (`codigoOficial`), pendiente ETL | `null` |

`turnos`, `modalidad` y `codigoOficial` son opcionales porque el seed actual
todavía no los trae: el nomenclador de origen no está versionado en el repo y
no se completan por inferencia. `fromJson` los lee con `as String?` y `toJson`
los vuelve a escribir tal cual, incluido `null`.

La app nunca muestra el valor crudo cuando es `null`. El fallback de
presentación vive en el dominio para no duplicarlo en cada widget:

```dart
School.notInformed        // 'No informado'
school.turnosLabel        // turnos    ?? School.notInformed
school.modalidadLabel     // modalidad ?? School.notInformed
school.codigoOficialLabel // codigoOficial ?? School.notInformed
```

### 3.2 Punto de partida del aspirante (`UserOrigin`)

El origen de todos los cálculos de distancia —ficha, lista, comparador y Zona
Segura— es configurable desde Perfil y persiste en `shared_preferences`.

| Pieza | Rol |
| --- | --- |
| `UserOrigin` | `label`, `latitude`, `longitude`, `source`. Valida el bbox del partido. |
| `UserOriginNotifier` | `Notifier<UserOrigin>`. Arranca en `UserOrigin.fallback` (Plaza Grigera) e hidrata desde disco. |
| `originLocationProvider` | `Provider<LatLng>` derivado. Único punto de contacto para los consumidores. |
| `streetIndexProvider` | `FutureProvider<List<StreetIndexEntry>>` sobre `assets/calles_lomas.json`. |
| `OriginPickerSheet` | Bottom sheet con mapa, pin fijo y autocompletado de calles. |

`build()` del notifier es **sincrónico** a propósito: cinco widgets leen
`originLocationProvider` como un `LatLng` plano. Un `AsyncNotifier` obligaría a
todos a manejar `AsyncValue`. La hidratación corre en un microtask y actualiza
el estado cuando `shared_preferences` responde; en arranque en frío hay un
parpadeo breve con el origen de fábrica.

El origen nunca se acepta fuera del bbox del partido
(`-34.90..-34.62`, `-58.60..-58.28`), el mismo que valida el ETL. Un valor
persistido corrupto o fuera de rango degrada a `UserOrigin.fallback`.

La geocodificación de la dirección es **offline**: el campo de domicilio
autocompleta contra las calles que ya existen en el padrón de escuelas y el
aspirante afina el punto arrastrando el mapa. No hay servicio externo ni
permiso de GPS. Ver `docs/05_Geocoding.md` §8.

## 4. Búsqueda

El estado de búsqueda vive en `lib/providers/school_providers.dart`:

- `searchQueryProvider`: `StateProvider<String>` que arranca en `''`.
- `filteredSchoolsProvider`: `Provider<AsyncValue<List<School>>>` que combina
  `schoolsProvider` con el query.

Reglas de filtrado:

1. Si el query está vacío, se devuelve el catálogo completo.
2. Los estados `loading` y `error` se reenvían sin transformar.
3. La comparación es case-insensitive (`toLowerCase`) y usa `contains` sobre
   `name`, `address` y `locality.name`.
4. La UI solo escribe el query y consume el resultado; no filtra listas.

En Riverpod 3.x `StateProvider` ya no se exporta desde
`flutter_riverpod.dart`. Se importa desde `package:flutter_riverpod/legacy.dart`.
Ese import vive únicamente en la capa de providers; la UI sigue importando
`flutter_riverpod.dart` y no necesita `legacy.dart`.

## 5. Mapa

- `FlutterMap` con `MapOptions(initialCenter:, initialZoom:)`.
- `TileLayer` apuntando a `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
  con `userAgentPackageName: 'com.example.mapa_escolar'`.
- `MarkerLayer` con un `Marker` genérico por escuela, ubicado en
  `LatLng(school.latitude, school.longitude)`.
- `RichAttributionWidget` con atribución a OpenStreetMap contributors.
- Android requiere `android.permission.INTERNET` para descargar tiles en
  release.

## 6. Geocodificación (ETL)

El ETL corre fuera del runtime y se apoya en dos scripts.

`geocoder.py` es el script base de un solo uso que:

1. Lee `assets/escuelas_seed.json`.
2. Normaliza localidades abreviadas e intersecciones.
3. Consulta el geocoder para cada escuela que todavía tiene las coordenadas
   default.
4. Reescribe el JSON con las coordenadas encontradas.

`reparador_automatico.py` es el pipeline vigente. Parte de
`auditoria_escuelas.csv` y:

1. Repara las coordenadas corruptas por Excel reinsertando el punto decimal
   después del prefijo 34 (latitud) y 58 (longitud).
2. Geocodifica con **ArcGIS** (vía `geopy`) las direcciones que son una
   intersección (`CALLE Y CALLE` o `CALLE e/ CALLE`), donde la coordenada
   exportada no es confiable.
3. Valida cada resultado de forma estructural: descarta los centroides de calle
   que ArcGIS devuelve cuando no encuentra el cruce, los puntos fuera del
   bounding box del partido y los que pertenecen a partidos o localidades
   vecinas.
4. Aplica las coordenadas corregidas a mano en `overrides_manual.json` (las
   escuelas que ArcGIS no pudo resolver) con prioridad sobre el geocoder.
5. Escribe `escuelas_reparadas_final.csv` y un reporte de revisión humana en
   `revision_manual.csv`.

Ninguno se ejecuta en runtime: el APK consume las coordenadas ya persistidas.
El detalle operativo está en `docs/05_Geocoding.md`.

## 7. Decisiones y restricciones

- **Offline-first para datos:** el catálogo no depende de la red.
- **Online solo para tiles:** sin conexión el mapa queda vacío, pero la
  búsqueda y las fichas siguen funcionando.
- **Riverpod exclusivo:** no se usa `setState` para estado de negocio.
- **Sin Google Maps:** se eliminó `google_maps_flutter` y todo el plumbing
  de `MAPS_API_KEY`.
- **ArcGIS en el ETL:** requests espaciados 0.5 s, caché en disco y User-Agent
  identificable. El servicio se consulta solo desde el ETL, nunca en runtime.

## 8. Validación

Antes de cerrar un ticket de código:

```powershell
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

## 9. Documentación relacionada

- `docs/01_PRD_Mapa_Escolar_Lomas.md` — alcance y modelo de dominio.
- `docs/03_Guidelines.md` — ramas, commits y convenciones.
- `docs/04_Tickets.md` — estado de los tickets.
- `docs/05_Geocoding.md` — operación del geocoder.
