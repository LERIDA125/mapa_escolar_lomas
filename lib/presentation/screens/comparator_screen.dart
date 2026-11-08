import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/models/school_models.dart';
import '../../providers/location_providers.dart';
import '../../providers/school_providers.dart';
import '../theme/app_theme.dart';

class ComparatorScreen extends ConsumerWidget {
  const ComparatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolIds = ref.watch(comparatorProvider);
    final origin = ref.watch(originLocationProvider);
    final schoolsAsync = ref.watch(schoolsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Comparativa')),
      body: schoolsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudieron cargar las escuelas: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (schools) {
          final selectedSchools =
              schools
                  .where((school) => schoolIds.contains(school.id))
                  .toList(growable: false)
                ..sort((first, second) {
                  final firstDistance = _distanceFrom(origin, first);
                  final secondDistance = _distanceFrom(origin, second);
                  return firstDistance.compareTo(secondDistance);
                });

          if (selectedSchools.isEmpty) {
            return const _EmptyComparator();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: selectedSchools.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final school = selectedSchools[index];
              return _ComparisonCard(
                school: school,
                distanceKm: _distanceFrom(origin, school),
                isClosest: index == 0,
                onRemove: () {
                  ref.read(comparatorProvider.notifier).toggle(school.id);
                },
              );
            },
          );
        },
      ),
    );
  }

  double _distanceFrom(LatLng origin, School school) {
    return calculateDistanceKm(
      origin: origin,
      destination: LatLng(school.latitude, school.longitude),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.school,
    required this.distanceKm,
    required this.isClosest,
    required this.onRemove,
  });

  final School school;
  final double distanceKm;
  final bool isClosest;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    school.name,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: AppColors.onSurface),
                  ),
                ),
                IconButton(
                  tooltip: 'Quitar de la comparativa',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            if (isClosest)
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(
                    Icons.near_me_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  label: const Text('Opción más cercana'),
                  labelStyle: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: AppColors.success),
                  backgroundColor: AppColors.successSurface,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            const SizedBox(height: 4),
            _ComparisonDetail(
              icon: Icons.school_outlined,
              label: 'Nivel',
              value: school.level.isNotEmpty
                  ? school.level
                  : School.notInformed,
            ),
            const SizedBox(height: 8),
            _ComparisonDetail(
              icon: Icons.directions_car_outlined,
              label: 'Distancia',
              value: '${distanceKm.toStringAsFixed(1)} km',
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonDetail extends StatelessWidget {
  const _ComparisonDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyComparator extends StatelessWidget {
  const _EmptyComparator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.compare_arrows_rounded,
              size: 48,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Tu comparativa está vacía',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Agrega escuelas desde su ficha en el mapa para compararlas.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
