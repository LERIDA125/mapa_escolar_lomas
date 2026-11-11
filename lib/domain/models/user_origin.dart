import 'package:latlong2/latlong.dart';

/// How the applicant's point of departure was chosen.
enum UserOriginSource {
  /// The neutral fallback baked into the app (Plaza Grigera).
  fallback,

  /// Picked by panning the map inside the origin sheet.
  map,

  /// Typed as a street address and matched against the offline street index.
  address,
}

/// The point every distance, ranking and safe-zone calculation measures from.
///
/// Persisted in `shared_preferences`, so the applicant sets it once from
/// Perfil and the filter keeps honouring it across restarts.
class UserOrigin {
  const UserOrigin({
    required this.label,
    required this.latitude,
    required this.longitude,
    this.source = UserOriginSource.fallback,
  });

  /// Plaza Grigera: the neutral centre of the partido, used until the
  /// applicant picks a real address.
  static const fallback = UserOrigin(
    label: 'Plaza Grigera, Lomas de Zamora',
    latitude: -34.7618,
    longitude: -58.4022,
  );

  /// Bounding box of the Lomas de Zamora partido. A point outside this
  /// rectangle is a bad geocode, not a home.
  static const double minLatitude = -34.90;
  static const double maxLatitude = -34.62;
  static const double minLongitude = -58.60;
  static const double maxLongitude = -58.28;

  /// Human readable address shown in Perfil.
  final String label;
  final double latitude;
  final double longitude;
  final UserOriginSource source;

  LatLng get latLng => LatLng(latitude, longitude);

  bool get isFallback => source == UserOriginSource.fallback;

  /// Whether the point falls inside the partido.
  bool get isInsidePartido =>
      latitude >= minLatitude &&
      latitude <= maxLatitude &&
      longitude >= minLongitude &&
      longitude <= maxLongitude;

  Map<String, dynamic> toJson() => {
    'label': label,
    'latitude': latitude,
    'longitude': longitude,
    'source': source.name,
  };

  /// Reads a persisted origin, degrading to [fallback] when the stored value
  /// is corrupt or points outside the partido.
  factory UserOrigin.fromJson(Map<String, dynamic> json) {
    final latitude = (json['latitude'] as num?)?.toDouble();
    final longitude = (json['longitude'] as num?)?.toDouble();
    if (latitude == null || longitude == null) return fallback;

    final label = (json['label'] as String? ?? '').trim();
    final origin = UserOrigin(
      label: label.isEmpty ? fallback.label : label,
      latitude: latitude,
      longitude: longitude,
      source: UserOriginSource.values.firstWhere(
        (value) => value.name == json['source'],
        orElse: () => UserOriginSource.map,
      ),
    );

    return origin.isInsidePartido ? origin : fallback;
  }
}
