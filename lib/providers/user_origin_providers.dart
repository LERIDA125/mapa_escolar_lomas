import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/user_origin.dart';

/// Persistence for the applicant's point of departure, following the same
/// pattern as [AuthPreferences] in `auth_providers.dart`.
class UserOriginPreferences {
  static const _userOriginKey = 'user_origin_v1';

  Future<UserOrigin?> read() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_userOriginKey);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return UserOrigin.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  Future<void> save(UserOrigin origin) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _userOriginKey,
      jsonEncode(origin.toJson()),
    );
    if (!saved) {
      throw StateError('No se pudo guardar el punto de partida.');
    }
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_userOriginKey);
  }
}

final userOriginPreferencesProvider = Provider<UserOriginPreferences>(
  (ref) => UserOriginPreferences(),
);

/// The applicant's point of departure.
///
/// Starts at [UserOrigin.fallback] and hydrates from disk as soon as
/// `shared_preferences` resolves. `build` stays synchronous on purpose:
/// [originLocationProvider] is read as a plain `LatLng` by the map, the list,
/// the detail sheet, the comparator and the safe-zone filter, so an
/// `AsyncNotifier` would force all five into `AsyncValue`.
class UserOriginNotifier extends Notifier<UserOrigin> {
  bool _disposed = false;

  @override
  UserOrigin build() {
    ref.onDispose(() => _disposed = true);
    Future<void>.microtask(_hydrate);
    return UserOrigin.fallback;
  }

  Future<void> _hydrate() async {
    final preferences = ref.read(userOriginPreferencesProvider);

    UserOrigin? stored;
    try {
      stored = await preferences.read();
    } catch (_) {
      // Unreadable storage (or a missing plugin binding under unit tests) is
      // not fatal: the fallback origin is a valid state, so there is nothing
      // to recover from.
      return;
    }

    if (_disposed || stored == null) return;
    state = stored;
  }

  Future<void> setOrigin(UserOrigin origin) async {
    if (!origin.isInsidePartido) {
      throw ArgumentError.value(
        origin.label,
        'origin',
        'El punto de partida debe estar dentro del partido de Lomas de Zamora.',
      );
    }

    // Persist first: if the write fails the caller gets the error and the
    // in-memory origin is left untouched, so the UI never claims a change that
    // will not survive a restart.
    await ref.read(userOriginPreferencesProvider).save(origin);
    if (_disposed) return;
    state = origin;
  }

  Future<void> reset() async {
    state = UserOrigin.fallback;
    try {
      await ref.read(userOriginPreferencesProvider).clear();
    } catch (_) {
      // The in-memory reset already happened; a storage failure must not block
      // falling back to the default origin.
    }
  }
}

final userOriginProvider = NotifierProvider<UserOriginNotifier, UserOrigin>(
  UserOriginNotifier.new,
);
