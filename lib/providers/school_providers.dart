import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:latlong2/latlong.dart';

import '../data/repositories/school_repository.dart';
import '../domain/models/school_models.dart';
import 'location_providers.dart';

/// Exposes the repository so widgets and other providers never instantiate it.
final schoolRepositoryProvider = Provider<SchoolRepository>(
  (ref) => const SchoolRepository(),
);

/// Loads the school catalog once and caches the result for its consumers.
final schoolsProvider = FutureProvider<List<School>>(
  (ref) => ref.watch(schoolRepositoryProvider).getSchools(),
);

/// Holds the text typed in the school search field.
///
/// Starts empty so the map and list show the full catalog until the user
/// types something.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Holds the selected education level filter.
final levelFilterProvider = StateProvider<String>((ref) => 'Todas');

/// Keeps favorite school IDs in memory for the current app session.
final favoritesProvider = NotifierProvider<FavoritesNotifier, List<String>>(
  FavoritesNotifier.new,
);

class FavoritesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  void toggle(String schoolId) {
    state = state.contains(schoolId)
        ? state.where((id) => id != schoolId).toList(growable: false)
        : [...state, schoolId];
  }
}

/// Keeps up to four school IDs for the in-memory comparison list.
final comparatorProvider = NotifierProvider<ComparatorNotifier, List<String>>(
  ComparatorNotifier.new,
);

class ComparatorNotifier extends Notifier<List<String>> {
  static const maxSchools = 4;

  @override
  List<String> build() => const [];

  bool toggle(String schoolId) {
    if (state.contains(schoolId)) {
      state = state.where((id) => id != schoolId).toList(growable: false);
      return false;
    }

    if (state.length >= maxSchools) return false;

    state = [...state, schoolId];
    return true;
  }
}

String _normalizeLevel(String value) {
  return value
      .toLowerCase()
      .replaceAll('ã©', 'e')
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
}

/// Applies the current search query on top of [schoolsProvider].
///
/// Loading and error states are forwarded untouched, so widgets can keep
/// showing the same spinners and error views. Matching is case-insensitive
/// across the school name, address and locality, and can be narrowed by level.
final filteredSchoolsProvider = Provider<AsyncValue<List<School>>>((ref) {
  final schoolsAsync = ref.watch(schoolsProvider);
  final normalizedQuery = ref.watch(searchQueryProvider).trim().toLowerCase();
  final selectedLevel = ref.watch(levelFilterProvider);
  final origin = ref.watch(originLocationProvider);
  final safeZoneRadiusKm = ref.watch(safeZoneRadiusProvider);
  final normalizedLevel = selectedLevel == 'Todas'
      ? ''
      : _normalizeLevel(selectedLevel);

  return schoolsAsync.whenData(
    (schools) => schools
        .where(
          (school) =>
              (normalizedQuery.isEmpty ||
                  school.name.toLowerCase().contains(normalizedQuery) ||
                  school.address.toLowerCase().contains(normalizedQuery) ||
                  school.locality.name.toLowerCase().contains(
                    normalizedQuery,
                  )) &&
              (normalizedLevel.isEmpty ||
                  _normalizeLevel(school.level).contains(normalizedLevel)) &&
              calculateDistanceKm(
                    origin: origin,
                    destination: LatLng(school.latitude, school.longitude),
                  ) <=
                  safeZoneRadiusKm,
        )
        .toList(growable: false),
  );
});
