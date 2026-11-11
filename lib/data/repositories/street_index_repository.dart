import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/street_index.dart';

/// Offline street index built from the school catalog.
///
/// Ships inside the app bundle, so resolving an address never touches the
/// network.
class StreetIndexRepository {
  const StreetIndexRepository({this.assetPath = 'assets/calles_lomas.json'});

  final String assetPath;

  Future<List<StreetIndexEntry>> getStreets({AssetBundle? bundle}) async {
    final rawJson = await (bundle ?? rootBundle).loadString(assetPath);
    final decoded = jsonDecode(rawJson);

    if (decoded is! List) {
      throw const FormatException(
        'Street index asset must contain a JSON array.',
      );
    }

    return decoded
        .map((item) => StreetIndexEntry.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
