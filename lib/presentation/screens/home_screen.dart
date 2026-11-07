import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/models/school_models.dart';
import '../../providers/school_providers.dart';
import '../theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  static const _lomasCenter = LatLng(-34.7616, -58.4027);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolsAsync = ref.watch(schoolsProvider);
    final schools = schoolsAsync.value ?? const <School>[];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _lomasCenter,
                zoom: 13.5,
              ),
              markers: _buildMarkers(schools),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              padding: const EdgeInsets.only(top: 140, bottom: 24),
            ),
            const SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _SearchBar(),
                ),
              ),
            ),
            if (schoolsAsync.isLoading) const _LoadingOverlay(),
            if (schoolsAsync.hasError)
              _ErrorOverlay(
                error: schoolsAsync.error!,
                onRetry: () => ref.invalidate(schoolsProvider),
              ),
          ],
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers(List<School> schools) {
    return {
      for (final school in schools)
        Marker(
          markerId: MarkerId(school.id),
          position: LatLng(school.latitude, school.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: school.name,
            snippet: '${school.level} · ${school.address}',
          ),
        ),
    };
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE0E2E6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x263C4043),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x1A3C4043),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              size: 22,
              color: AppColors.neutral,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                textInputAction: TextInputAction.search,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.onSurface),
                decoration: const InputDecoration(
                  hintText: 'Buscar por número o nombre (ej. EP 12)',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Buscar por voz',
              onPressed: () {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text(
                        'La búsqueda por voz estará disponible próximamente.',
                      ),
                    ),
                  );
              },
              icon: const Icon(
                Icons.mic_none_rounded,
                size: 20,
                color: AppColors.neutral,
              ),
            ),
            Container(
              width: 1,
              height: 20,
              color: AppColors.outlineVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Aspirante',
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'AP',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onPrimaryFixedVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.08),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x263C4043),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Text('Cargando escuelas...', style: textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'Leyendo la base local',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.12),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x263C4043),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: AppColors.error,
                ),
                const SizedBox(height: 8),
                Text(
                  'No pudimos cargar las escuelas',
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  error.toString(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
