import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';

/// Size ceiling for the tile cache.
///
/// 250 MB is roughly twelve thousand tiles at the zoom levels this app uses,
/// which covers Lomas de Zamora several times over without competing for space
/// with photos or downloads.
const _maxCacheSizeBytes = 250 * 1024 * 1024;

/// How long a cached tile is served without revalidating against the network.
///
/// OpenStreetMap raster tiles change far less often than a month, and a long
/// window is what makes a browsed area stay readable when the device has no
/// connection.
const _freshAge = Duration(days: 30);

/// Pins the policy of flutter_map's built-in tile cache.
///
/// flutter_map 8.2+ already stores every browsed tile on disk through
/// [BuiltInMapCachingProvider], which is the default of [NetworkTileProvider].
/// Nothing here turns caching on; this only decides *where* and *how much*:
///
/// * a persistent directory, so the cache survives the OS reclaiming
///   temporary storage (the default cache directory can be wiped at any
///   moment, which would silently break the offline promise);
/// * a size ceiling, so the cache cannot grow without bound;
/// * a fresh age, so an already-downloaded tile is served without a network
///   round trip.
///
/// Must run before the first tile is requested. Safe on every platform: web
/// has no file cache to configure, and a missing path provider (unit tests,
/// unsupported platform) degrades to flutter_map's default directory instead
/// of crashing the app before the first frame.
Future<void> configureTileCache() async {
  if (kIsWeb) return;

  String? cacheDirectory;
  try {
    cacheDirectory = (await getApplicationSupportDirectory()).path;
  } catch (_) {
    // No path provider available: let flutter_map pick its platform default.
  }

  BuiltInMapCachingProvider.getOrCreateInstance(
    cacheDirectory: cacheDirectory,
    maxCacheSize: _maxCacheSizeBytes,
    overrideFreshAge: _freshAge,
  );
}
