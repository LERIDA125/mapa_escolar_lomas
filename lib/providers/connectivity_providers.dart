import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the device currently has no usable network connection.
///
/// `true` only when the platform reports [ConnectivityResult.none], which
/// `connectivity_plus` guarantees arrives as the sole element of the list.
/// Wi-Fi, mobile, ethernet and bluetooth all count as connected.
///
/// The notifier is optimistic on purpose: it starts at `false` and stays there
/// when the platform channel is missing (unit tests, unsupported platform), so
/// a plugin failure never paints an offline banner on a device that is online.
/// A wrong "connected" reading is harmless, a wrong "offline" one is alarming.
class ConnectivityNotifier extends Notifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _disposed = false;

  @override
  bool build() {
    ref.onDispose(() {
      _disposed = true;
      _subscription?.cancel();
    });

    // Everything touching the plugin lives inside this try: `Connectivity()`
    // itself can throw when the platform channel is not registered, and an
    // exception here would propagate out of the Scaffold that hosts the
    // banner. A decorative widget must never be able to break the app shell.
    try {
      final connectivity = Connectivity();
      _subscription = connectivity.onConnectivityChanged.listen(
        (results) {
          if (!_disposed) state = _isOffline(results);
        },
        // A broken stream must not surface as a provider error: the banner is
        // decorative, it never owns an error state the UI has to render.
        onError: (Object _) {},
      );

      Future<void>.microtask(() async {
        try {
          final results = await connectivity.checkConnectivity();
          if (!_disposed) state = _isOffline(results);
        } catch (_) {
          // Keep the optimistic default.
        }
      });
    } catch (_) {
      // Platform channel unavailable: keep the optimistic default.
    }

    return false;
  }
}

bool _isOffline(List<ConnectivityResult> results) =>
    results.isEmpty ||
    results.every((result) => result == ConnectivityResult.none);

/// `true` when the device has no network connection.
final isOfflineProvider = NotifierProvider<ConnectivityNotifier, bool>(
  ConnectivityNotifier.new,
);
