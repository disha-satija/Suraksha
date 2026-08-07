import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import 'constants/app_constants.dart';

/// Single source of truth for the map tile provider.
///
/// The offline cache is best-effort: if the FMTC backend failed to start,
/// [isOfflineCacheReady] stays false and every map falls back to plain network
/// tiles rather than rendering blank. The provider is built once and reused —
/// constructing an [FMTCTileProvider] inside `build` strands an HttpClient per
/// rebuild and invalidates the tile image cache.
class MapTileProvider {
  MapTileProvider._();

  static bool _offlineCacheReady = false;
  static TileProvider? _cached;

  static bool get isOfflineCacheReady => _offlineCacheReady;

  /// Called once at startup, after the FMTC backend init attempt.
  static void markOfflineCacheReady({required bool ready}) {
    _offlineCacheReady = ready;
    _cached = null;
  }

  /// The shared tile provider for every map in the app.
  static TileProvider get instance => _cached ??= _offlineCacheReady
      ? FMTCTileProvider(
          stores: const {
            AppConstants.offlineTileStoreName:
                BrowseStoreStrategy.readUpdateCreate,
          },
          loadingStrategy: BrowseLoadingStrategy.cacheFirst,
        )
      : NetworkTileProvider();
}
