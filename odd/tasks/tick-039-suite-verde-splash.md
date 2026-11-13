# TICK-039 — Suite verde y fondo del Splash

## Objetivo

Dejar la suite de tests completamente verde (0 rojos) y cerrar el pendiente visual
del Splash: fondo corporativo en degradado y layout sin overflow en pantallas
ajustadas.

## Problema

Al abrir el Sprint 6 la suite tenía 3 tests rojos:

1. `test/home_screen_search_test.dart` → "narrowing the search to a single school
   does not crash".
2. `test/home_screen_search_test.dart` → "map markers show school abbreviations
   and numbers".
3. `test/widget_test.dart` → "splash hands off to the login screen".

Causas verificadas:

- Los dos tests de `HomeScreen` montaban `MaterialApp(home: HomeScreen())` sin
  ancestro `Material`. `HomeScreen` devuelve un `Stack`, no un `Scaffold`, porque
  en producción vive dentro del `Scaffold` de `main_screen.dart`. Sin `Material`,
  cada `ChoiceChip` lanza "No Material widget found." y el layout colapsa con un
  overflow espurio de 99228 px. No era un bug de producto: era el test montando
  el widget fuera de su contexto real.
- El test del Splash pumpeaba 2300 ms contra un `_loadingDuration` de 2700 ms, así
  que nunca llegaba a la navegación, y no mockeaba `SharedPreferences`.
- El Splash desbordaba 193 px en 320×568: la píldora "Geolocalización y Ruteo
  Inmediato" es un `Row` con `mainAxisSize.min` y un `Text` rígido, sin `Flexible`.

## Alcance

- `test/home_screen_search_test.dart`: montar `HomeScreen` bajo `Scaffold`.
- `test/widget_test.dart`: mockear `SharedPreferences` y alinear el pump con
  `_loadingDuration`.
- `lib/presentation/screens/splash_screen.dart`: fondo en degradado corporativo y
  píldora adaptable.
- `docs/04_Tickets.md`: TICK-039 a `🟢 DONE` con la evidencia real.

## Fuera de alcance

- Exportar el PNG del fondo desde `prototipo_ui/`: el archivo sigue sin existir en
  `assets/`. Se usa el degradado como reemplazo temporal hasta esa exportación.
- Mesa de Ayuda (TICK-040) e higiene de release (TICK-041).

## Decisiones técnicas

- **Test de `HomeScreen` con `Scaffold`, no cambio de producto.** `HomeScreen` es
  un widget de contenido; agregarle un `Scaffold` propio duplicaría el de
  `MainScreen` y rompería la barra de navegación inferior.
- **`Flexible` en la píldora, no `FittedBox`.** Con `FittedBox` el texto se
  encogería hasta ~7 px en 320 dp. Con `Flexible` el texto envuelve en dos líneas
  y conserva el tamaño tipográfico. La columna ya vive dentro de un
  `SingleChildScrollView`, así que crecer en vertical es seguro.
- **Degradado con tokens existentes.** `AppColors.splashTop/splashMid/splashBottom`
  ya estaban definidos en el tema y solo se usaba el primero. No se agregan colores
  nuevos ni se toca la paleta.

## Checklist

- [x] T039-1 `Scaffold` como ancestro de `HomeScreen` en `home_screen_search_test.dart`.
- [x] T039-2 `SharedPreferences.setMockInitialValues({})` en el `setUp` de `widget_test.dart`.
- [x] T039-3 Pump del Splash a 2800 ms (por encima de `_loadingDuration`).
- [x] T039-4 Píldora del Splash con `Flexible` y `textAlign: center`.
- [x] T039-5 Fondo en degradado `splashTop → splashMid → splashBottom`.
- [x] T039-6 `flutter test` en 0 rojos y `flutter analyze` limpio.

## Criterios de aceptación

1. `flutter test` termina con todos los tests en verde.
2. `flutter analyze` no reporta issues.
3. En 320×568 el Splash no produce overflow y navega al Login.
4. El Splash mantiene su identidad visual con un fondo corporativo coherente.

## Verificación

- `flutter test` → 21 tests verdes.
- `flutter analyze` → `No issues found!`

## Progreso

- [x] Rama `feature/TICK-039-suite-verde-splash` creada sobre TICK-038.
- [x] Los tres tests rojos reparados en su causa raíz.
- [x] Splash sin overflow y con fondo en degradado.
- [x] Suite completa verde y analyze limpio.
