import 'package:flutter_riverpod/flutter_riverpod.dart';

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
