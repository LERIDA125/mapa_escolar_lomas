import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Simulated user location at Plaza Grigera, Lomas de Zamora.
final originLocationProvider = Provider<LatLng>(
  (ref) => const LatLng(-34.7618, -58.4022),
);

/// Calculates the great-circle distance between two points in kilometers.
double calculateDistanceKm({
  required LatLng origin,
  required LatLng destination,
}) {
  const earthRadiusKm = 6371.0;
  final latitudeDifference = _degreesToRadians(
    destination.latitude - origin.latitude,
  );
  final longitudeDifference = _degreesToRadians(
    destination.longitude - origin.longitude,
  );
  final originLatitude = _degreesToRadians(origin.latitude);
  final destinationLatitude = _degreesToRadians(destination.latitude);

  final haversine =
      math.pow(math.sin(latitudeDifference / 2), 2) +
      math.cos(originLatitude) *
          math.cos(destinationLatitude) *
          math.pow(math.sin(longitudeDifference / 2), 2);
  final boundedHaversine = haversine.clamp(0.0, 1.0);
  final centralAngle =
      2 *
      math.atan2(math.sqrt(boundedHaversine), math.sqrt(1 - boundedHaversine));

  return earthRadiusKm * centralAngle;
}

double _degreesToRadians(double degrees) => degrees * math.pi / 180;
