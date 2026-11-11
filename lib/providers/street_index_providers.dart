import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/street_index_repository.dart';
import '../domain/models/street_index.dart';

final streetIndexRepositoryProvider = Provider<StreetIndexRepository>(
  (ref) => const StreetIndexRepository(),
);

/// Streets known to the offline index, loaded once from the app bundle.
final streetIndexProvider = FutureProvider<List<StreetIndexEntry>>(
  (ref) => ref.watch(streetIndexRepositoryProvider).getStreets(),
);
