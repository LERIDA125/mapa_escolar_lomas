# 03_Guidelines.md (Reglas y Convenciones)

## 1. Estrategia de Ramas (Git Flow Simplificado)

- `main`: Código estable y listo para compilar el APK de producción.
- `develop`: Rama de integración donde se unen todas las features.
- `feature/TICK-XXX-nombre`: Desarrollo de nuevas características (ej. `feature/TICK-002-etl-python`).
- `bugfix/TICK-XXX-nombre`: Corrección de errores aislados.

## 2. Conventional Commits (Obligatorio)

El agente y los desarrolladores deben usar prefijos estandarizados en cada commit:

- `feat:` Nueva funcionalidad o módulo.
- `fix:` Corrección de errores.
- `docs:` Cambios en la documentación (PRD, diagramas, wireframes).
- `chore:` Actualización de dependencias, configuraciones o tareas menores.
  _Ejemplo:_ `feat(etl): extracción inicial de escuelas desde PDF (TICK-002)`

## 3. Arquitectura y Gestión de Estado (Flutter)

- **Separación de Responsabilidades:** Ningún widget de la UI debe contener lógica de negocio, cálculos de distancia ni llamadas directas a lectura de archivos.
- **Gestor de Estado:** Uso exclusivo de `Riverpod` para inyectar dependencias y manejar el estado del mapa, la búsqueda y el comparador. No se usa `setState`, `ChangeNotifier` ni `Provider` para estado de negocio.
- **Búsqueda:** el query y el filtrado viven en `searchQueryProvider` y `filteredSchoolsProvider`. La UI solo escribe el query con `ref.read(...notifier).state` y consume el `AsyncValue` resultante; nunca filtra listas ni compara strings de negocio dentro de un widget.
- **Riverpod 3.x:** `StateProvider` se importa desde `package:flutter_riverpod/legacy.dart`. Ese import se limita a `lib/providers/`; los widgets importan `flutter_riverpod.dart`.
- **Paradigma Offline-First:** El acceso a los datos de las escuelas se hace a través de un repositorio local (`SchoolRepository`) que lee el archivo `assets/escuelas_seed.json`. La red se usa únicamente para descargar tiles de OpenStreetMap. La geocodificación con ArcGIS es parte del ETL y no se ejecuta en runtime.
- **Mapas:** `flutter_map` + `latlong2`. No se permite `google_maps_flutter` ni API keys de mapas.

## 4. Datos y geocodificación

- Las coordenadas del seed no se editan a mano. Se regeneran con el ETL (`reparador_automatico.py`).
- Antes de correr el geocoder, guardar un backup de `assets/escuelas_seed.json`.
- El script espacia los requests 0.5 s (`DELAY_ARCGIS`) y cachea cada respuesta en `reparador_geocode_cache.json`, así una re-corrida no vuelve a consultar el servicio.
- Las escuelas que ArcGIS no puede resolver se corrigen a mano en `overrides_manual.json`, nunca en el CSV de salida: el script las aplica con prioridad sobre el geocoder y valida que caigan dentro del partido.
- El `User-Agent` del geocoder debe identificar la app y un contacto real.
- Toda corrida debe cerrar con revisión del resumen `Coordenadas reparadas / Geocodificadas / Manuales / Sin match confiable / Errores` y del conteo de filas de `revision_manual.csv`.
- El detalle operativo vive en `docs/05_Geocoding.md`.

## 5. Documentación SDD

Cada cambio relevante debe actualizar la documentación correspondiente:

| Documento | Cuándo actualizarlo |
| --------- | ------------------- |
| `docs/01_PRD_Mapa_Escolar_Lomas.md` | Alcance, stack o modelo de dominio |
| `docs/02_Architecture.md` | Capas, flujo de datos o decisiones técnicas |
| `docs/03_Guidelines.md` | Convenciones, ramas o reglas de datos |
| `docs/04_Tickets.md` | Estado de tickets al cerrar una tarea |
| `docs/05_Geocoding.md` | Cambios en el proceso de geocodificación |
