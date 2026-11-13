import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authPreferencesProvider = Provider<AuthPreferences>(
  (ref) => AuthPreferences(),
);

final rememberedDniProvider = FutureProvider<String?>(
  (ref) => ref.watch(authPreferencesProvider).readRememberedDni(),
);

final sessionProvider = NotifierProvider<SessionNotifier, String?>(
  SessionNotifier.new,
);

bool isValidDni(String dni) => RegExp(r'^\d{7,8}$').hasMatch(dni);

class SessionNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Restaura la sesión persistida. Nunca lanza: si el almacenamiento local
  /// falla, el arranque cae en Login en lugar de bloquearse.
  Future<void> restore() async {
    if (state != null) return;

    final preferences = ref.read(authPreferencesProvider);
    try {
      final isLoggedIn = await preferences.readIsLoggedIn();
      if (!isLoggedIn) return;

      final dni = await preferences.readSessionDni();
      if (dni == null || !isValidDni(dni)) {
        await preferences.clearSession();
        return;
      }

      state = dni;
    } catch (error) {
      debugPrint('No se pudo restaurar la sesión: $error');
    }
  }

  /// Persiste la sesión activa y la preferencia de prellenado del DNI.
  /// Lanza si el almacenamiento rechaza la escritura para que el Login avise
  /// que la sesión no va a sobrevivir a un reinicio.
  Future<bool> signIn(String dni, {required bool rememberDni}) async {
    if (!isValidDni(dni)) return false;

    final preferences = ref.read(authPreferencesProvider);
    await preferences.saveRememberedDni(rememberDni ? dni : null);
    await preferences.saveSession(dni);
    state = dni;
    return true;
  }

  /// Borra la sesión persistida. Si la escritura falla, la sesión en memoria
  /// se conserva para no simular un cierre que no sobrevive al reinicio.
  Future<void> signOut() async {
    await ref.read(authPreferencesProvider).clearSession();
    state = null;
  }
}

class AuthPreferences {
  static const _rememberedDniKey = 'remembered_dni';
  static const _isLoggedInKey = 'is_logged_in';
  static const _sessionDniKey = 'session_dni';

  Future<String?> readRememberedDni() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_rememberedDniKey);
  }

  Future<void> saveRememberedDni(String? dni) async {
    final preferences = await SharedPreferences.getInstance();
    if (dni == null) {
      await preferences.remove(_rememberedDniKey);
      return;
    }

    final saved = await preferences.setString(_rememberedDniKey, dni);
    if (!saved) {
      throw StateError('No se pudo guardar el DNI en este dispositivo.');
    }
  }

  Future<bool> readIsLoggedIn() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_isLoggedInKey) ?? false;
  }

  Future<String?> readSessionDni() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_sessionDniKey);
  }

  Future<void> saveSession(String dni) async {
    final preferences = await SharedPreferences.getInstance();
    final savedDni = await preferences.setString(_sessionDniKey, dni);
    final savedFlag = await preferences.setBool(_isLoggedInKey, true);
    if (!savedDni || !savedFlag) {
      await preferences.remove(_sessionDniKey);
      await preferences.setBool(_isLoggedInKey, false);
      throw StateError('No se pudo guardar la sesión en este dispositivo.');
    }
  }

  Future<void> clearSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionDniKey);
    final cleared = await preferences.setBool(_isLoggedInKey, false);
    if (!cleared) {
      throw StateError('No se pudo cerrar la sesión en este dispositivo.');
    }
  }
}
