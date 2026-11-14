# TICK-041 — Release hygiene

## Objetivo

Dejar el proyecto listo para compilar un APK identificable, firmable y con ícono
propio, sin peso muerto versionado.

## Problema

El proyecto seguía con la configuración que genera `flutter create`:

- `applicationId` y `namespace` en `com.example.mapa_escolar`.
- Release firmado con las **debug keys**, que no sirven para publicar ni para
  actualizar una instalación existente.
- `android:label` = "Mapa Escolar Lomas" (no el nombre corto pedido).
- Ícono y launch screen por defecto de Flutter.
- `assets/escuelas_seed.backup.json` versionado: 232 KB de instantánea del seed que
  el ETL usa como fuente de teléfonos.
- `.gitignore` con las dos últimas líneas escritas en **UTF-16 dentro de un archivo
  UTF-8**, así que `auditoria_escuelas.csv` y `auditoria_gps_cache.json` nunca
  quedaron ignorados de verdad.

## Corrección de una premisa propia

En el ticket anterior se afirmó que el backup del seed "engorda el APK". **Es falso.**
Flutter solo empaqueta los assets declarados en `pubspec.yaml`, y ahí solo están
`escuelas_seed.json` y `calles_lomas.json`. El backup nunca llegó al APK: es peso
muerto del **repositorio**, no del binario.

## Alcance

- Identidad Android: `applicationId` y `namespace` a `ar.gob.abc.mapaescolar`, con
  `MainActivity` movida al paquete nuevo.
- Firma de release por `android/key.properties`, con fallback a debug si el archivo
  no existe (comportamiento actual intacto).
- `android:label` = "Mapa Escolar LDZ".
- `flutter_launcher_icons` como dev dependency, configurado sobre `assets/icono.png`.
- `userAgentPackageName` de OSM alineado con el nuevo identificador.
- `.gitignore` reescrito en UTF-8 limpio, con `key.properties`, `*.jks`, `*.keystore`
  y el backup del seed.
- `assets/escuelas_seed.backup.json` fuera del índice (`git rm --cached`) pero
  conservado en disco: el ETL lo necesita para recuperar teléfonos.

## Fuera de alcance

- Generar el keystore: requiere una contraseña que decide el usuario.
- Identificadores de iOS, macOS, Windows y Linux: el entregable del PRD es un APK
  de Android.
- Subir `versionName`/`versionCode`.

## Decisiones técnicas

- **Se renombra `namespace` además de `applicationId`.** Cambiar solo el
  `applicationId` deja `MainActivity` declarada como `.MainActivity` dentro de un
  paquete `com.example` que ya no representa al proyecto. El `namespace` define el
  paquete de la clase y del `R`; si no se mueve junto, el manifest sigue apuntando
  al paquete viejo. Se mueve el archivo Kotlin y se actualiza su `package`.
- **Firma por `key.properties` con fallback.** Si `android/key.properties` existe,
  el release usa esa config; si no, cae en debug como hoy. Cero regresión para
  quien no tenga el keystore, y el día que lo tenga solo agrega el archivo.
- **El backup del seed se desindexa, no se borra del disco.** El ETL
  (`csv_a_seed_json.py:34`) lo lee como fuente de teléfonos. Borrarlo del working
  copy rompería la regeneración del seed en esta máquina; sacarlo del índice y
  agregarlo al `.gitignore` resuelve el peso muerto sin romper el pipeline.
- **El ícono de origen es chico.** `assets/icono.png` mide 163×163 px. Con esa
  entrada, `flutter_launcher_icons` escala a 192 px para `xxxhdpi`, así que el
  ícono queda algo blando en pantallas modernas. El mecanismo funciona, pero hay
  que reemplazar el archivo por uno de 1024×1024 y volver a correr el comando
  antes de publicar.
- **`userAgentPackageName` se actualiza.** Es el identificador que la app manda a
  OpenStreetMap en cada request de tiles. Dejarlo en `com.example` mientras el
  paquete real cambia es exactamente el tipo de inconsistencia que OSM usa para
  bloquear clientes.

## Checklist

- [x] T041-1 `namespace` y `applicationId` = `ar.gob.abc.mapaescolar`.
- [x] T041-2 `MainActivity.kt` movida al paquete nuevo.
- [x] T041-3 Firma de release por `android/key.properties` con fallback a debug.
- [x] T041-4 `android:label` = "Mapa Escolar LDZ".
- [x] T041-5 `flutter_launcher_icons` en `dev_dependencies` y bloque de configuración.
- [x] T041-6 `userAgentPackageName` alineado en `home_screen` y `origin_picker_sheet`.
- [x] T041-7 `.gitignore` en UTF-8 limpio con `key.properties`, `*.jks`, `*.keystore` y el backup.
- [x] T041-8 `assets/escuelas_seed.backup.json` fuera del índice.
- [x] T041-9 `flutter test`, `flutter analyze` y `flutter build apk --debug` sin errores.
- [x] T041-10 `dart run flutter_launcher_icons` corrido desde `assets/icono.png`: mipmaps
  `launcher_icon` en las 5 densidades y `android:icon` apuntando a `@mipmap/launcher_icon`.

## Criterios de aceptación

1. El APK se instala como `ar.gob.abc.mapaescolar` y se muestra como "Mapa Escolar LDZ".
2. `flutter build apk --debug` compila sin tocar `key.properties`.
3. Con `android/key.properties` presente, el release firma con esa clave.
4. La suite sigue en 0 rojos.
5. `git status` no muestra el backup del seed ni archivos de firma.

## Verificación

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- `dart run flutter_launcher_icons`

## Progreso

- [x] Rama `chore/TICK-041-release-hygiene` creada sobre TICK-040.
- [x] `flutter build apk --debug` → `√ Built build\app\outputs\flutter-apk\app-debug.apk`;
  `aapt2 dump packagename` → `ar.gob.abc.mapaescolar`.
- [x] Error de compilación corregido: `java.util.Properties()` y
  `java.io.FileInputStream` no resuelven dentro de `build.gradle.kts` porque
  `java` choca con la extensión de Gradle. Se resolvió con `import` explícito
  arriba del bloque `plugins`.
- [x] Ícono generado por el responsable del proyecto desde `assets/icono.png`.
