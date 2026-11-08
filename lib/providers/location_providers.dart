import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:latlong2/latlong.dart';

/// Simulated user location at Plaza Grigera, Lomas de Zamora.
final originLocationProvider = Provider<LatLng>(
  (ref) => const LatLng(-34.7618, -58.4022),
);

/// Whether schools outside the selected safe-zone radius are hidden.
final safeZoneEnabledProvider = StateProvider<bool>((ref) => true);

/// Maximum safe-zone radius in blocks. One block is assumed to be 100 meters.
final safeZoneRadiusProvider = StateProvider<int>((ref) => 30);

/// Estimated travel durations in whole minutes for each travel mode.
class EstimatedTravelTimes {
  const EstimatedTravelTimes({
    required this.walkingMinutes,
    required this.drivingMinutes,
    required this.transitMinutes,
  });

  final int walkingMinutes;
  final int drivingMinutes;
  final int transitMinutes;
}

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

/// Estimates trip duration using typical urban speeds, not live routing data.
EstimatedTravelTimes calculateEstimatedTimes(double distanceKm) {
  if (!distanceKm.isFinite || distanceKm < 0) {
    throw ArgumentError.value(
      distanceKm,
      'distanceKm',
      'Must be a finite, non-negative distance.',
    );
  }

  int minutesAt(double speedKmPerHour) {
    if (distanceKm == 0) return 0;
    return (distanceKm / speedKmPerHour * 60).ceil();
  }

  return EstimatedTravelTimes(
    walkingMinutes: minutesAt(5),
    drivingMinutes: minutesAt(30),
    transitMinutes: minutesAt(15),
  );
}

double _degreesToRadians(double degrees) => degrees * math.pi / 180;
