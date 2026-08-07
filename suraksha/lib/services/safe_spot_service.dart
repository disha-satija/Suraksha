import 'dart:math' as math;
import '../models/safe_spot.dart';
import '../models/safety_grid_entry.dart';
import '../repositories/safety_repository.dart';
import 'api_client.dart';

/// Reads verified safe-place records from the backend. The client does not
/// invent real-world names, coordinates, phone numbers, or opening hours.
/// When the backend is unreachable, falls back to the bundled safety grid —
/// real areas with real coordinates, not fabricated listings.
class SafeSpotService {
  final ApiClient _api;
  final SafetyRepository? _safetyRepo;
  SafeSpotService({ApiClient? api, SafetyRepository? safetyRepo})
      : _api = api ?? ApiClient(),
        _safetyRepo = safetyRepo;

  Future<List<SafeSpot>> findSafeSpots({
    required double lat,
    required double lng,
    required String locationLabel,
    int radiusKm = 50,
    int maxResults = 5,
  }) async {
    try {
      final payload = await _api.get('/safety/safe-spots', query: {
        'lat': lat,
        'lng': lng,
        'radiusM': radiusKm * 1000,
        'limit': maxResults,
      });
      final rows = payload['data'] as List<dynamic>? ?? [];
      if (rows.isEmpty) return _localSafeSpots(lat, lng, maxResults);
      return rows.map((row) {
        final json = Map<String, dynamic>.from(row as Map);
        final distanceM = (json['distanceM'] as num?)?.toDouble() ?? 0;
        json['distance_km'] = distanceM / 1000;
        return SafeSpot.fromJson(json, originLat: lat, originLng: lng);
      }).toList();
    } catch (_) {
      return _localSafeSpots(lat, lng, maxResults);
    }
  }

  /// Offline fallback — derives safe spots from the bundled safety grid so the
  /// app stays useful with no backend. These are real areas, not invented places.
  List<SafeSpot> _localSafeSpots(double lat, double lng, int maxResults) {
    final grid = _safetyRepo?.grid ?? const <SafetyGridEntry>[];
    if (grid.isEmpty) return const [];

    final sorted = [...grid]..sort((a, b) {
        final da = _haversineKm(lat, lng, a.lat, a.lng);
        final db = _haversineKm(lat, lng, b.lat, b.lng);
        return da.compareTo(db);
      });

    return sorted.take(maxResults).map((e) {
      final distKm = _haversineKm(lat, lng, e.lat, e.lng);
      return SafeSpot(
        id: 'grid_${e.city}_${e.area}'.toLowerCase().replaceAll(' ', '_'),
        name: e.area,
        address: '${e.area}, ${e.city}',
        lat: e.lat,
        lng: e.lng,
        category: SafeSpotCategory.publicSpace,
        safetyScore: e.avgSafetyScore,
        distanceKm: distKm,
        whySafe: e.riskLevel == 'Low'
            ? 'Community data rates this area as low risk.'
            : 'Community safety data is available for this area.',
      );
    }).toList();
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.pow(math.sin(dLon / 2), 2);
    return r * 2 * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
  }

  /// Returns the single closest safe spot from SafeSpots_Delhi.
  Future<SafeSpot?> getTopSafeSpot({
    required double lat,
    required double lng,
    int radiusKm = 50,
  }) async {
    final payload = await _api.get('/safety/top-safe-spot', query: {
      'lat': lat,
      'lng': lng,
      'radiusM': radiusKm * 1000,
    });
    final data = payload['data'] as Map<String, dynamic>?;
    if (data == null) return null;
    return SafeSpot.fromJson(data, originLat: lat, originLng: lng);
  }
}
