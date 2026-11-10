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

/// Holds the selected bus line filter.
final busLineFilterProvider = StateProvider<String>((ref) => 'Todas');

/// Snapshot of the filters that drive the map camera auto-fit.
typedef CameraFitFilters = ({String level, String busLine, String query});

/// Filters that trigger the camera auto-fit, excluding the safe zone.
///
/// Changing the safe-zone radius must not re-frame the map: the circle has to
/// stay visible contracting against a static camera. Records use structural
/// equality, so this only notifies when search, level or bus line really
/// change.
final cameraFitFiltersProvider = Provider<CameraFitFilters>((ref) {
  return (
    level: ref.watch(levelFilterProvider),
    busLine: ref.watch(busLineFilterProvider),
    query: ref.watch(searchQueryProvider),
  );
});

/// Returns the unique bus lines present in the complete local school catalog.
final availableBusLinesProvider = Provider<AsyncValue<List<String>>>((ref) {
  return ref.watch(schoolsProvider).whenData((schools) {
    final lines = schools
        .expand((school) => school.transportLines)
        .map((transport) => transport.line.trim())
        .where((line) => line.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return ['Todas', ...lines];
  });
});

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

/// Schools that pass every active control except the text search: level, bus
/// line and safe zone.
///
/// Single shared source for the map pins, the list and the autocomplete
/// suggestions, so the buscador can never offer a school that the map hides.
/// The text query is intentionally excluded: it is applied later by
/// [filteredSchoolsProvider] (map/list) and by the autocomplete itself.
final mapVisibleSchoolsProvider = Provider<AsyncValue<List<School>>>((ref) {
  final schoolsAsync = ref.watch(schoolsProvider);
  final selectedLevel = ref.watch(levelFilterProvider);
  final selectedBusLine = ref.watch(busLineFilterProvider).trim().toLowerCase();
  final safeZoneEnabled = ref.watch(safeZoneEnabledProvider);
  final safeZoneRadiusBlocks = ref.watch(safeZoneRadiusProvider);
  final origin = ref.watch(originLocationProvider);
  final normalizedLevel = selectedLevel == 'Todas'
      ? ''
      : _normalizeLevel(selectedLevel);
  final safeZoneRadiusKm = safeZoneRadiusBlocks / 10;

  return schoolsAsync.whenData(
    (schools) => schools
        .where(
          (school) =>
              (normalizedLevel.isEmpty ||
                  _normalizeLevel(school.level).contains(normalizedLevel)) &&
              (selectedBusLine == 'todas' ||
                  school.transportLines.any(
                    (transport) =>
                        transport.line.trim().toLowerCase() == selectedBusLine,
                  )) &&
              (!safeZoneEnabled ||
                  calculateDistanceKm(
                        origin: origin,
                        destination: LatLng(school.latitude, school.longitude),
                      ) <=
                      safeZoneRadiusKm),
        )
        .toList(growable: false),
  );
});

/// Whether [school] matches the free-text [query].
///
/// Single source of truth shared by [filteredSchoolsProvider] and the
/// autocomplete, so both apply the exact same rules (case-insensitive over
/// name, address, locality and official code). Keeping them in sync avoids the
/// buscador suggesting schools the map filters out.
bool schoolMatchesQuery(School school, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return true;

  return school.name.toLowerCase().contains(normalizedQuery) ||
      school.address.toLowerCase().contains(normalizedQuery) ||
      school.locality.name.toLowerCase().contains(normalizedQuery) ||
      (school.codigoOficial?.toLowerCase().contains(normalizedQuery) ?? false);
}

/// Applies the current search query on top of [mapVisibleSchoolsProvider].
///
/// Loading and error states are forwarded untouched, so widgets can keep
/// showing the same spinners and error views.
final filteredSchoolsProvider = Provider<AsyncValue<List<School>>>((ref) {
  final schoolsAsync = ref.watch(mapVisibleSchoolsProvider);
  final query = ref.watch(searchQueryProvider);

  return schoolsAsync.whenData(
    (schools) => schools
        .where((school) => schoolMatchesQuery(school, query))
        .toList(growable: false),
  );
});
