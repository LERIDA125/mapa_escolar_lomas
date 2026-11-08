| Ticket       | Módulo     | Descripción                                                                                                                                 | Estado         |
| ------------ | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------- | -------------- |
| **TICK-001** | Docs       | Estructurar SDD (PRD, ERD, Guidelines, Tickets) y assets visuales de Stitch.                                                                | 🟢 DONE        |
| **TICK-002** | Data (ETL) | Script Python ETL, parseo de nomenclador PDF a Excel y export a `escuelas_seed.json`.                                                       | 🟢 DONE        |
| **TICK-003** | Infra      | Configurar modelos de datos, `SchoolRepository` y Riverpod. Inyectar JSON tolerando registros vacíos y configurar test unitarios.           | 🟢 DONE        |
| **TICK-004** | UI         | Traducir prototipos de Stitch (Splash, Login, Home) a Flutter integrando `flutter_map` (OpenStreetMap) con pines renderizados vía Riverpod. | 🟢 DONE        |
| **TICK-005** | Data (ETL) | Geocodificar direcciones del seed con Nominatim, normalizando localidades abreviadas e intersecciones.                                       | 🟢 DONE        |
| **TICK-006** | State      | Crear `searchQueryProvider` y `filteredSchoolsProvider` con filtrado case-insensitive por nombre, dirección y localidad, preservando `AsyncValue`. | 🟢 DONE        |
| **TICK-007** | UI         | Conectar el buscador de Home al `searchQueryProvider` y renderizar los resultados de `filteredSchoolsProvider` en mapa y lista.              | 🟢 DONE        |
## Sprint 3: Refinamiento UX y Resolución de Deuda de Datos

| Ticket | Módulo | Descripción | Estado |
|---|---|---|---|
| **TICK-008** | Data (Script) | Ampliar el diccionario de localidades en `geocoder.py` para mapear las 106 escuelas fallidas (V. URBANA, STA. MARTA, etc.) y re-ejecutar. | 🟢 DONE |
| **TICK-009** | UX/UI | Mostrar un overlay o feedback visual de "Sin resultados" en el mapa cuando `filteredSchoolsProvider` devuelva una lista vacía. | 🟢 DONE |
| **TICK-010** | UX/Map | Implementar lógica con `MapController` de `flutter_map` para recentrar y ajustar el zoom dinámicamente a los bounds de los resultados filtrados. | 🟢 DONE |