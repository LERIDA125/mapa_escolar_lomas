# Mapa Escolar Lomas

Aplicación Flutter offline-first para consultar el nomenclador de escuelas del
partido de Lomas de Zamora durante los actos públicos de auxiliares.

El catálogo de escuelas viaja dentro del APK. El mapa usa tiles de
OpenStreetMap cuando hay conectividad.

## Stack

- Flutter + Material Design 3
- Riverpod
- `flutter_map` + `latlong2` sobre OpenStreetMap
- JSON local en `assets/escuelas_seed.json`

No se usa Google Maps.

## Estructura

```text
lib/
├── main.dart
├── domain/models/          # School, Locality, TransportLine
├── data/repositories/      # SchoolRepository
├── providers/              # Riverpod (catálogo, búsqueda y filtros)
└── presentation/
    ├── screens/            # Splash, Login, Home
    ├── widgets/
    └── theme/
```

## Búsqueda

El buscador de Home escribe en `searchQueryProvider` y el mapa consume
`filteredSchoolsProvider`. El filtro es local, case-insensitive y busca en
nombre, dirección y localidad. No requiere conexión.

## Puesta en marcha

```powershell
flutter pub get
flutter run
```

## Validación

```powershell
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

## Geocodificación

Las coordenadas del seed se regeneran con `geocoder.py` (Nominatim):

```powershell
Copy-Item assets\escuelas_seed.json assets\escuelas_seed.backup.json -Force
python -m pip install requests
python geocoder.py
```

Después de correrlo, reiniciar la app para que Flutter vuelva a empaquetar el
asset. Hot reload no recarga el JSON.

El detalle operativo, las limitaciones y la política de uso de Nominatim están
en [`docs/05_Geocoding.md`](docs/05_Geocoding.md).

## Documentación SDD

- [`docs/01_PRD_Mapa_Escolar_Lomas.md`](docs/01_PRD_Mapa_Escolar_Lomas.md) — PRD y modelo de dominio.
- [`docs/02_Architecture.md`](docs/02_Architecture.md) — arquitectura y flujo de datos.
- [`docs/03_Guidelines.md`](docs/03_Guidelines.md) — ramas, commits y convenciones.
- [`docs/04_Tickets.md`](docs/04_Tickets.md) — estado de tickets.
- [`docs/05_Geocoding.md`](docs/05_Geocoding.md) — proceso de geocodificación.
