import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/services/tile_cache.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Before the first frame: the tile cache policy has to be in place before any
  // TileLayer asks for its first tile.
  await configureTileCache();

  runApp(const ProviderScope(child: MapaEscolarApp()));
}

class MapaEscolarApp extends StatelessWidget {
  const MapaEscolarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapa Escolar Lomas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        MainScreen.routeName: (_) => const MainScreen(),
      },
    );
  }
}
