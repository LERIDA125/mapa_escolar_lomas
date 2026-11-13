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
| **TICK-012** | State/Geo | Crear `originLocationProvider` con origen simulado en Plaza Grigera y helper Haversine reutilizable. Mostrar la distancia calculada desde ese origen en la ficha; GPS real e ingreso manual del punto de partida quedan diferidos. | 🟢 DONE |
| **TICK-013** | UI/Map | Implementar la ficha de escuela al tocar un pin: pin seleccionado, tarjeta peek + bottom sheet expandible con nivel, modalidad, turnos, dirección, teléfono con acción de llamada, localidad, líneas de colectivo, distancia desde el origen y mini-mapa embebido. Acciones `Cómo llegar` y `Añadir a comparativa`. Cerrar al tocar el mapa. | 🟢 DONE |
| **TICK-014** | UI/State | Agregar chips horizontales por nivel (Todas, Jardín, Primaria, Secundaria, Técnica, Especial y Adultos), conectados a `levelFilterProvider` y combinados con la búsqueda textual para filtrar los pines del mapa. | 🟢 DONE |
| **TICK-015** | UI | Implementar autocompletado offline del buscador: sugerencias por nombre/número mientras se tipea, selección que centra el mapa en la escuela y navegación por teclado. Requisito del MMP ("Buscador Autocompletado"). | 🟢 DONE |
| **TICK-016** | State/UI | Implementar búsqueda inversa por línea de colectivo (CU-Opcional 02): selector de línea alimentado por `transportLines`, filtrado del mapa y contador de escuelas servidas. | 🟢 DONE |
| **TICK-017** | State/UI | Implementar filtro de Zona Segura con radio global en Riverpod, slider en Perfil, círculo sobre el mapa y filtrado por distancia Haversine desde el origen. | 🟢 DONE |
| **TICK-018** | UI/State | Agregar vista de lista sincronizada con filtros del mapa, con nombre, nivel, dirección y distancia desde el origen. Al seleccionar una escuela, vuelve al mapa, centra el pin y abre su ficha. | 🟢 DONE |
| **TICK-019** | State/UI | Agregar favoritos en memoria con `favoritesProvider`, acción corazón en la ficha y pantalla `Mis favoritas` con estado vacío y tarjetas con nombre, nivel y dirección. Persistencia, distancias, orden y comparación quedan para iteraciones futuras. | 🟢 DONE |
| **TICK-020** | State/UI | Comparador en memoria de hasta 4 escuelas con selección desde la ficha, ranking por distancia Haversine al origen, indicador de opción más cercana y retiro de escuelas desde la lista. | 🟢 DONE |
| **TICK-021** | UI/Nav | Agregar navegación inferior MD3 con Mapa, Comparativa, Favoritos y Perfil. Mantener el mapa y buscador en Mapa; mostrar placeholders en Comparativa, Favoritos y Perfil. | 🟢 DONE |
| **TICK-022** | UI/State | Implementar Perfil con identidad de aspirante, punto de partida, radio máximo, turnos de interés, indicador de almacenamiento offline y cierre de sesión. Las preferencias se mantienen en estado local de pantalla, sin persistencia. | 🟢 DONE |
| **TICK-023** | State/Auth | Validar DNI/legajo localmente, mantener la sesión en Riverpod, recordar el DNI en el dispositivo y conectar el ingreso/salida con la navegación. Mesa de Ayuda y Listado Oficial muestran feedback informativo. | 🟢 DONE |
| **TICK-024** | Map/Infra | Implementar caché offline de tiles y banner de conectividad. El PRD promete funcionamiento 100% offline, pero hoy sin red el mapa queda vacío. Cachear tiles visitados y avisar `Sin conexión` sin bloquear búsqueda ni fichas. **Resuelto con la caché nativa de `flutter_map` 8.2+** (`BuiltInMapCachingProvider`): `configureTileCache()` fija directorio persistente, techo de 250 MB y frescura de 30 días antes del primer frame. Se descartó `flutter_map_tile_caching` por conflicto de `latlong2` (exige `^0.9.x` vs `^0.10.1` de `flutter_map` 8.3.2), licencia GPL-3.0 y falta de soporte web. `isOfflineProvider` + `ConnectivityBanner` muestran el aviso en una fila propia del `Scaffold`, fuera del `Stack` del mapa, así que no toca buscador, filtros, fichas ni distancias. | 🟢 DONE |
| **TICK-025** | State/UI | Mostrar tiempos estimados a pie, en auto y en colectivo según distancia y velocidades urbanas asumidas, en la ficha y en la comparativa. El ruteo real queda diferido. | 🟢 DONE |
| **TICK-026** | Splash/UI | Diseñar Splash institucional con identidad del Consejo Escolar, indicador de modo offline y carga visual; al finalizar, dirigir según el estado de sesión local. | 🟢 DONE |
| **TICK-027** | UI/State | Mejoras UX de Zona Segura y autocompletado sincronizado: activar/desactivar el filtro, ajustar el radio en cuadras y sugerir solo escuelas que cumplen nivel, colectivo y zona seleccionados. | 🟢 DONE |
| **TICK-028** | Bugfix/Map | La app crashea al escribir en el buscador. Revisar el provider y el ajuste de cámara cuando el filtro deja un solo resultado, sin casts ni parseos inválidos. | 🟢 DONE |
| **TICK-029** | UI/Map | Agregar etiquetas de texto con la sigla de cada escuela (ej. `PP 32`, `ES`, `JI 940`, `CENS`) sobre los pines del mapa. | 🟢 DONE |

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
  conexión con el comparador y cierre al tocar el mapa) se implementó en una
  iteración posterior.
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

