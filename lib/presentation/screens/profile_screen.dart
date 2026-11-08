import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../providers/location_providers.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _morningShift = true;
  bool _afternoonShift = true;
  bool _eveningShift = false;

  void _signOut() {
    ref.read(sessionProvider.notifier).signOut();
    Navigator.of(context)
        .pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxRadius = ref.watch(safeZoneRadiusProvider);
    final userDni = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          const SizedBox(height: 8),
          Column(
            children: [
              const CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primaryFixed,
                child: Icon(
                  Icons.person_rounded,
                  size: 48,
                  color: AppColors.onPrimaryFixedVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Aspirante',
                style: textTheme.headlineSmall?.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'DNI ${userDni ?? ''}',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _ProfileSectionTitle(title: 'Ubicación y búsqueda'),
          Card(
            margin: EdgeInsets.zero,
            color: AppColors.surface,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text('Punto de partida'),
                  subtitle: Text('Av. Hipólito Yrigoyen 8700, Lomas de Zamora'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Radio máximo (Zona Segura)',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${maxRadius.toStringAsFixed(0)} km',
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: maxRadius,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '${maxRadius.toStringAsFixed(0)} km',
                        onChanged: (value) {
                          ref.read(safeZoneRadiusProvider.notifier).state =
                              value;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _ProfileSectionTitle(title: 'Preferencias'),
          Card(
            margin: EdgeInsets.zero,
            color: AppColors.surface,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.wb_sunny_outlined),
                  title: const Text('Mañana'),
                  value: _morningShift,
                  onChanged: (value) {
                    setState(() => _morningShift = value);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.wb_twilight_rounded),
                  title: const Text('Tarde'),
                  value: _afternoonShift,
                  onChanged: (value) {
                    setState(() => _afternoonShift = value);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.nights_stay_outlined),
                  title: const Text('Vespertino'),
                  value: _eveningShift,
                  onChanged: (value) {
                    setState(() => _eveningShift = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _ProfileSectionTitle(title: 'Sistema'),
          Card(
            margin: EdgeInsets.zero,
            color: AppColors.surface,
            child: const ListTile(
              leading: Icon(Icons.cloud_done_rounded, color: AppColors.success),
              title: Text('Almacenamiento Offline Activo'),
              subtitle: Text(
                'El catálogo de escuelas está disponible sin conexión.',
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: AppColors.onSurface),
      ),
    );
  }
}
