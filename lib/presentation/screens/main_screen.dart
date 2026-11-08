import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const routeName = HomeScreen.routeName;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeScreen(),
          _ComingSoonScreen(tabName: 'Comparativa'),
          _ComingSoonScreen(tabName: 'Favoritos'),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: _destinations,
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.tabName});

  final String tabName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Próximamente: $tabName',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: AppColors.onSurface),
        ),
      ),
    );
  }
}
