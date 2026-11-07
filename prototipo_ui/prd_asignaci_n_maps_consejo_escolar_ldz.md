# Documento de Requisitos de Producto (PRD) / Product Brief

**Proyecto:** Asignación Maps — Herramienta Móvil de Geolocalización, Ruteo y Comparativa de Escuelas  
**Organismo / Ámbito:** Consejo Escolar de Lomas de Zamora (LDZ), DGCyE  
**Destinatarios:** Auxiliares de la Educación (Portería, Mantenimiento, Cocina)  
**Estado:** V1.0 Especificación Funcional Consolidada  

---

## 1. Visión y Propósito del Producto

Durante los Actos Públicos presenciales para la cobertura de cargos auxiliares, los aspirantes deben tomar decisiones críticas en cuestión de segundos cuando se anuncia una vacante vacía en un establecimiento educativo. Históricamente, esta decisión se toma a ciegas, sin certeza sobre distancias reales, combinaciones de colectivos ni tiempos de traslado desde sus hogares o puntos de partida.

**Asignación Maps** es una aplicación móvil diseñada específicamente como una **herramienta táctica de geolocalización, ruteo multimodal y comparación offline**. 

> **Aclaración crítica de alcance (Anti-alcance):**  
> La aplicación **NO** es un portal para postularse a vacantes, ni un sistema de votación remota, ni tramita reclamos de puntajes u obleas oficiales. Su única misión es asistir en tiempo real a la toma de decisiones informada sobre qué vacantes convienen elegir presencialmente.

---

## 2. Objetivos Estratégicos & KPIs

1. **Agilidad en la Toma de Decisión:** Reducir a menos de 10 segundos el tiempo que un aspirante tarda en conocer la ubicación exacta, líneas de transporte y tiempo estimado hacia cualquier escuela anunciada.
2. **Resiliencia Operativa Offline:** Funcionamiento garantizado 100% offline dentro de los salones de asambleas donde la conectividad celular (3G/4G/5G o Wi-Fi) suele saturarse o ser nula.
3. **Decisiones Multimodales Claras:** Proveer ranking comparativo instantáneo entre 2 o más instituciones basándose en tiempo de viaje, líneas de colectivo directas y turnos.

---

## 3. Personas y Casos de Uso

### Persona Principal: Auxiliar Aspirante a Cargo
* **Contexto:** Se encuentra sentado en el gimnasio o salón del Consejo Escolar durante el Acto Público presencial.
* **Problema:** El moderador canta: *"EP N° 12, Banfield Oeste, Turno Mañana"*. El aspirante no recuerda la calle exacta ni qué colectivo lo deja en puerta.
* **Solución de la app:** Abre la app, busca "EP 12" o la toca en el mapa, observa que está a 14 min (colectivo 541 directo) desde su casa guardada, la añade al comparador y levanta la mano seguro en el acto.

---

## 4. Arquitectura de Módulos & Pantallas

### Módulo 0: Splash Screen Institucional (Móvil)
* **Objetivo:** Bienvenida institucional, validación de base de datos local y precarga offline.
* **Componentes clave:**
  * Logo oficial e institucional del Consejo Escolar de Lomas de Zamora (con el Escudo Provincial y las Islas Malvinas).
  * Indicador de estado: *"Inicializando base de datos local..."* y badge de funcionamiento offline.
  * Versión del paquete de datos de escuelas y líneas municipales.

### Módulo 1: Mapa Táctico de Escuelas (Pantalla Principal)
* **Objetivo:** Exploración espacial inmediata con filtrado dinámico.
* **Componentes clave:**
  * **Top Bar Flotante:** Buscador por número o nombre de escuela (`EP N° ...`, `EES N° ...`, `Jardín N° ...`) y filtros rápidos (Nivel, Turno, Radio km).
  * **Punto de Partida Dinámico:** Banner anclado que muestra el origen configurado (*ej: Av. Meeks 850, Temperley*).
  * **Mapa Interactivo:** Pines visualmente clasificados por nivel (Primaria, Secundaria, Inicial, Especial), con tarjetas flotantes al tocar.
  * **Barra de Navegación Inferior (MD3):** Destinos fijos: `Mapa`, `Comparativa`, `Favoritos`, `Perfil`.

