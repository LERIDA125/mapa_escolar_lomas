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

## Sprint 4: Interacciones y UI Final

Cierra las brechas entre los prototipos de `prototipo_ui/`, el PRD y el código actual. Hoy la app solo tiene mapa + buscador + estados de carga/error/vacío: faltan ficha de escuela, filtros, favoritos, comparador, perfil, sesión, navegación inferior y caché offline de tiles.

| Ticket | Módulo | Descripción | Estado |
|---|---|---|---|
| **TICK-011** | Data (ETL) | Agregar `turnos`, `modalidad` y código oficial de establecimiento al modelo `School` y al seed. El seed actual solo trae nivel: validar si el nomenclador provee estos campos y, si no, exponer `No informado` sin inventar datos. Actualizar `fromJson`/`toJson`, tests y `docs/02_Architecture.md`. | 🟢 DONE |
| **TICK-012** | State/Geo | Crear `originLocationProvider` con punto de partida por GPS (`geolocator`) o dirección tipeada, persistido con `shared_preferences`. Agregar distancia haversine reutilizable, banner con el origen configurado en Home y FAB de recentrado. Base para ficha, favoritos y comparador. | ⚪ TO DO |
| **TICK-013** | UI/Map | Implementar la ficha de escuela al tocar un pin: pin seleccionado, tarjeta peek + bottom sheet expandible con nivel, modalidad, turnos, dirección, teléfono con acción de llamada, localidad, líneas de colectivo, distancia desde el origen y mini-mapa embebido. Acciones `Cómo llegar` y `Añadir a comparativa`. Cerrar al tocar el mapa. | 🟢 DONE |
| **TICK-014** | UI/State | Agregar chips horizontales de filtro por nivel conectados a `levelFilterProvider` (Todas, Primarias, Jardines, Secundarias, Técnicas, Especial, Adultos, CENS, Formación, Complementarios, Superior). Incluir contador de resultados, botón para limpiar búsqueda/filtros y diferenciación visual del pin por nivel. | ⚪ TO DO |
| **TICK-015** | UI | Implementar autocompletado offline del buscador: sugerencias por nombre/número mientras se tipea, selección que centra el mapa en la escuela y navegación por teclado. Requisito del MMP ("Buscador Autocompletado"). | ⚪ TO DO |
| **TICK-016** | State/UI | Implementar búsqueda inversa por línea de colectivo (CU-Opcional 02): selector de línea alimentado por `transportLines`, filtrado del mapa y contador de escuelas servidas. | ⚪ TO DO |
| **TICK-017** | State/UI | Implementar el modo "Zona Segura" (CU-Opcional 04): slider de radio máximo desde el punto de partida, círculo dibujado en el mapa y ocultamiento de escuelas fuera del radio. | ⚪ TO DO |
| **TICK-018** | UI/State | Agregar la lista de resultados sincronizada con el mapa (TICK-007 la declaró pero no existe): nombre, nivel, localidad y distancia; al tocar un ítem abre la ficha y centra el pin. | ⚪ TO DO |
| **TICK-019** | State/UI | Implementar favoritos persistentes con `favoritesProvider` y pantalla `Mis favoritas`: badge de modo offline, tarjetas con distancia y líneas, orden por cercanía, filtro por nivel, acciones `Ver ruta` / `Al comparador` y botón `Comparar todas en ranking`. | ⚪ TO DO |
| **TICK-020** | State/UI | Implementar el comparador de 2 a 4 escuelas: `comparatorProvider` con alta/baja, ranking automático por distancia/tiempo, insignia `Opción más cercana`, desglose lado a lado (tiempo total, líneas, turno/horario, trayecto a pie) y acciones `Ver en mapa` / `Ver ruta`. | ⚪ TO DO |
| **TICK-021** | UI/Nav | Agregar la barra de navegación inferior MD3 con Mapa, Comparativa, Favoritos y Perfil, rutas nombradas y badges de cantidad. Unificar el cuarto destino como `Perfil` (el prototipo de Home dice `Mi Ubicación`; el recentrado GPS pasa a FAB). Incluir drawer si se conserva el ícono de menú. | ⚪ TO DO |
| **TICK-022** | UI/State | Implementar la pantalla Perfil: identidad del aspirante, punto de partida con `Cambiar`, preferencias de transporte, radio máximo, turnos de interés, estado de almacenamiento local y cierre de sesión. Persistir las preferencias localmente. | ⚪ TO DO |
| **TICK-023** | State/Auth | Reemplazar el login decorativo por sesión real: validar DNI/legajo con reglas locales, persistir `Recordar mi DNI`, crear `sessionProvider` y proteger las rutas. Resolver los placeholders de `Mesa de Ayuda` y `Listado oficial` con enlaces o contenido. | ⚪ TO DO |
| **TICK-024** | Map/Infra | Implementar caché offline de tiles y banner de conectividad. El PRD promete funcionamiento 100% offline, pero hoy sin red el mapa queda vacío. Cachear tiles visitados y avisar `Sin conexión` sin bloquear búsqueda ni fichas. | ⚪ TO DO |
| **TICK-025** | State/Map | Calcular tiempos estimados por modo (a pie, auto, colectivo) desde el punto de partida y resolver `Cómo llegar`: distancia + velocidades configurables, líneas directas del seed y polyline simple. El ruteo real por calles queda para una iteración posterior. | ⚪ TO DO |
| **TICK-026** | Splash/Infra | Reemplazar el timer fijo del Splash por precarga real del seed y validación de coordenadas. Mostrar la versión y fecha real del paquete de datos en lugar del texto hardcodeado `v2.4.0`. | ⚪ TO DO |
| **TICK-027** | UI/Map | Segunda iteración de la ficha de escuela (alcance diferido de TICK-013): estado de pin seleccionado, tarjeta peek previa al bottom sheet, mini-mapa embebido, distancia desde el origen, teléfono con acción de llamada real, líneas de colectivo, `Añadir a comparativa` conectado al comparador y cierre de la ficha al tocar el mapa. | ⚪ TO DO |

