import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../widgets/connectivity_banner.dart';
import 'comparator_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  static const routeName = HomeScreen.routeName;

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.map_rounded), label: 'Mapa'),
    NavigationDestination(
      icon: Icon(Icons.compare_arrows_rounded),
      label: 'Comparativa',
    ),
    NavigationDestination(
      icon: Icon(Icons.favorite_rounded),
      label: 'Favoritos',
    ),
    NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    if (ref.watch(sessionProvider) == null) {
      return const LoginScreen();
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeScreen(),
          ComparatorScreen(),
          FavoritesScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sits in its own row, outside the map Stack, so it can never cover
          // the search bar, the filter chips or the school sheet.
          const ConnectivityBanner(),
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: _destinations,
          ),
        ],
      ),
    );
  }
}
