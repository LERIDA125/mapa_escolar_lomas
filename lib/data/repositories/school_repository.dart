import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/school_models.dart';

/// Offline-first source of truth for the school catalog.
///
/// The seed file ships inside the app bundle, so reading it never touches
/// the network.
class SchoolRepository {
  const SchoolRepository({this.assetPath = 'assets/escuelas_seed.json'});

  final String assetPath;

  Future<List<School>> getSchools({AssetBundle? bundle}) async {
    final rawJson = await (bundle ?? rootBundle).loadString(assetPath);
    final decoded = jsonDecode(rawJson);

    if (decoded is! List) {
      throw const FormatException(
        'School seed asset must contain a JSON array.',
      );
    }

    final schools = decoded
        .map((item) => School.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    // The seed must honour the contract documented in
    // docs/02_Architecture.md §3.1. Without this guard a renamed key degrades
    // into a catalog of blank cards instead of failing loudly in debug.
    assert(
      schools.every((school) => school.name.isNotEmpty),
      'Seed contract mismatch: some schools parsed with an empty name.',
    );

    return schools;
  }
}
