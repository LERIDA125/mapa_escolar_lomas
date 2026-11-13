import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mapa_escolar/providers/auth_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Simula un arranque nuevo de la app: cada container es una sesión en
  // memoria independiente que solo puede recuperar estado desde disco.
  ProviderContainer createContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('Sesión persistida', () {
    test('un arranque nuevo no tiene sesión', () async {
      final container = createContainer();

      expect(container.read(sessionProvider), isNull);

      await container.read(sessionProvider.notifier).restore();
      expect(container.read(sessionProvider), isNull);
    });

    test('iniciar sesión persiste y se restaura en el próximo arranque',
        () async {
      final container = createContainer();
      final signedIn = await container
          .read(sessionProvider.notifier)
          .signIn('35123456', rememberDni: true);

      expect(signedIn, isTrue);
      expect(container.read(sessionProvider), '35123456');

      final nextLaunch = createContainer();
      await nextLaunch.read(sessionProvider.notifier).restore();
      expect(nextLaunch.read(sessionProvider), '35123456');
    });

    test('un DNI inválido no inicia sesión', () async {
      final container = createContainer();

      expect(
        await container
            .read(sessionProvider.notifier)
            .signIn('123', rememberDni: true),
        isFalse,
      );
      expect(container.read(sessionProvider), isNull);

      expect(
        await container
            .read(sessionProvider.notifier)
            .signIn('abcdefgh', rememberDni: true),
        isFalse,
      );
      expect(container.read(sessionProvider), isNull);
    });

    test('cerrar sesión borra la sesión pero conserva el DNI recordado',
        () async {
      final container = createContainer();
      await container
          .read(sessionProvider.notifier)
          .signIn('35123456', rememberDni: true);

      await container.read(sessionProvider.notifier).signOut();
      expect(container.read(sessionProvider), isNull);

      final nextLaunch = createContainer();
      await nextLaunch.read(sessionProvider.notifier).restore();
      expect(nextLaunch.read(sessionProvider), isNull);

      final preferences = nextLaunch.read(authPreferencesProvider);
      expect(await preferences.readRememberedDni(), '35123456');
      expect(await preferences.readIsLoggedIn(), isFalse);
      expect(await preferences.readSessionDni(), isNull);
    });

    test('sin recordar el DNI no queda prellenado en el próximo arranque',
        () async {
      final container = createContainer();
      await container
          .read(sessionProvider.notifier)
          .signIn('35123456', rememberDni: false);

      final nextLaunch = createContainer();
      await nextLaunch.read(sessionProvider.notifier).restore();
      expect(nextLaunch.read(sessionProvider), '35123456');
      expect(await nextLaunch.read(rememberedDniProvider.future), isNull);
    });

    test('un estado inconsistente nunca otorga sesión y se limpia', () async {
      SharedPreferences.setMockInitialValues({
        'is_logged_in': true,
        'session_dni': 'abc',
      });

      final container = createContainer();
      await container.read(sessionProvider.notifier).restore();

      expect(container.read(sessionProvider), isNull);

      final preferences = container.read(authPreferencesProvider);
      expect(await preferences.readIsLoggedIn(), isFalse);
      expect(await preferences.readSessionDni(), isNull);
    });

    test('flag apagado con DNI guardado nunca otorga sesión', () async {
      SharedPreferences.setMockInitialValues({
        'is_logged_in': false,
        'session_dni': '35123456',
      });

      final container = createContainer();
      await container.read(sessionProvider.notifier).restore();

      expect(container.read(sessionProvider), isNull);
    });
  });
}
