import 'dart:math' as math;
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import '../models/safe_spot.dart';
import '../models/safety_grid_entry.dart';
import '../repositories/safety_repository.dart';
import 'api_client.dart';
import 'database_service.dart';

/// Reads verified safe-place records from the backend. The client does not
/// invent real-world names, coordinates, phone numbers, or opening hours.
///
/// Resolution order when the backend is unreachable:
///   1. Safe spots downloaded for an offline region — real, verified places.
///   2. The bundled safety grid — real areas with real coordinates, but areas,
///      not places you can walk into. A weaker answer, so it comes second.
class SafeSpotService {
  final ApiClient _api;
  final SafetyRepository? _safetyRepo;
  final AppDatabase? _db;

  SafeSpotService({ApiClient? api, SafetyRepository? safetyRepo, AppDatabase? db})
      : _api = api ?? ApiClient(),
        _safetyRepo = safetyRepo,
        _db = db;

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
      if (rows.isEmpty) return _offlineSafeSpots(lat, lng, maxResults);
      return rows.map((row) {
        final json = Map<String, dynamic>.from(row as Map);
        final distanceM = (json['distanceM'] as num?)?.toDouble() ?? 0;
        json['distance_km'] = distanceM / 1000;
        return SafeSpot.fromJson(json, originLat: lat, originLng: lng);
      }).toList();
    } catch (_) {
      return _offlineSafeSpots(lat, lng, maxResults);
    }
  }

  // ── Offline region bundling ─────────────────────────────────────────────────

  /// Downloads every verified safe spot inside [bounds] and stores it locally,
  /// so the area's real safe places stay available with no connection.
  ///
  /// Returns how many were stored. Zero is a legitimate outcome, not an error:
  /// outside the curated coverage there are no verified places to bundle, and
  /// the backend deliberately does not substitute AI-suggested ones.
  Future<int> cacheRegionSafeSpots({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
  }) async {
    final db = _db;
    if (db == null) return 0;

    final payload = await _api.get('/safety/safe-spots/bbox', query: {
      'minLat': minLat,
      'minLng': minLng,
      'maxLat': maxLat,
      'maxLng': maxLng,
      'limit': 1000,
    });

    final data = payload['data'];
    if (data is! Map<String, dynamic>) return 0;
    final rows = data['spots'] as List<dynamic>? ?? [];
    if (rows.isEmpty) return 0;

    final now = DateTime.now();
    final companions = <CachedSafeSpotsCompanion>[];
    for (final raw in rows) {
      final json = Map<String, dynamic>.from(raw as Map);
      final lat = (json['lat'] as num?)?.toDouble();
      final lng = (json['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue; // Never store a placeless spot.

      companions.add(CachedSafeSpotsCompanion.insert(
        id: (json['id'] as String?)?.trim().isNotEmpty == true
            ? json['id'] as String
            : '${lat}_$lng',
        name: (json['name'] as String?) ?? 'Safe spot',
        category: (json['category'] as String?) ?? 'other',
        address: (json['address'] as String?) ?? '',
        lat: lat,
        lng: lng,
        safetyScore: (json['safety_score'] as num?)?.toDouble() ?? 0.8,
        whySafe: (json['why_safe'] as String?) ?? '',
        operatingHours: Value(json['operating_hours'] as String?),
        contactNumber: Value(json['contact_number'] as String?),
        source: (json['source'] as String?) ?? 'curated',
        cachedAt: now,
      ));
    }

    final stored = await db.upsertCachedSafeSpots(companions);
    debugPrint('[SafeSpotService] cached $stored verified safe spots for region');
    return stored;
  }

  /// How many verified safe spots are currently bundled on this device.
  Future<int> cachedSafeSpotCount() async => (await _db?.cachedSafeSpotCount()) ?? 0;

  Future<void> clearCachedSafeSpots() async => _db?.clearCachedSafeSpots();

  /// Offline resolution: downloaded verified spots first, bundled grid second.
  Future<List<SafeSpot>> _offlineSafeSpots(double lat, double lng, int maxResults) async {
    final cached = await _cachedSafeSpots(lat, lng, maxResults);
    if (cached.isNotEmpty) return cached;
    return _localSafeSpots(lat, lng, maxResults);
  }

  /// Nearest downloaded safe spots. Sorted in Dart — the verified dataset is
  /// under 200 rows, so this is cheaper than a spatial index would be.
  Future<List<SafeSpot>> _cachedSafeSpots(double lat, double lng, int maxResults) async {
    final db = _db;
    if (db == null) return const [];
    try {
      final rows = await db.getCachedSafeSpots();
      if (rows.isEmpty) return const [];

      final withDistance = rows
          .map((r) => (row: r, km: _haversineKm(lat, lng, r.lat, r.lng)))
          .toList()
        ..sort((a, b) => a.km.compareTo(b.km));

      return withDistance.take(maxResults).map((e) {
        final r = e.row;
        return SafeSpot(
          id: r.id,
          name: r.name,
          address: r.address,
          lat: r.lat,
          lng: r.lng,
          category: SafeSpotCategoryX.fromString(r.category),
          safetyScore: r.safetyScore,
          distanceKm: e.km,
          whySafe: r.whySafe.isNotEmpty ? r.whySafe : 'Verified safe place, saved for offline use.',
          operatingHours: r.operatingHours,
          contactNumber: r.contactNumber,
        );
      }).toList();
    } catch (e) {
      debugPrint('[SafeSpotService] cached safe spot lookup failed: $e');
      return const [];
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

    final nearby = sorted.where((e) => _haversineKm(lat, lng, e.lat, e.lng) <= 15).toList();
    if (nearby.isEmpty) return const [];

    return nearby.take(maxResults).map((e) {
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
