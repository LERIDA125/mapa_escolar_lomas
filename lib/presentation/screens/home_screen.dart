import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/school_models.dart';
import '../../providers/location_providers.dart';
import '../../providers/school_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/estimated_travel_times_row.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _lomasCenter = LatLng(-34.7616, -58.4027);
  static const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  final _mapController = MapController();
  String? _selectedSchoolId;
  bool _isSchoolDetailsOpen = false;
  bool _showMap = true;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schoolsAsync = ref.watch(filteredSchoolsProvider);
    final originLocation = ref.watch(originLocationProvider);
    final safeZoneRadiusKm = ref.watch(safeZoneRadiusProvider);
    final schools = schoolsAsync.value ?? const <School>[];
    final catalogSchools = ref.watch(schoolsProvider).value ?? const <School>[];

    // Capa defensiva: nunca dibujamos pines en el par de coordenadas default.
    // Protege la UI si en el futuro entra un registro sin geocodificar.
    final validSchools = _validSchools(schools);
    final selectedSchools = _selectedSchoolId == null
        ? const <School>[]
        : _validSchools(
            catalogSchools
                .where((school) => school.id == _selectedSchoolId)
                .toList(),
          );
    final schoolsForMap = [
      ...validSchools,
      ...selectedSchools.where(
        (selected) => !validSchools.any((school) => school.id == selected.id),
      ),
    ];

    final showEmptyState =
        !schoolsAsync.isLoading &&
        !schoolsAsync.hasError &&
        schoolsForMap.isEmpty;

    ref.listen<AsyncValue<List<School>>>(filteredSchoolsProvider, (
      previous,
      next,
    ) {
      if (!mounted || !_showMap || !next.hasValue) return;
      _fitCameraTo(_validSchools(next.requireValue));
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_showMap)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _lomasCenter,
                initialZoom: 13.5,
                minZoom: 3,
                maxZoom: 19,
                backgroundColor: AppColors.surfaceContainer,
                onTap: _handleMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: _osmTileUrl,
                  userAgentPackageName: 'com.example.mapa_escolar',
                  maxNativeZoom: 19,
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: originLocation,
                      radius: safeZoneRadiusKm * 1000,
                      useRadiusInMeter: true,
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderStrokeWidth: 2,
                      borderColor: Colors.blue,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: _buildMarkers(
                    context,
                    schoolsForMap,
                    originLocation,
                  ),
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            )
          else
            _buildSchoolList(validSchools, originLocation),
          if (schoolsAsync.isLoading) const _LoadingOverlay(),
          if (schoolsAsync.hasError)
            _ErrorOverlay(
              error: schoolsAsync.error!,
              onRetry: () => ref.invalidate(schoolsProvider),
            ),
          if (showEmptyState) const _EmptyStateOverlay(),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SearchBar(onSelected: _selectSchoolFromList),
                    const SizedBox(height: 8),
                    const _LevelFilterChips(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: FloatingActionButton.extended(
                onPressed: () => setState(() => _showMap = !_showMap),
                icon: Icon(_showMap ? Icons.list_rounded : Icons.map_rounded),
                label: Text(_showMap ? 'Ver Lista' : 'Ver Mapa'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolList(List<School> schools, LatLng originLocation) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 104, 16, 96),
      itemCount: schools.length,
      itemBuilder: (context, index) {
        final school = schools[index];
        final distanceKm = calculateDistanceKm(
          origin: originLocation,
          destination: LatLng(school.latitude, school.longitude),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: AppColors.surface,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(school.name),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [
                  if (school.level.isNotEmpty) school.level,
                  if (school.address.isNotEmpty) school.address,
                ].join('\n'),
              ),
            ),
            trailing: Text(
              '${distanceKm.toStringAsFixed(1)} km',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () => _selectSchoolFromList(school),
          ),
        );
      },
    );
  }

  void _selectSchoolFromList(School school) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _showMap = true;
      _selectedSchoolId = school.id;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final point = LatLng(school.latitude, school.longitude);
      _mapController.move(point, 16);
      _showSchoolDetails(context, school, ref.read(originLocationProvider));
    });
  }

  List<School> _validSchools(List<School> schools) {
    return schools
        .where((s) => s.latitude != -34.7628 || s.longitude != -58.4022)
        .toList();
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    if (_selectedSchoolId == null) return;

    setState(() => _selectedSchoolId = null);
    if (_isSchoolDetailsOpen) {
      Navigator.of(context).pop();
    }
  }

  void _fitCameraTo(List<School> schools) {
    if (schools.isEmpty) return;

    final points = schools
        .map((s) => LatLng(s.latitude, s.longitude))
        .toList(growable: false);

    final distinctPoints = points.toSet();
    if (distinctPoints.length == 1) {
      _mapController.move(distinctPoints.first, 16);
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(50),
        maxZoom: 17,
      ),
    );
  }

  String _getSchoolShortName(String name) {
    final normalized = name.toLowerCase();
    final abbreviation = switch (true) {
      _ when normalized.contains('cens') => 'CENS',
      _ when normalized.contains('jardin') || normalized.contains('jardín') =>
        'JI',
      _ when normalized.contains('primaria') => 'PP',
      _ when normalized.contains('secundaria') => 'ES',
      _
          when normalized.contains('técnica') ||
              normalized.contains('tecnica') ||
              normalized.contains('tã©cnica') =>
        'MT',
      _ when normalized.contains('adulto') => 'EEPA',
      _ => '',
    };
    final number = RegExp(r'\b\d+\b').firstMatch(name)?.group(0);

    return [abbreviation, ?number].join(' ');
  }

  List<Marker> _buildMarkers(
    BuildContext context,
    List<School> schools,
    LatLng originLocation,
  ) {
    return schools
        .map((school) => _buildMarker(context, school, originLocation))
        .toList();
  }

  Marker _buildMarker(
    BuildContext context,
    School school,
    LatLng originLocation,
  ) {
    final isSelected = school.id == _selectedSchoolId;
    return Marker(
      point: LatLng(school.latitude, school.longitude),
      width: 80,
      height: 68,
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => _selectedSchoolId = school.id);
          _showSchoolDetails(context, school, originLocation);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getSchoolShortName('${school.level} ${school.name}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.black87,
                  fontSize: isSelected ? 11 : 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.location_on_rounded,
              color: isSelected ? AppColors.primary : AppColors.mapMarker,
              size: isSelected ? 48 : 40,
              shadows: const [
                Shadow(
                  color: Color(0x66000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSchoolDetails(
    BuildContext context,
    School school,
    LatLng originLocation,
  ) async {
    final textTheme = Theme.of(context).textTheme;
    final hasLocation =
        school.address.isNotEmpty || school.locality.name.isNotEmpty;
    final hasPhone = school.phone.trim().isNotEmpty;
    final distanceKm = calculateDistanceKm(
      origin: originLocation,
      destination: LatLng(school.latitude, school.longitude),
    );
    final estimatedTimes = calculateEstimatedTimes(distanceKm);

    _isSchoolDetailsOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) {
          return SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 8),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          school.name,
                          style: textTheme.titleLarge?.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Consumer(
                        builder: (context, ref, _) {
                          final isFavorite = ref
                              .watch(favoritesProvider)
                              .contains(school.id);
                          return IconButton(
                            tooltip: isFavorite
                                ? 'Quitar de favoritos'
                                : 'Agregar a favoritos',
                            onPressed: () => ref
                                .read(favoritesProvider.notifier)
                                .toggle(school.id),
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFavorite
                                  ? AppColors.error
                                  : AppColors.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  if (school.level.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Chip(
                      label: Text(school.level),
                      labelStyle: textTheme.labelMedium?.copyWith(
                        color: AppColors.onPrimaryFixedVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: AppColors.primaryFixed,
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ],
                  if (hasLocation) ...[
                    const SizedBox(height: 20),
                    _SchoolDetailRow(
                      icon: Icons.location_on_rounded,
                      title: school.address.isNotEmpty
                          ? school.address
                          : school.locality.name,
                      subtitle: school.address.isNotEmpty
                          ? school.locality.name
                          : null,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _SchoolDetailRow(
                    icon: Icons.directions_car_rounded,
                    title:
                        '🚗 A ${distanceKm.toStringAsFixed(1)} km de tu ubicación',
                  ),
                  const SizedBox(height: 12),
                  EstimatedTravelTimesRow(times: estimatedTimes),
                  const SizedBox(height: 12),
                  const _SchoolDetailRow(
                    icon: Icons.directions_bus_rounded,
                    title: '🚌 Líneas: 540, 277, 164',
                  ),
                  if (hasPhone) ...[
                    const SizedBox(height: 16),
                    _SchoolDetailRow(
                      icon: Icons.phone_rounded,
                      title: school.phone.trim(),
                      trailing: IconButton(
                        tooltip: 'Llamar a la escuela',
                        onPressed: () => _callSchool(school),
                        icon: const Icon(Icons.call_rounded),
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: FilledButton.icon(
                          onPressed: () {
                            debugPrint('Cómo llegar: ${school.name}');
                          },
                          icon: const Icon(Icons.directions_bus_rounded),
                          label: const Text('Cómo llegar'),
                        ),
                      ),
                      Flexible(
                        child: Consumer(
                          builder: (context, ref, _) {
                            final isInComparison = ref
                                .watch(comparatorProvider)
                                .contains(school.id);
                            return OutlinedButton.icon(
                              onPressed: () => _toggleComparison(school),
                              icon: Icon(
                                isInComparison
                                    ? Icons.remove_circle_outline_rounded
                                    : Icons.compare_arrows_rounded,
                              ),
                              label: Text(
                                isInComparison ? 'Quitar' : 'Comparar',
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      _isSchoolDetailsOpen = false;
      if (mounted && _selectedSchoolId == school.id) {
        setState(() => _selectedSchoolId = null);
      }
    }
  }

  Future<void> _callSchool(School school) async {
    try {
      final launched = await launchUrl(Uri.parse('tel:${school.phone.trim()}'));
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar la llamada.')),
        );
      }
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar la llamada.')),
        );
      }
    }
  }

  void _toggleComparison(School school) {
    final wasSelected = ref.read(comparatorProvider).contains(school.id);
    final wasAdded = ref.read(comparatorProvider.notifier).toggle(school.id);
    final message = wasSelected
        ? '${school.name} se quitó de la comparativa.'
        : wasAdded
        ? '${school.name} se agregó a la comparativa.'
        : 'La comparativa admite hasta 4 escuelas.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SchoolDetailRow extends StatelessWidget {
  const _SchoolDetailRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = this.subtitle;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _SearchBar extends ConsumerWidget {
  const _SearchBar({required this.onSelected});

  final ValueChanged<School> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schools = ref.watch(schoolsProvider).value ?? const <School>[];

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
        child: Autocomplete<School>(
          displayStringForOption: (school) => school.name,
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.trim().toLowerCase();
            if (query.isEmpty) return const Iterable<School>.empty();

            return schools
                .where((school) {
                  return school.name.toLowerCase().contains(query) ||
                      (school.codigoOficial?.toLowerCase().contains(query) ??
                          false);
                })
                .take(8);
          },
          onSelected: (school) {
            ref.read(searchQueryProvider.notifier).state = school.name;
            onSelected(school);
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 320,
                    maxWidth: 480,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final school = options.elementAt(index);
                      return ListTile(
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                        ),
                        title: Text(school.name),
                        subtitle: Text(
                          [
                            if (school.level.isNotEmpty) school.level,
                            if (school.address.isNotEmpty) school.address,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => onSelected(school),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
                return Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 22,
                      color: AppColors.neutral,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: textController,
                        focusNode: focusNode,
                        textInputAction: TextInputAction.search,
                        onChanged: (value) {
                          ref.read(searchQueryProvider.notifier).state = value;
                        },
                        onSubmitted: (_) => onFieldSubmitted(),
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
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.onPrimaryFixedVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ],
                );
              },
        ),
      ),
    );
  }
}

class _LevelFilterChips extends ConsumerWidget {
  const _LevelFilterChips();

  static const _levels = [
    'Todas',
    'Jardín',
    'Primaria',
    'Secundaria',
    'Técnica',
    'Especial',
    'Adultos',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLevel = ref.watch(levelFilterProvider);

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final level in _levels) ...[
                  if (level != _levels.first) const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(level),
                    selected: selectedLevel == level,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    labelStyle: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(
                          color: selectedLevel == level
                              ? Colors.white
                              : AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: selectedLevel == level
                          ? AppColors.primary
                          : AppColors.outlineVariant,
                    ),
                    onSelected: (_) {
                      ref.read(levelFilterProvider.notifier).state = level;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        const _BusLineFilter(),
      ],
    );
  }
}

class _BusLineFilter extends ConsumerWidget {
  const _BusLineFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLine = ref.watch(busLineFilterProvider);
    final availableLines = ref.watch(availableBusLinesProvider);

    return Container(
      height: 40,
      width: 140,
      padding: const EdgeInsets.only(left: 10, right: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.directions_bus_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: availableLines.when(
              data: (lines) => DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: lines.contains(selectedLine) ? selectedLine : 'Todas',
                  isExpanded: true,
                  isDense: true,
                  borderRadius: BorderRadius.circular(12),
                  dropdownColor: AppColors.surface,
                  icon: const Icon(Icons.arrow_drop_down_rounded),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  items: [
                    for (final line in lines)
                      DropdownMenuItem(
                        value: line,
                        child: Text(line, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (line) {
                    if (line != null) {
                      ref.read(busLineFilterProvider.notifier).state = line;
                    }
                  },
                ),
              ),
              loading: () => Text(
                'Colectivo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              error: (error, stackTrace) => Tooltip(
                message: 'No se pudieron cargar las líneas: $error',
                child: Text(
                  'Sin líneas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateOverlay extends StatelessWidget {
  const _EmptyStateOverlay();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outlineVariant),
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
                  Icons.search_off_rounded,
                  size: 40,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'No se encontraron escuelas',
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Probá con otro número o nombre.',
                  textAlign: TextAlign.center,
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
