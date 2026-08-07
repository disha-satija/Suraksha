import '../models/safe_spot.dart';
import 'api_client.dart';

/// Reads verified safe-place records from the backend. The client does not
/// invent real-world names, coordinates, phone numbers, or opening hours.
class SafeSpotService {
  final ApiClient _api;
  SafeSpotService({ApiClient? api}) : _api = api ?? ApiClient();

  // ── Legacy: general safe-spots (OSM / Groq fallback) ──────────────────────

  Future<List<SafeSpot>> findSafeSpots({
    required double lat,
    required double lng,
    required String locationLabel,
    int radiusKm = 5,
    int maxResults = 8,
  }) async {
    final payload = await _api.get('/safety/safe-spots', query: {
      'lat': lat,
      'lng': lng,
      'radiusM': radiusKm * 1000,
      'limit': maxResults,
    });
    final rows = payload['data'] as List<dynamic>? ?? [];
    return rows.map((row) {
      final json = Map<String, dynamic>.from(row as Map);
      final distanceM = (json['distanceM'] as num?)?.toDouble() ?? 0;
      json['distance_km'] = distanceM / 1000;
      return SafeSpot.fromJson(json, originLat: lat, originLng: lng);
    }).toList();
  }

  // ── Delhi dataset: 5 nearest safe spots ───────────────────────────────────

  /// Returns up to 5 safe spots nearest to [lat]/[lng] from the curated
  /// SafeSpots_Delhi table (143 verified Delhi locations), ordered by
  /// straight-line distance ascending.
  ///
  /// [radiusKm] sets the outer search boundary (default 50 km).
  Future<List<SafeSpot>> findNearestSafeSpots({
    required double lat,
    required double lng,
    int radiusKm = 50,
  }) async {
    final payload = await _api.get('/safety/nearest-safe-spots', query: {
      'lat': lat,
      'lng': lng,
      'radiusM': radiusKm * 1000,
    });
    final rows = payload['data'] as List<dynamic>? ?? [];
    return rows.map((row) => _mapDelhiRow(row as Map, lat, lng)).toList();
  }

  // ── Delhi dataset: single closest safe spot ────────────────────────────────

  /// Returns the single closest safe spot to [lat]/[lng] from the curated
  /// SafeSpots_Delhi table, or `null` if none found within [radiusKm].
  ///
  /// Useful for SOS flows — "take me somewhere safe, right now."
  Future<SafeSpot?> findTopSafeSpot({
    required double lat,
    required double lng,
    int radiusKm = 50,
  }) async {
    final payload = await _api.get('/safety/top-safe-spot', query: {
      'lat': lat,
      'lng': lng,
      'radiusM': radiusKm * 1000,
    });
    final data = payload['data'];
    if (data == null) return null;
    return _mapDelhiRow(data as Map, lat, lng);
  }

  // ── Private: map Delhi API row → SafeSpot ─────────────────────────────────

  SafeSpot _mapDelhiRow(Map row, double originLat, double originLng) {
    final json = Map<String, dynamic>.from(row);
    // Backend returns distanceM; SafeSpot.fromJson expects distance_km
    final distanceM = (json['distanceM'] as num?)?.toDouble() ?? 0.0;
    json['distance_km'] = distanceM / 1000.0;
    // Backend field is `category` (mapped from `type` in SafeSpots_Delhi)
    // SafeSpot.fromJson already reads `category`, so no rename needed.
    return SafeSpot.fromJson(json, originLat: originLat, originLng: originLng);
  }
}
