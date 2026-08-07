import '../models/safe_spot.dart';
import 'api_client.dart';

/// Reads verified safe-place records from the backend. The client does not
/// invent real-world names, coordinates, phone numbers, or opening hours.
class SafeSpotService {
  final ApiClient _api;
  SafeSpotService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<SafeSpot>> findSafeSpots({
    required double lat,
    required double lng,
    required String locationLabel,
    int radiusKm = 50,
    int maxResults = 5,
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
