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

- Portafolio Técnico: Mapa Escolar Lomas (Sector Auxiliares)
Descripción General
Aplicación móvil nativa (Android) diseñada específicamente para el Consejo Escolar de Lomas de Zamora (Sector Auxiliares). El sistema optimiza la logística de asignación de cargos en actos públicos, permitiendo a los aspirantes geolocalizar establecimientos educativos, calcular tiempos de viaje y aplicar filtros de proximidad con parámetros reales del entorno urbano (medición en cuadras y cruce con líneas de transporte local).

Desarrollada bajo la metodología Spec-Driven Development (SDD), priorizando iteraciones rápidas, alta fidelidad visual y empaquetamiento comercial (MVP 1).

🛠 Stack Tecnológico y Arquitectura
Framework: Flutter / Dart (Compilación nativa a APK).

Gestor de Estado: Riverpod (Arquitectura reactiva y desacoplada).

Geolocalización y Mapas: flutter_map implementando tiles de OpenStreetMap (OSM).

Flujo de Trabajo: Spec-Driven Development (SDD) asistido por herramientas de IA local (OpenCode, modelos Qwen) para generación de UI y validación de requerimientos.

Control de Versiones: Git / GitHub (Estrategia de ramas por features / tickets).

🚀 Funcionalidades Principales (Core Features)
Motor de Ruteo y Geolocalización (Core):

Renderizado interactivo de mapas con marcadores personalizados para escuelas.

Cálculo algorítmico de tiempos de viaje estimados desde el punto de origen hasta el establecimiento.

Filtros de Proximidad Adaptados (UX Localizada):

Implementación de un "Radar de Zona Segura" configurable por el usuario utilizando el sistema métrico local (medición en cuadras, 100m por unidad) en lugar de radios kilométricos abstractos, elevando drásticamente la usabilidad en terreno.

Opción de habilitar/deshabilitar la zona segura mediante un toggle integrado al estado global.

Motor de Búsqueda Sincronizado:

Barra de búsqueda con autocompletado en tiempo real.

Sincronización estricta de estado: el buscador respeta las fronteras de los filtros activos (zona segura, niveles, colectivos), previniendo inconsistencias de UI o sugerencias "fantasma".

Módulo de Identidad y Acceso:

Pantalla de validación de credenciales (DNI/Legajo) con persistencia de sesión local.

Splash Screen institucional corporativo diseñado con identidad visual del Consejo Escolar, gestionando la carga simulada de datos y el enrutamiento inteligente (Login vs. Home).

Modo Offline (Resiliencia):

Arquitectura preparada para caché de mapas y datos, garantizando operatividad básica durante actos públicos en zonas con baja conectividad móvil.

📈 Impacto y Visión de Producto
El proyecto transitó exitosamente desde un prototipo de visualización de datos hasta un producto de software comercializable. Al resolver un problema logístico real de la administración pública provincial (la toma de cargos a ciegas), la aplicación reduce la fricción en los actos públicos y previene renuncias tempranas por desconocimiento de las distancias o accesos de transporte. Su arquitectura modular permite escalar fácilmente hacia un backend centralizado para sincronización en tiempo real del padrón de escuelas.