## Sprint 5: Bugs y Estabilización

| Ticket | Módulo | Descripción | Estado |
|---|---|---|---|
| **TICK-030** | Bugfix/UI | La ficha mostraba `'🚌 Líneas: 540, 277, 164'` hardcodeado para toda escuela. Ahora renderiza `school.transportLines` (solo el campo `line`, unido por comas) con fallback `No informado` cuando no hay datos. | 🟢 DONE |
| **TICK-031** | Bugfix/Map | Zona Segura: el auto-fit de cámara ya no se dispara al cambiar el radio (el mapa queda estático y el círculo se ve contraerse), slider ampliado a 90 cuadras y contador `N de 307 escuelas visibles` en Perfil. | 🟢 DONE |
| **BUG-001** | Bugfix/UI | Sincronización Autocompletado y Filtros: las sugerencias del buscador se alimentan de `mapVisibleSchoolsProvider` (nivel + colectivo + Zona Segura, sin texto) y usan el mismo matcher que el mapa (`schoolMatchesQuery`), así nunca ofrecen escuelas que el mapa oculta ni dejan el cartel "No se encontraron escuelas" en conflicto con el overlay del buscador. | 🟢 DONE |
| **TICK-032** | Data (ETL) | Normalizar las variantes de líneas de colectivo del seed (`79 SAN JOSE` / `79 S. JOSÉ` / `79 SJOSE`, letras sueltas como `B`, `C`) a ramales canónicos y completar las 14 escuelas sin líneas. Base de auditoría: `auditoria_escuelas.csv`. | ⚫ WONTFIX |
| **TICK-033** | State/UX | Punto de partida editable (HU-02): `UserOrigin` persistido en `shared_preferences`, picker en mapa + etiqueta en Perfil, `originLocationProvider` derivado para que ficha, lista, comparador y Zona Segura recalculen desde ahí. El domicilio se resuelve **offline**: `generar_indice_calles.py` deriva `assets/calles_lomas.json` (165 calles con bounds) del propio padrón, el campo autocompleta por tokens y el pin se afina arrastrando el mapa. Sin dependencias nuevas, sin GPS y sin red. | 🟢 DONE |
| **TICK-034** | Data (ETL) | Inyectar el padrón de 310 escuelas en `assets/escuelas_seed.json`, corregir coordenadas y aplicar trim a los campos de texto. Commit `c96dd8c`. | 🟢 DONE |
| **TICK-035** | Data (ETL) | `reparador_automatico.py`: reparar las coordenadas corruptas por Excel (se reinserta el punto decimal tras el prefijo 34/58) y geocodificar las 78 direcciones de intersección con ArcGIS aplicando validación estructural (rechazo de centroides de calle), bbox del partido y filtro de partidos ajenos. Genera `escuelas_reparadas_final.csv` y `revision_manual.csv`. Documentado en `docs/05_Geocoding.md`. | 🟢 DONE |
| **TICK-036** | Data (QA) | Revisión manual de las 10 escuelas sin match confiable. Se cargaron las coordenadas de Google Maps en `overrides_manual.json`, que el script aplica con prioridad sobre ArcGIS (validando que caigan dentro del partido). `revision_manual.csv` baja de 54 a 44 filas: quedan 18 con desvío mayor a 3 km, 31 con localidad distinta y 8 con coincidencia parcial. | 🟢 DONE |
| **TICK-037** | Bugfix/Data | El seed regenerado en `8b7a98c` salió con las claves planas del CSV (`nombre`, `nivel`, `zona`, `direccion`), así que `School.fromJson` parseaba 310 escuelas con `name`, `level` y `address` vacíos, `locality` vacía y sin `transportLines`: tarjetas y pines sin nombre, filtros de nivel y colectivo muertos. `csv_a_seed_json.py` ahora emite el contrato de `docs/02_Architecture.md` §3.1, valida todo antes de escribir y recupera teléfonos del seed histórico; `SchoolRepository` valida en debug con un `assert` que ninguna escuela quede sin nombre. Commit `5aab97f`. | 🟢 DONE |

