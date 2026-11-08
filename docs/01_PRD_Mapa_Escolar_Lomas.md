01_PRD_Mapa_Escolar_Lomas.md (Documento Fundacional)

1.  Planteo del Caso
    Durante los actos públicos virtuales para la designación de auxiliares (porteros) en Lomas de Zamora, las vacantes se exponen de forma telemática siguiendo el orden de mérito de los aspirantes. Aunque disponen de un breve margen de tiempo para analizar las opciones, los postulantes suelen tener dificultades para gestionar esta información de manera eficiente. Esto se debe a la falta de experiencia, el desconocimiento territorial y la gran extensión del partido, que cuenta con más de 200 establecimientos educativos. La carencia de herramientas ágiles para geolocalizar las escuelas, calcular tiempos de viaje o evaluar opciones de transporte público dificulta enormemente la toma de decisiones informadas bajo la presión del acto.
2.  Arquitectura y Stack Tecnológico
    El sistema seguirá un patrón Offline-First Híbrido y se distribuirá como una aplicación móvil instalable (APK):
    Frontend / Framework: Flutter (Dart). Permite empaquetar un APK de alto rendimiento, ideal para dispositivos Android de gama entrada/media.
    Almacenamiento Local (Offline): La base de datos de escuelas (nomenclador, direcciones, colectivos) reside estáticamente dentro del binario de la aplicación (assets/escuelas_seed.json), permitiendo búsquedas instantáneas sin depender de la conectividad.
    Gestión de Estado: Riverpod (exclusivo) para manejar la UI del comparador de escuelas.
    Mapas (Online): flutter_map + latlong2 sobre tiles raster de OpenStreetMap. La geocodificación se resuelve en el ETL con Nominatim; la app no usa Google Maps ni API keys de mapas.
3.  Alcance y MMP (Minimum Marketable Product)
    Buscador Autocompletado (Offline): Filtrado instantáneo por nombre/número de escuela desde los datos locales.
    Geolocalización Base: Punto de partida manual o automático por GPS.
    Ficha Individual: Mapa embebido interactivo con los datos de la escuela. El cálculo de rutas y tiempos queda para una iteración posterior.
    Comparador Multiescuela: Carga de hasta 4 escuelas simultáneas con ranking automático de cercanía desde el punto de partida.
4.  Modelo de Datos Lógico (ERD y UML)
    Basado en el nomenclador estructurado por zonas (Lomas, Banfield, Temperley, Llavallol, Fiorito, Budge, V. Albertina).
    Diagrama Entidad-Relación (ERD - Base de Datos)
    erDiagram
    LOCALIDAD ||--o{ ESCUELA : "contiene"
    ESCUELA ||--o{ ESCUELA_COLECTIVO : "servida_por"
    COLECTIVO ||--o{ ESCUELA_COLECTIVO : "recorre"

        ESCUELA {
            UUID id_escuela PK
            String numero_nombre
            String tipo_nivel
            String direccion
            String telefono
            Decimal latitud
            Decimal longitud
            UUID id_localidad FK
        }
        LOCALIDAD {
            UUID id_localidad PK
            String nombre
            String zona
        }
        COLECTIVO {
            UUID id_colectivo PK
            String linea
        }
        ESCUELA_COLECTIVO {
            UUID id_escuela FK
            UUID id_colectivo FK
        }

    Diagrama de Clases UML (Modelo de Dominio Dart/Flutter)
    classDiagram
    class Locality {
    +String id
    +String name
    +String zone
    }
    class School {
    +String id
    +String name
    +String level
    +String address
    +String phone
    +double latitude
    +double longitude
    +Locality locality
    +List~TransportLine~ transportLines
    }
    class TransportLine {
    +String id
    +String line
    }
    School "_" --> "1" Locality : ubicada_en
    School "_" --> "\*" TransportLine : servida_por

5.  Módulos del Sistema
    Módulo 1: Data Ingestion (ETL): Script Python para parsear el documento base, limpiar la data, geocodificar direcciones con Nominatim (`geocoder.py`) y exportar un escuelas_seed.json.
    Módulo 2: Interfaz de Búsqueda: Buscador local en Dart para filtrado fuzzy sobre el JSON embebido en los assets.
    Módulo 3: Motor de Mapas: FlutterMap con tiles de OpenStreetMap y marcadores alimentados por Riverpod. El ruteo y las matrices de distancia quedan fuera del MMP actual.
    Módulo 4: Motor de Comparación: Gestor de estado que mantiene hasta 4 entidades en memoria y ordena por cercanía usando las coordenadas locales.
6.  Historias de Usuario (User Stories)
    HU-01: Como aspirante, quiero buscar una escuela por su número/nombre (sin necesidad de internet) para ver su teléfono y dirección.
    HU-02: Como aspirante, quiero establecer mi ubicación actual (GPS o tipeada) para usarla como punto de partida.
    HU-03: Como aspirante, quiero ver la ruta, distancia y líneas de colectivo hacia una escuela seleccionada para saber cómo llegar de forma óptima.
    HU-04: Como aspirante, quiero comparar hasta 4 escuelas simultáneamente para decidir rápido cuál me queda más cerca durante el acto público.
7.  Primeros Tickets (Setup y Data)
    TICK-001 [Docs]: Inicializar repositorio en Github, configurar ramas y armar estructura SDD (/docs/01_PRD, 02_Architecture, 03_Guidelines, 04_Tickets).
    TICK-002 [ETL]: Crear script base en Python para extraer, limpiar y exportar las escuelas del PDF a escuelas_seed.json.
    TICK-003 [Infra]: Inicializar proyecto en Flutter, configurar dependencias base (riverpod, flutter_map, latlong2) y empaquetar el JSON en la carpeta assets.
    TICK-005 [ETL]: Geocodificar las direcciones del seed con Nominatim, normalizando localidades abreviadas e intersecciones.
8.  Casos de Uso Opcionales (Futuras Iteraciones / Sprint 2)
    CU-Opcional 01: Lista de Favoritos (Pre-selección): Búsqueda previa al acto público para marcar escuelas con una estrella y guardarlas en una pestaña de "Favoritos", generando un subconjunto filtrado listo para comparar bajo presión.
    CU-Opcional 02: Búsqueda Inversa por Línea de Colectivo: Filtrado del mapa iluminando únicamente las escuelas servidas por una línea de transporte específica (ej. "544"), basándose en los datos del nomenclador.
    CU-Opcional 03: Filtro por Nivel Educativo: Selectores rápidos (chips) para mostrar u ocultar instituciones según su tipo (Jardines de Infantes, Primarias, Secundarias, Técnicas, Especiales, Adultos).
    CU-Opcional 04: Modo "Zona Segura" (Radio de Cercanía): Slider que permite establecer un radio de distancia máxima (ej. "menos de 5 km") desde la ubicación base del usuario, ocultando visualmente las escuelas fuera de ese límite para reducir el ruido visual.
