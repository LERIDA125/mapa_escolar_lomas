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
- **Gestor de Estado:** Uso exclusivo de `Riverpod` (o `Provider` como alternativa) para inyectar dependencias y manejar el estado del mapa y el comparador.
- **Paradigma Offline-First:** El acceso a los datos de las escuelas se hace a través de un repositorio local (`SchoolRepository`) que lee el archivo `assets/escuelas_seed.json`. Solo se utiliza la red para la API de Google Maps.