### Notas de estado

- **TICK-032 (⚫ WONTFIX):** se descarta la normalización de variantes de línea. El costo de limpiar la data cruda y sostener excepciones manuales supera el beneficio en UX. El filtro por colectivo sigue operativo; las variantes del nomenclador aparecen como entradas separadas en el selector.

## Sprint 6: Cierre 1.0 — Puerta de Entrada y Contacto

Estos tickets no amplían el MMP del PRD (buscador offline, punto de partida, ficha y comparador ya están cubiertos): cierran la experiencia de entrada, el contacto con el Consejo y la higiene de release.

| Ticket | Módulo | Descripción | Estado |
|---|---|---|---|
| **TICK-038** | State/Auth | Persistencia de sesión: guardar el flag de sesión y el DNI activo en `shared_preferences`, hidratar la sesión al arrancar y hacer que el Splash espere esa carga (hoy lee `sessionProvider` sincrónico, que arranca en `null`, y siempre manda a Login). `_signOut` en Perfil debe limpiar el flag persistido, no solo el estado en memoria. El checkbox "Recordar mi DNI" se conserva como preferencia de prellenado y sobrevive al cierre de sesión. | 🟢 DONE |
| **TICK-039** | UI/QA | Suite verde y Splash: incorporar el fondo real desde `prototipo_ui/splash_screen_mobile_consejo_escolar_ldz/screen.png` y declararlo en `pubspec.yaml` (hoy no existe ningún asset de imagen en el repo), corregir el overflow de 193px de la píldora "Geolocalización y Ruteo Inmediato" en `_SplashIdentity`, mockear `SharedPreferences` en los widget tests, alinear el pump del test con `_loadingDuration` (2300ms vs 2700ms) y envolver `HomeScreen` con un ancestro `Material` en `home_screen_search_test.dart`. Baseline al abrir: 11 verdes, 3 rojos. | ⚪ TO DO |
| **TICK-040** | Integración | Mesa de Ayuda: abrir `mailto:ce062auxiliares.abc.gob.ar` con asunto prearmado (`Consulta - Mapa Escolar`) vía `url_launcher` (ya declarado en `pubspec.yaml`), con feedback si el dispositivo no tiene cliente de correo. Debe estar en Login **y** en Perfil, porque con TICK-038 el Login deja de mostrarse en cada arranque y el acceso quedaría huérfano. | ⚪ TO DO |
| **TICK-041** | Release | Higiene de release: reemplazar `applicationId = "com.example.mapa_escolar"`, definir firma de release (hoy usa debug keys), agregar `<queries>` de `mailto:` y `tel:` en `AndroidManifest.xml` para Android 11+, y reemplazar el ícono y el launch screen por defecto de Flutter. | ⚪ TO DO |

### Puntaje

El módulo de Puntaje se mantiene con el estado "Próximamente" y se difiere a la v2. No se agrega ticket en este sprint.

### Evidencia de apertura del Sprint 6

- `main` local estaba 18 commits detrás de `origin/main`: TICK-024, TICK-033 y TICK-034..037 ya estaban integrados pero ausentes del working copy. La medición y el desarrollo de este sprint parten de `0e1149b`.
- Suite al abrir el sprint: 11 tests verdes, 3 rojos (`home_screen_search_test` ×2 por falta de ancestro `Material` y `widget_test` por timing del Splash más overflow de 193px).
