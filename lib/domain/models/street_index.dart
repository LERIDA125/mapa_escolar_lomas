import 'package:latlong2/latlong.dart';

/// One street derived from the school catalog, used to place the applicant's
/// origin without leaving the offline world.
///
/// `search` arrives pre-normalized from `generar_indice_calles.py`, so the Dart
/// side only has to normalize the query, never the index.
class StreetIndexEntry {
  const StreetIndexEntry({
    required this.name,
    required this.search,
    required this.latitude,
    required this.longitude,
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final String name;
  final String search;
  final double latitude;
  final double longitude;
  final double south;
  final double west;
  final double north;
  final double east;

  LatLng get center => LatLng(latitude, longitude);

  /// Whether the bounds collapse to a single point. Fitting the camera to a
  /// zero-area rectangle would zoom in nonsensically, so callers fall back to
  /// [center] plus a fixed zoom.
  bool get isSinglePoint => south == north && west == east;

  factory StreetIndexEntry.fromJson(Map<String, dynamic> json) {
    final bounds = json['bounds'] as Map<String, dynamic>? ?? const {};
    final latitude = (json['latitude'] as num?)?.toDouble() ?? 0;
    final longitude = (json['longitude'] as num?)?.toDouble() ?? 0;

    return StreetIndexEntry(
      name: json['name'] as String? ?? '',
      search: json['search'] as String? ?? '',
      latitude: latitude,
      longitude: longitude,
      south: (bounds['south'] as num?)?.toDouble() ?? latitude,
      west: (bounds['west'] as num?)?.toDouble() ?? longitude,
      north: (bounds['north'] as num?)?.toDouble() ?? latitude,
      east: (bounds['east'] as num?)?.toDouble() ?? longitude,
    );
  }
}
