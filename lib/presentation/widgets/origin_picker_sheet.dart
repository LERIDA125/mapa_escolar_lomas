import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/models/street_index.dart';
import '../../domain/models/user_origin.dart';
import '../../providers/street_index_providers.dart';
import '../../providers/user_origin_providers.dart';
import '../theme/app_theme.dart';

/// Bottom sheet that lets the applicant move their point of departure.
///
/// Offline on purpose: the address field autocompletes against the streets
/// already present in the school catalog, then the applicant refines the exact
/// spot by panning the map under a fixed pin. No geocoding service involved.
class OriginPickerSheet extends ConsumerStatefulWidget {
  const OriginPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const OriginPickerSheet(),
    );
  }

  @override
  ConsumerState<OriginPickerSheet> createState() => _OriginPickerSheetState();
}

class _OriginPickerSheetState extends ConsumerState<OriginPickerSheet> {
  static const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _maxSuggestions = 5;

  final _mapController = MapController();
  final _addressController = TextEditingController();
  final _addressFocus = FocusNode();

  late LatLng _initialCenter;
  List<StreetIndexEntry> _suggestions = const [];
  StreetIndexEntry? _selectedStreet;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final origin = ref.read(userOriginProvider);
    _initialCenter = origin.latLng;
    _addressController.text = origin.isFallback ? '' : origin.label;
  }

  @override
  void dispose() {
    _mapController.dispose();
    _addressController.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  void _onAddressChanged(String value, List<StreetIndexEntry> streets) {
    final tokens = _tokenize(value);
    setState(() {
      _selectedStreet = null;
      if (tokens.isEmpty) {
        _suggestions = const [];
        return;
      }

      // Token matching instead of a raw substring: the index stores
      // abbreviated names ("H. YRIGOYEN", "ALTE. BROWN"), so requiring the
      // whole query to appear would miss "Hipólito Yrigoyen" or "Av. Yrigoyen".
      // Matching any token still surfaces the street and keeps "Campana 534"
      // working when the applicant types the full address.
      final matches =
          streets
              .where((street) => _matchScore(street, tokens) > 0)
              .toList(growable: false)
            ..sort((a, b) {
              final byScore = _matchScore(
                b,
                tokens,
              ).compareTo(_matchScore(a, tokens));
              return byScore != 0 ? byScore : a.name.compareTo(b.name);
            });

      _suggestions = matches.take(_maxSuggestions).toList(growable: false);
    });
  }

  void _selectStreet(StreetIndexEntry street) {
    _selectedStreet = street;
    _addressController.text = street.name;
    _addressController.selection = TextSelection.collapsed(
      offset: street.name.length,
    );
    _addressFocus.unfocus();
    setState(() => _suggestions = const []);

    if (street.isSinglePoint) {
      _mapController.move(street.center, 16);
    } else {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(
            LatLng(street.south, street.west),
            LatLng(street.north, street.east),
          ),
          padding: const EdgeInsets.all(48),
          maxZoom: 16,
        ),
      );
    }
  }

  Future<void> _confirm() async {
    final center = _mapController.camera.center;
    final typedLabel = _addressController.text.trim();
    final origin = UserOrigin(
      label: typedLabel.isEmpty ? 'Punto elegido en el mapa' : typedLabel,
      latitude: center.latitude,
      longitude: center.longitude,
      source: _selectedStreet != null
          ? UserOriginSource.address
          : UserOriginSource.map,
    );

    if (!origin.isInsidePartido) {
      _showMessage('Ese punto queda fuera del partido de Lomas de Zamora.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(userOriginProvider.notifier).setOrigin(origin);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('No se pudo guardar el punto de partida.');
    }
  }

  Future<void> _reset() async {
    await ref.read(userOriginProvider.notifier).reset();
    if (!mounted) return;
    _mapController.move(UserOrigin.fallback.latLng, 14);
    _addressController.clear();
    setState(() {
      _selectedStreet = null;
      _suggestions = const [];
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final streets =
        ref.watch(streetIndexProvider).value ?? const <StreetIndexEntry>[];

    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    // Keeping the content above the keyboard without letting the sheet grow
    // past 85% of the screen.
    final sheetHeight = (screenHeight * 0.85 - keyboard).clamp(
      260.0,
      screenHeight * 0.85,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Punto de partida',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Restablecer'),
                  ),
                ],
              ),
              Text(
                'Buscá tu calle y arrastrá el mapa hasta tu puerta.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                focusNode: _addressFocus,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Domicilio',
                  hintText: 'Ej. Campana',
                  prefixIcon: Icon(Icons.search_rounded),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _onAddressChanged(value, streets),
              ),
              if (_suggestions.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 168),
                  child: Card(
                    margin: const EdgeInsets.only(top: 4),
                    color: AppColors.surface,
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final street = _suggestions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.signpost_outlined,
                            size: 18,
                          ),
                          title: Text(street.name),
                          onTap: () => _selectStreet(street),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _initialCenter,
                          initialZoom: 15,
                          minZoom: 11,
                          maxZoom: 19,
                          backgroundColor: AppColors.surfaceContainer,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: _osmTileUrl,
                            userAgentPackageName: 'com.example.mapa_escolar',
                            maxNativeZoom: 19,
                          ),
                          const RichAttributionWidget(
                            attributions: [
                              TextSourceAttribution(
                                'OpenStreetMap contributors',
                              ),
                            ],
                          ),
                        ],
                      ),
                      IgnorePointer(
                        child: Center(
                          child: Transform.translate(
                            offset: const Offset(0, -24),
                            child: Icon(
                              Icons.location_pin,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving ? null : _confirm,
                icon: const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Guardando…' : 'Usar esta ubicación'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lowercase, accent-free, punctuation-free query so it can be matched against
/// the pre-normalized `search` field of the offline index.
String _normalize(String value) {
  const replacements = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };

  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    final character = String.fromCharCode(rune);
    buffer.write(replacements[character] ?? character);
  }

  return buffer
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

List<String> _tokenize(String value) {
  final normalized = _normalize(value);
  if (normalized.isEmpty) return const [];
  // Dropping short tokens keeps "Av. Yrigoyen" and "14 de julio" from matching
  // on "av" or "de" and flooding the suggestions with unrelated streets.
  return normalized
      .split(' ')
      .where((token) => token.length >= 3)
      .toList(growable: false);
}

int _matchScore(StreetIndexEntry street, List<String> tokens) {
  final words = street.search.split(' ');
  var score = 0;
  for (final token in tokens) {
    if (words.contains(token)) {
      // Whole-word matches outrank accidental prefixes: "san" should surface
      // "SAN BLAS" before "F. SANCHEZ".
      score += 2;
    } else if (street.search.contains(token)) {
      score += 1;
    }
  }
  return score;
}
