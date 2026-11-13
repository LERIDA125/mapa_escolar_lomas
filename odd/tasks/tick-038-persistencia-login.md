# TICK-038 — Persistencia de sesión y arranque sin fricción

## Objetivo

Que el login funcione como barrera real una sola vez: al volver a abrir la app, la
sesión se restaura desde disco y el Splash entra directo al mapa. Cerrar sesión
desde Perfil debe borrar esa persistencia para que el login vuelva a exigirse.

## Problema

`sessionProvider` es un `Notifier<String?>` cuyo `build()` devuelve `null`
(`lib/providers/auth_providers.dart:20`). El Splash decide el destino leyendo ese
estado sincrónico (`lib/presentation/screens/splash_screen.dart:30`), así que
siempre arranca en `null` y siempre manda a Login. `AuthPreferences` solo persiste
`remembered_dni` (prellenado del campo), no la sesión. `_signOut` en Perfil solo
limpia memoria (`lib/presentation/screens/profile_screen.dart:25`).

## Alcance

- Nuevas claves persistidas: `is_logged_in` (bool) y `session_dni` (String).
- `SessionNotifier.restore()`: hidrata el estado desde disco validando el DNI.
- `SessionNotifier.signIn()`: persiste sesión + preferencia de prellenado y setea estado.
- `SessionNotifier.signOut()`: limpia estado y claves de sesión, conserva `remembered_dni`.
- Splash: espera la restauración antes de rutear (arregla la race).
- Login: usa la API async nueva respetando el checkbox "Recordar mi DNI".
- Perfil: `_signOut` async y con guard de `mounted`.
- Tests nuevos de persistencia en `test/auth_session_test.dart`.

## Fuera de alcance

- Rediseño visual del Login, Splash o Perfil.
- Arreglar los 3 tests rojos de la suite: es TICK-039.
- Mesa de Ayuda: es TICK-040.
- Firma, `applicationId` y manifest: es TICK-041.

## Decisiones técnicas

- Se mantiene `NotifierProvider<SessionNotifier, String?>` para no romper
  `main_screen`, Splash ni Perfil, que leen el estado sincrónico.
- Dos claves con una sola fuente de verdad efectiva: la sesión solo se considera
  válida si `is_logged_in == true` **y** `session_dni` es un DNI válido. Si no
  coinciden, se limpian ambas y se trata como sesión cerrada.
- `remembered_dni` es independiente de la sesión: sobrevive al logout para
  prellenar el campo (semántica original del checkbox).
- `restore()` no propaga excepciones de plataforma: si el almacenamiento falla,
  deja la sesión en `null` y el Splash cae en Login. La app nunca se bloquea por
  preferencias.

## Checklist

- [x] T038-1 `AuthPreferences` con `readIsLoggedIn`, `readSessionDni`, `saveSession`, `clearSession`.
- [x] T038-2 `SessionNotifier.restore/signIn/signOut` async con validación y manejo de fallos.
- [x] T038-3 Splash espera `restore()` y rutea según el estado hidratado.
- [x] T038-4 Login usa `signIn(dni, rememberDni:)` conservando sus snackbars de error.
- [x] T038-5 Perfil limpia la sesión persistida antes de navegar al Login.
- [x] T038-6 Tests nuevos: persistencia, restauración, logout, DNI inválido y sesión inconsistente.
- [x] T038-7 `flutter analyze` sin issues nuevos y suite con el mismo baseline (11 verdes, 3 rojos de TICK-039).

## Criterios de aceptación

1. Login válido con checkbox marcado → cerrar y reabrir la app entra directo al mapa
   sin pedir DNI.
2. Login válido con checkbox desmarcado → igual restaura la sesión; el DNI no queda
   prellenado tras cerrar sesión.
3. Cerrar sesión desde Perfil → borra `is_logged_in` y `session_dni`; reabrir exige login.
4. Si el almacenamiento local falla, el Splash no crashea: cae en Login.
5. Un `session_dni` inválido o un flag sin DNI nunca otorga sesión.

## Verificación

- `flutter analyze`
- `flutter test test/auth_session_test.dart`
- `flutter test` (baseline esperado: 11 verdes, 3 rojos de TICK-039)

## Ruta de implementación

Delegada a un writer (5 archivos no triviales). La evidencia de exploración ya está
en este documento y en el ticket, así que no hace falta un explorer previo.

## Progreso

- [x] Backlog actualizado y TICK-032 marcado WONTFIX (commit `7ba5ab2` en `main`).
- [x] Rama `feature/TICK-038-persistencia-login` creada.
- [x] T038-1..T038-6 implementados en `lib/providers/auth_providers.dart`,
  `splash_screen.dart`, `login_screen.dart`, `profile_screen.dart` y
  `test/auth_session_test.dart`. RED observado: el test no compilaba por
  `rememberDni`/`restore` inexistentes.
- [x] Verificación observada por el padre: `flutter test
  test/auth_session_test.dart` → 7/7 verdes; `flutter analyze` → `No issues
  found!`; `flutter test` → 18 verdes, 3 rojos preexistentes de TICK-039.
