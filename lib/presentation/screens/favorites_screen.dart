import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/school_models.dart';
import '../../providers/school_providers.dart';
import '../theme/app_theme.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final schoolsAsync = ref.watch(schoolsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis favoritas')),
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
          final favoriteSchools = schools
              .where((school) => favorites.contains(school.id))
              .toList(growable: false);

          if (favoriteSchools.isEmpty) {
            return const _EmptyFavorites();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favoriteSchools.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _FavoriteSchoolCard(school: favoriteSchools[index]),
          );
        },
      ),
    );
  }
}

class _FavoriteSchoolCard extends StatelessWidget {
  const _FavoriteSchoolCard({required this.school});

  final School school;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primaryFixed,
          child: Icon(Icons.favorite_rounded, color: AppColors.error, size: 20),
        ),
        title: Text(school.name),
        subtitle: Text(
          [
            if (school.level.isNotEmpty) school.level,
            if (school.address.isNotEmpty) school.address,
          ].join('\n'),
        ),
        isThreeLine: school.level.isNotEmpty && school.address.isNotEmpty,
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_border_rounded,
              size: 48,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Todavía no tienes escuelas favoritas',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Guarda una escuela desde su ficha en el mapa.',
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
