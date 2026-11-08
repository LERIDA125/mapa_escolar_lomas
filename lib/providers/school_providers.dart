import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/repositories/school_repository.dart';
import '../domain/models/school_models.dart';

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

/// Applies the current search query on top of [schoolsProvider].
///
/// Loading and error states are forwarded untouched, so widgets can keep
/// showing the same spinners and error views. An empty query returns the full
/// catalog. Matching is case-insensitive across the school name, the address
/// and the locality name.
final filteredSchoolsProvider = Provider<AsyncValue<List<School>>>((ref) {
  final schoolsAsync = ref.watch(schoolsProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  if (query.isEmpty) {
    return schoolsAsync;
  }

  return schoolsAsync.whenData(
    (schools) => schools
        .where(
          (school) =>
              school.name.toLowerCase().contains(query) ||
              school.address.toLowerCase().contains(query) ||
              school.locality.name.toLowerCase().contains(query),
        )
        .toList(growable: false),
  );
});
