import 'package:flutter/material.dart';

import '../../providers/location_providers.dart';
import '../theme/app_theme.dart';

class EstimatedTravelTimesRow extends StatelessWidget {
  const EstimatedTravelTimesRow({super.key, required this.times});

  final EstimatedTravelTimes times;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiempos estimados',
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _TravelTime(
                icon: Icons.directions_walk_rounded,
                label: 'A pie',
                minutes: times.walkingMinutes,
              ),
              _TravelTime(
                icon: Icons.directions_car_rounded,
                label: 'Auto',
                minutes: times.drivingMinutes,
              ),
              _TravelTime(
                icon: Icons.directions_bus_rounded,
                label: 'Colectivo',
                minutes: times.transitMinutes,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TravelTime extends StatelessWidget {
  const _TravelTime({
    required this.icon,
    required this.label,
    required this.minutes,
  });

  final IconData icon;
  final String label;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            '$minutes min',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
