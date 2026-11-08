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

  bool signIn(String dni) {
    if (!isValidDni(dni)) return false;
    state = dni;
    return true;
  }

  void signOut() => state = null;
}

class AuthPreferences {
  static const _rememberedDniKey = 'remembered_dni';

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
}
