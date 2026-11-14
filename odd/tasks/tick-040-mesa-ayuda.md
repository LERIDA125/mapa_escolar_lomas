# TICK-040 — Mesa de Ayuda por correo

## Objetivo

Que "Mesa de Ayuda" abra un correo real a `ce062auxiliares.abc.gob.ar` con asunto
prearmado, y que sea alcanzable tanto desde el Login como desde Perfil.

## Problema

Hoy el botón "Mesa de Ayuda" (`login_screen.dart:283`) solo muestra un SnackBar con
"La mesa de ayuda estará disponible próximamente.". Con TICK-038 la sesión se
persiste, así que el Login deja de aparecer en cada arranque: sin un acceso en
Perfil, el usuario logueado pierde el contacto con el Consejo de forma permanente.

## Alcance

- `lib/data/services/support_mail.dart`: helper con la URI y el lanzamiento.
- `login_screen.dart`: "Mesa de Ayuda" abre el correo en vez del SnackBar pendiente.
- `profile_screen.dart`: nueva sección "Ayuda" con un `ListTile` a la mesa de ayuda.
- `android/app/src/main/AndroidManifest.xml`: `<queries>` de `mailto:` (y `tel:`,
  que arrastra el mismo problema).
- `test/support_mail_test.dart`: tests de la URI.
- `docs/04_Tickets.md`: TICK-040 a DONE y el ítem de `<queries>` movido desde TICK-041.

## Fuera de alcance

- Cambiar el asunto o el destinatario del correo.
- Formulario de contacto in-app.
- `applicationId`, firma de release e ícono (siguen en TICK-041).

## Decisiones técnicas

- **El `<queries>` se adelanta desde TICK-041 y se implementa acá.** Sin esa
  declaración, Android 11+ devuelve `false` en `canLaunchUrl(mailto:)` aunque Gmail
  esté instalado: el botón diría "no hay cliente de correo" en todos los equipos
  modernos. Entregar una feature que no funciona en producción para respetar el
  reparto de tickets es peor que mover un ítem de ticket. Se agrega el bloque
  `<queries>` completo (`mailto:` y `tel:`) y se retira esa línea de TICK-041.
- **Helper en `lib/data/services/`, no en un widget.** Login necesita un `TextButton`
  y Perfil un `ListTile`; forzar un widget compartido obligaría a parametrizar el
  layout. El helper devuelve `bool` y cada pantalla decide su feedback.
- **La URI se arma con `Uri.encodeComponent`, no con `queryParameters`.** El
  constructor `Uri(queryParameters:)` codifica el espacio como `+`, que en `mailto:`
  no es un espacio: el asunto llegaría como `Consulta+-+Mapa+Escolar`.
- **`canLaunchUrl` antes de `launchUrl`, con `PlatformException` capturada.** En
  escritorio y en tests el canal puede no existir; el helper nunca propaga la
  excepción, siempre devuelve `false`.

## Checklist

- [x] T040-1 `buildSupportMailUri()` con destinatario y asunto codificados.
- [x] T040-2 `launchSupportMail()` con `canLaunchUrl`, `launchUrl` y captura de `PlatformException`.
- [x] T040-3 Login: "Mesa de Ayuda" lanza el correo con SnackBar de error.
- [x] T040-4 Perfil: sección "Ayuda" con `ListTile` a la mesa de ayuda.
- [x] T040-5 `<queries>` de `mailto:` y `tel:` en `AndroidManifest.xml`.
- [x] T040-6 Tests de la URI (esquema, destinatario, asunto decodificado).
- [x] T040-7 `flutter test` verde y `flutter analyze` limpio.

## Criterios de aceptación

1. Tocar "Mesa de Ayuda" en Login abre el cliente de correo con destinatario y
   asunto ya cargados.
2. Un usuario logueado encuentra la misma acción en Perfil.
3. Si no hay cliente de correo, la app muestra un SnackBar claro y no rompe.
4. La suite sigue en 0 rojos.

## Verificación

- `flutter analyze`
- `flutter test`

## Progreso

- [x] Rama `feature/TICK-040-mesa-ayuda` creada sobre TICK-039.
- [x] `url_launcher: ^6.3.3` ya estaba declarado y está up-to-date.
