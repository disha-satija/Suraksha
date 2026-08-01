import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../models/safety_grid_entry.dart';
import '../core/constants/app_constants.dart';
/// Handles route fetching from OSRM (online) and pre-cached routes (offline).
class RoutingService {
  List<DemoRoute>? _cachedDemoRoutes;

  Future<void> initialize() async {
    final jsonStr =
        await rootBundle.loadString(AppConstants.demoRoutesPath);
    final data = jsonDecode(jsonStr) as List<dynamic>;
    _cachedDemoRoutes =
        data.map((e) => _parseDemoRoute(e as Map<String, dynamic>)).toList();
  }

  /// Fetch routes from OSRM (requires internet).
  Future<List<RouteModel>> fetchOnlineRoutes({
    required LatLng start,
    required LatLng end,
    required List<SafetyGridEntry> grid,
  }) async {
    final url =
        '${AppConstants.osrmBaseUrl}/${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?alternatives=true&geometries=geojson&overview=full';

    final response =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('OSRM returned ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = json['routes'] as List<dynamic>;

    return routes.asMap().entries.map((entry) {
      final idx = entry.key;
      final r = entry.value as Map<String, dynamic>;
      final coords = (r['geometry']['coordinates'] as List<dynamic>)
          .map((c) => LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();
      final safetyScore = _avgSafetyAlongRoute(coords, grid);
      final explanation = _buildExplanation(coords, grid, safetyScore);
      return RouteModel(
        id: 'route_$idx',
        polyline: coords,
        distanceMeters: (r['distance'] as num).toDouble(),
        durationSeconds: (r['duration'] as num).toDouble(),
        safetyScore: safetyScore,
        riskLevel: _scoreToRisk(safetyScore),
        isCached: false,
        explanation: explanation,
      );
    }).toList();
  }

  /// Returns pre-cached demo routes (works fully offline).
  List<DemoRoute> get cachedDemoRoutes => _cachedDemoRoutes ?? [];

  /// Find the closest matching cached route to given start/end.
  DemoRoute? findNearestCachedRoute(LatLng start, LatLng end) {
    if (_cachedDemoRoutes == null || _cachedDemoRoutes!.isEmpty) return null;
    const distance = Distance();
    return _cachedDemoRoutes!.reduce((a, b) {
      final da = distance(start, a.start) + distance(end, a.end);
      final db = distance(start, b.start) + distance(end, b.end);
      return da < db ? a : b;
    });
  }

  // ── Route deviation detection ────────────────────────────────────────────

  /// Returns true if current position deviates more than [thresholdMeters]
  /// from the planned route polyline.
  bool hasDeviated(
    LatLng currentPosition,
    List<LatLng> plannedPolyline, {
    double thresholdMeters = 150,
  }) {
    if (plannedPolyline.isEmpty) return false;
    const distance = Distance();
    final minDist = plannedPolyline
        .map((p) => distance(currentPosition, p))
        .reduce((a, b) => a < b ? a : b);
    return minDist > thresholdMeters;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  double _avgSafetyAlongRoute(
      List<LatLng> polyline, List<SafetyGridEntry> grid) {
    if (grid.isEmpty) return 0.5;
    const distance = Distance();
    double total = 0;
    int count = 0;
    for (final point in polyline) {
      final nearest = grid.reduce((a, b) {
        final da = distance(point, LatLng(a.lat, a.lng));
        final db = distance(point, LatLng(b.lat, b.lng));
        return da < db ? a : b;
      });
      total += nearest.avgSafetyScore;
      count++;
    }
    return count > 0 ? total / count : 0.5;
  }

  /// Compute full XAI explanation by sampling grid entries along the polyline.
  RouteExplanation _buildExplanation(
      List<LatLng> polyline, List<SafetyGridEntry> grid, double score) {
    if (grid.isEmpty) {
      return RouteExplanation(
        avgLighting: 5,
        avgPoliceDist: 3,
        avgCrowd: 400,
        avgCrimeCount: 20,
        summaryText: 'Safety score: ${(score * 100).toStringAsFixed(0)}/100.',
        tips: ['Stay aware of your surroundings.'],
      );
    }

    const distance = Distance();
    double totalLighting = 0;
    double totalPoliceDist = 0;
    double totalCrowd = 0;
    double totalCrime = 0;
    int count = 0;

    // Sample every Nth point for performance
    final step = (polyline.length / 10).ceil().clamp(1, polyline.length);
    for (int i = 0; i < polyline.length; i += step) {
      final point = polyline[i];
      final nearest = grid.reduce((a, b) {
        final da = distance(point, LatLng(a.lat, a.lng));
        final db = distance(point, LatLng(b.lat, b.lng));
        return da < db ? a : b;
      });
      totalLighting += nearest.avgLighting;
      totalPoliceDist += nearest.avgPoliceDist;
      totalCrowd += nearest.avgCrowd;
      totalCrime += nearest.avgCrimeCount;
      count++;
    }

    final n = count > 0 ? count : 1;
    final avgLighting = totalLighting / n;
    final avgPoliceDist = totalPoliceDist / n;
    final avgCrowd = totalCrowd / n;
    final avgCrime = totalCrime / n;
    final pct = (score * 100).toStringAsFixed(0);
    final risk = _scoreToRisk(score);

    String summary;
    if (risk == 'Low') {
      summary = 'Score $pct/100 — safe route. '
          '${avgLighting >= 7 ? 'Well-lit' : avgLighting >= 4 ? 'Adequately lit' : 'Poorly lit'} '
          'with ${avgPoliceDist <= 3 ? 'good' : 'limited'} police coverage.';
    } else if (risk == 'Medium') {
      summary = 'Score $pct/100 — moderate risk. '
          '${avgCrime > 30 ? 'High incident history' : 'Some incidents recorded'} '
          'along this route. Stay alert.';
    } else {
      summary = 'Score $pct/100 — higher risk. '
          '${avgLighting < 4 ? 'Poor lighting' : 'Limited police coverage'} '
          'detected. Consider an alternative.';
    }

    final tips = <String>[];
    if (avgLighting < 4) tips.add('Avoid this route at night — poor lighting.');
    if (avgPoliceDist > 5) tips.add('Police coverage is limited along this route.');
    if (avgCrime > 30) tips.add('High incident history — share location before travelling.');
    if (avgCrowd < 200) tips.add('Low foot traffic — travel with company if possible.');
    if (tips.isEmpty && risk != 'Low') {
      tips.add('Stay aware and keep your guardian updated.');
    }

    return RouteExplanation(
      avgLighting: avgLighting,
      avgPoliceDist: avgPoliceDist,
      avgCrowd: avgCrowd,
      avgCrimeCount: avgCrime,
      summaryText: summary,
      tips: tips,
    );
  }

  String _scoreToRisk(double score) {
    if (score >= 0.75) return 'Low';
    if (score >= 0.50) return 'Medium';
    return 'High';
  }

  DemoRoute _parseDemoRoute(Map<String, dynamic> json) {
    final alts = (json['alternatives'] as List<dynamic>).map((a) {
      final coords = (a['polyline'] as List<dynamic>)
          .map((c) => LatLng(
                (c['lat'] as num).toDouble(),
                (c['lng'] as num).toDouble(),
              ))
          .toList();
      return RouteModel(
        id: a['id'] as String,
        polyline: coords,
        distanceMeters: (a['distance_meters'] as num).toDouble(),
        durationSeconds: (a['duration_seconds'] as num).toDouble(),
        safetyScore: (a['safety_score'] as num).toDouble(),
        riskLevel: a['risk_level'] as String,
        isCached: true,
        explanation: RouteExplanation(
          avgLighting: 5.5,
          avgPoliceDist: 3.2,
          avgCrowd: 450,
          avgCrimeCount: 22,
          summaryText:
              'Pre-cached demo route. Score: ${((a['safety_score'] as num).toDouble() * 100).toStringAsFixed(0)}/100.',
          tips: [],
        ),
      );
    }).toList();

    return DemoRoute(
      id: json['id'] as String,
      label: json['label'] as String,
      start: LatLng(
        (json['start']['lat'] as num).toDouble(),
        (json['start']['lng'] as num).toDouble(),
      ),
      end: LatLng(
        (json['end']['lat'] as num).toDouble(),
        (json['end']['lng'] as num).toDouble(),
      ),
      alternatives: alts,
    );
  }
}