### Módulo 2: Ficha Rápida / Detalle de Escuela (Modal Bottom Sheet)
* **Objetivo:** Ficha técnica sin perder el contexto visual del mapa.
* **Componentes clave:**
  * Tiempos y modos de transporte (Colectivo, Auto, A pie) calculados desde el punto de partida.
  * Líneas directas de transporte que pasan a menos de 300 metros (ej: *Líneas 541, 160, 548*).
  * Datos operativos: Nivel, Modalidad, Turnos disponibles (Mañana / Tarde / Vespertino) y características edilicias.
  * Botones de acción rápida:
    * `Añadir a Comparativa` (+): Envía la escuela al ranking del Módulo 4.
    * `Favorito` (Ícono de corazón/marcador): Guarda para acceso rápido en su lista personal.

### Módulo 3: Lista de Favoritos / Escuelas Guardadas
* **Objetivo:** Espacio de preselección antes de ingresar al acto público.
* **Componentes clave:**
  * Estado de sincronización local visible (*"Modo Offline Sincronizado"*).
  * Listado de tarjetas de establecimientos con distancias y líneas principales.
  * Acciones por tarjeta: *"Ver Ruta"* y *"Al Comparador"*.
  * Botón maestro para *"Comparar todas en ranking"*.

### Módulo 4: Comparador de Escuelas (Ranking de Conveniencia)
* **Objetivo:** Comparar de 2 a 4 escuelas simultáneas para decidir cuál elegir al momento de ser llamado por lista.
* **Componentes clave:**
  * Algoritmo de ponderación: Menor tiempo de viaje y menor cantidad de transbordos.
  * Insignia destacada para la **Opción Ganadora** (*#1 en cercanía / Más conveniente*).
  * Desglose lado a lado: tiempo total, líneas de colectivo, horario de ingreso y trayecto a pie.
  * Acciones directas: **"Ver en mapa"** (conectar directo con el mapa táctico) y **"Ver Ruta"**.

### Módulo 5: Perfil & Preferencias de Ruteo
* **Objetivo:** Configuración de origen y filtros que alimentan el motor de cálculo geográfico.
* **Componentes clave:**
  * Datos de identificación del aspirante (Nombre, DNI, Legajo).
  * **Punto de Partida:** Domicilio o coordenada base con selector de *"Cambiar"*, origen universal de las distancias en toda la app.
  * **Preferencias de transporte:** Medio preferido (Colectivo, A pie, Auto), radio de acción máximo deseado y turnos prioritarios.
  * Cierre de sesión y estado de almacenamiento local del dispositivo.

---

## 5. Requerimientos Técnicos y de Diseño (Design System)

* **Guías Visuales:** Material Design 3 (Google MD3).
* **Paleta de Color:**
  * Azul Institucional Primario: `#1a73e8` / Deep Blue Gubernamental.
  * Superficies: Neutros claros `#f7f9ff`, tarjetas contrastadas en `#ffffff`.
  * Estados y Acentos: Verde esmeralda para la opción ganadora de ruteo, ámbar para advertencias de transbordo.
* **Tipografía:** Inter / Roboto para máxima legibilidad en dispositivos de gama media y baja.
* **Accesibilidad:** Cumplimiento WCAG AA, áreas táctiles mínimas de 48x48 dp para uso ágil en movilidad.
* **Arquitectura de Datos Offline:** SQLite / IndexedDB con precarga de polígonos, calles y recorridos del Municipio de Lomas de Zamora.

---

## 6. Próximos Pasos & Roadmap

1. **Fase 1 (Completada):** Prototipado y validación de UI/UX de las 6 pantallas móviles clave y su flujo interactivo.
2. **Fase 2:** Definición del esquema de datos JSON/GeoJSON para el catálogo municipal de escuelas y paradas de colectivos.
3. **Fase 3:** Integración del motor de cálculo de distancias ortodrómicas / ruteo offline embebido en el cliente móvil.