### Notas de estado

- **TICK-011 (🟢 DONE):** el PO descartó buscar o inyectar `turnos`,
  `modalidad` y `codigoOficial` en el seed por ahora. La solución definitiva es
  el modelo con campos `String?` + getters tolerantes a null
  (`turnosLabel`, `modalidadLabel`, `codigoOficialLabel`) que devuelven
  `No informado`. Documentado en la sección 3.1 de `docs/02_Architecture.md`.
  La UI no los muestra hasta que exista una fuente real.
- **TICK-013 (🟢 DONE):** ficha entregada en dos cortes — pin con `onTap`,
  `_showSchoolDetails` con `showModalBottomSheet` M3 (drag handle, safe area,
  nombre, chip de nivel, dirección + localidad, teléfono condicional) y fila de
  acciones `Cómo llegar` / `Comparar` con `debugPrint` como placeholder.
  El resto del alcance original (pin seleccionado, tarjeta peek, mini-mapa
  embebido, distancia desde el origen, llamada real, líneas de colectivo,
  conexión con el comparador y cierre al tocar el mapa) se difiere a
  **TICK-027** para no bloquear la UI base.
- **TICK-013** arranca antes que **TICK-012** por decisión de producto: la ficha
  se puede construir con el modelo actual y el origen de distancia se enchufa
  después.

### Fuera de alcance de Sprint 4

- **Postulación y adjudicación de cargos/vacantes:** el prototipo muestra badges de vacantes y un botón `Postularme`, pero el PRD oficial lo declara anti-alcance y no existe una fuente offline de vacantes dinámicas.
- **Notas de asamblea por escuela:** aparecen como texto de ejemplo en el prototipo de Favoritos, pero no tienen flujo de edición ni respaldo en el PRD.
- **Búsqueda por voz:** el prototipo muestra el micrófono, pero el PRD no la especifica. Hoy hay un snackbar de "próximamente"; si se prioriza, se abre un ticket aparte.
- **Votación remota, reclamos de puntaje u obleas:** fuera del propósito de la app.
- **Ruteo con tráfico en tiempo real:** incompatible con el requisito offline.
- **Login contra un backend oficial:** no hay API disponible; TICK-023 valida localmente.
