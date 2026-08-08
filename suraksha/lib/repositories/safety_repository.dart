import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/safety_grid_entry.dart';
import '../models/safety_score_result.dart';
import '../services/api_client.dart';
import '../services/connectivity_service.dart';
import '../services/onnx_service.dart';
import '../core/constants/app_constants.dart';

/// Single source of truth for safety scores.
///
/// Resolution order for [getAreaScore]:
///   1. Backend `/safety/score` — trained cells including community reports,
///      or a validated AI estimate where the trained grid has no coverage.
///   2. On-device ONNX against the nearest bundled grid area.
///   3. The bundled grid's precomputed value.
///   4. An explicit "no data" result.
///
/// Every result carries a [ScoreSource] so the UI can state which of these
/// actually produced the number, instead of labelling all of them "offline".
class SafetyRepository {
  final OnnxService _onnxService;
  final ApiClient? _api;
  final ConnectivityService? _connectivity;
  List<SafetyGridEntry>? _grid;

  SafetyRepository({
    required OnnxService onnxService,
    ApiClient? api,
    ConnectivityService? connectivity,
  })  : _onnxService = onnxService,
        _api = api,
        _connectivity = connectivity;

  Future<void> initialize() async {
    await _loadGrid();
    // ONNX init is best-effort — grid fallback works without it.
    try {
      if (!_onnxService.isInitialized) {
        await _onnxService.initialize();
      }
    } catch (e, stack) {
      // Logged, not silent: this is the single most common reason the app
      // falls back to precomputed scores, and swallowing it made that
      // undiagnosable from a normal run.
      debugPrint('[SafetyRepository] ONNX unavailable, using grid fallback: $e');
      debugPrintStack(stackTrace: stack, maxFrames: 5);
    }
  }

  Future<void> _loadGrid() async {
    // Safe to call twice: MapViewModel.initialize() and main() both call
    // SafetyRepository.initialize() — skip reloading once the grid is set.
    if (_grid != null) return;

    final jsonStr = await rootBundle.loadString(AppConstants.safetyGridPath);
    final data = jsonDecode(jsonStr) as List<dynamic>;
    final entries = <SafetyGridEntry>[];
    for (final e in data) {
      try {
        entries.add(SafetyGridEntry.fromJson(e as Map<String, dynamic>));
      } catch (err) {
        // Skip a malformed row rather than losing the whole grid.
        debugPrint('[SafetyRepository] skipped malformed grid row: $err');
      }
    }
    _grid = entries;
  }

  List<SafetyGridEntry> get grid => _grid ?? [];

  // ── Nearest-area lookup ─────────────────────────────────────────────────────

  /// Nearest bundled-grid area to a point, with its distance in km.
  ///
  /// The grid holds one centroid per area, so callers MUST check the distance
  /// before presenting the area name as the user's own location.
  ({SafetyGridEntry? entry, double distanceKm}) nearestEntry(double lat, double lng) {
    final entries = _grid;
    if (entries == null || entries.isEmpty) {
      return (entry: null, distanceKm: double.infinity);
    }
    double minDist = double.infinity;
    SafetyGridEntry? nearest;
    for (final entry in entries) {
      final d = _haversine(lat, lng, entry.lat, entry.lng);
      if (d < minDist) {
        minDist = d;
        nearest = entry;
      }
    }
    return (entry: nearest, distanceKm: minDist);
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Offline-only score. Synchronous, so it is safe to call during a map tap.
  /// Never touches the network — use [getAreaScore] when a round trip is fine.
  SafetyScoreResult getScore({
    required double lat,
    required double lng,
    String timeOfDay = 'Morning',
    String weatherCondition = 'Clear',
  }) {
    final near = nearestEntry(lat, lng);
    final entry = near.entry;

    if (entry == null) {
      return _unavailable('No safety data is bundled with this app build.');
    }

    // Beyond this radius the nearest centroid describes a different part of the
    // city. Returning its score as "your area" is what made the dashboard claim
    // the user was in Lajpat Nagar from anywhere in south-east Delhi.
    if (near.distanceKm > AppConstants.gridTrustMaxKm) {
      return _noLocalCoverage(entry, near.distanceKm);
    }

    // ── On-device model ──────────────────────────────────────────────────────
    if (_onnxService.isInitialized) {
      try {
        final predicted = _onnxService.predict(
          lightingScore: entry.avgLighting,
          policeDistanceKm: entry.avgPoliceDist,
          crowdDensity: entry.avgCrowd,
          crimeCount: entry.avgCrimeCount,
          timeOfDay: timeOfDay,
          weatherCondition: weatherCondition,
        );
        return SafetyScoreResult(
          score: predicted.score,
          riskLevel: predicted.riskLevel,
          contributions: predicted.contributions,
          source: ScoreSource.onDeviceModel,
          areaLabel: entry.area,
          referenceDistanceKm: near.distanceKm,
          summaryExplanation:
              _areaSummary(predicted.score, predicted.riskLevel, entry, near.distanceKm),
          improvementTips: predicted.improvementTips,
        );
      } catch (e) {
        debugPrint('[SafetyRepository] ONNX predict failed, using grid value: $e');
      }
    }

    // ── Precomputed grid value ───────────────────────────────────────────────
    return SafetyScoreResult(
      score: entry.avgSafetyScore,
      riskLevel: entry.riskLevel,
      contributions: _buildContributions(
        lighting: entry.avgLighting,
        policeDistanceKm: entry.avgPoliceDist,
        crowdDensity: entry.avgCrowd,
        crimeCount: entry.avgCrimeCount,
      ),
      source: ScoreSource.cachedGrid,
      areaLabel: entry.area,
      referenceDistanceKm: near.distanceKm,
      summaryExplanation:
          _areaSummary(entry.avgSafetyScore, entry.riskLevel, entry, near.distanceKm),
      improvementTips: _gridTips(entry.avgSafetyScore, entry),
    );
  }

  /// Full lookup for the home dashboard.
  ///
  /// Prefers the backend so community-reported incidents (which the server
  /// blends into `safety_cells`) actually reach the user, and so locations
  /// outside the trained grid get a validated AI estimate instead of a
  /// distant area's score. Falls back to [getScore] whenever the network is
  /// unavailable or the server has nothing better.
  Future<SafetyScoreResult> getAreaScore({
    required double lat,
    required double lng,
    String timeOfDay = 'Morning',
    String weatherCondition = 'Clear',
  }) async {
    if (_api != null && (_connectivity?.isOnline ?? false)) {
      try {
        final remote = await _fetchRemoteScore(lat, lng);
        if (remote != null) return remote;
      } catch (e) {
        debugPrint('[SafetyRepository] remote score failed, using local: $e');
      }
    }
    return getScore(
      lat: lat,
      lng: lng,
      timeOfDay: timeOfDay,
      weatherCondition: weatherCondition,
    );
  }

  // ── Remote ──────────────────────────────────────────────────────────────────

  /// How long to wait for the backend before falling back to local data.
  /// `isOnline` only means the device has a network interface — it says nothing
  /// about whether the API host is reachable, so this path must be bounded or
  /// the dashboard sits on its loading spinner until the socket gives up.
  static const Duration _remoteTimeout = Duration(seconds: 6);

  /// Calls `GET /safety/score`. Returns null when the server has no usable
  /// answer, so the caller can fall back to local data.
  Future<SafetyScoreResult?> _fetchRemoteScore(double lat, double lng) async {
    final payload = await _api!.get('/safety/score', query: {
      'lat': lat,
      'lng': lng,
      // Same coverage gate the client applies locally, so "no data" means the
      // same thing on both sides.
      'maxDistanceM': AppConstants.gridTrustMaxMeters,
    }).timeout(_remoteTimeout);

    final data = payload['data'];
    if (data is! Map<String, dynamic>) return null;

    final source = data['source'] as String?;
    final score = (data['score'] as num?)?.toDouble();
    if (score == null || score.isNaN) return null;
    final clamped = score.clamp(0.0, 1.0);

    // ── Trained cell, including any community-reported updates ───────────────
    if (source == 'model') {
      final features = data['features'];
      final area = data['area'] as String?;
      final distanceKm = ((data['distanceM'] as num?)?.toDouble() ?? 0) / 1000;
      return SafetyScoreResult(
        score: clamped,
        riskLevel: _titleCaseRisk(data['riskLevel'] as String?, clamped),
        contributions: features is Map<String, dynamic>
            ? _buildContributions(
                lighting: (features['lighting'] as num?)?.toDouble(),
                policeDistanceKm: (features['policeDistanceKm'] as num?)?.toDouble(),
                crowdDensity: (features['crowdDensity'] as num?)?.toDouble(),
                crimeCount: (features['crimeCount'] as num?)?.toDouble(),
              )
            : const [],
        source: ScoreSource.remoteModel,
        areaLabel: area,
        referenceDistanceKm: distanceKm,
        summaryExplanation: _remoteSummary(clamped, area, distanceKm),
      );
    }

    // ── Validated AI estimate — no trained coverage for this location ────────
    if (source == 'ai-estimate') {
      final area = data['area'] as String?;
      final reasons = _stringList(data['reasons']);
      final tips = _stringList(data['tips']);
      final pct = (clamped * 100).round();
      final where = (area == null || area.isEmpty) ? 'this area' : area;
      final because = reasons.isEmpty ? '' : ' ${reasons.first}';
      return SafetyScoreResult(
        score: clamped,
        riskLevel: _titleCaseRisk(data['riskLevel'] as String?, clamped),
        contributions: const [], // No measured features exist for this location.
        source: ScoreSource.aiEstimate,
        areaLabel: area,
        summaryExplanation:
            'AI estimate for $where: $pct/100.$because Not from the trained safety model — treat as a rough guide.',
        improvementTips: tips,
      );
    }

    return null; // 'none' or anything unrecognised — let the caller fall back.
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  /// The server uses lowercase risk labels; the app displays title case.
  /// Falls back to deriving from the score if the label is missing or unknown.
  static String _titleCaseRisk(String? raw, double score) {
    switch (raw?.toLowerCase()) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
    }
    if (score >= AppConstants.safetyHighThreshold) return 'Low';
    if (score >= AppConstants.safetyMediumThreshold) return 'Medium';
    return 'High';
  }

  // ── Result builders ─────────────────────────────────────────────────────────

  SafetyScoreResult _unavailable(String reason) => SafetyScoreResult(
        score: 0.5,
        riskLevel: 'Medium',
        contributions: const [],
        source: ScoreSource.unavailable,
        summaryExplanation: '$reason Exercise standard caution.',
      );

  /// The nearest known area is too far to describe this location. Say that,
  /// rather than presenting a distant area's score as the user's own.
  SafetyScoreResult _noLocalCoverage(SafetyGridEntry entry, double distanceKm) {
    return SafetyScoreResult(
      score: 0.5,
      riskLevel: 'Medium',
      contributions: const [],
      source: ScoreSource.unavailable,
      areaLabel: null, // Deliberately unnamed — we are not in this area.
      referenceDistanceKm: distanceKm,
      summaryExplanation:
          'No safety data covers this location yet. The nearest area we have is '
          '${entry.area}, ${distanceKm.toStringAsFixed(0)} km away — too far to describe where you are. '
          'Connect to the internet for an estimate.',
    );
  }

  /// Names the area only when the centroid is genuinely close. Beyond that it
  /// is presented as a nearby reference point, with the distance stated.
  String _areaSummary(double score, String riskLevel, SafetyGridEntry e, double distKm) {
    final pct = (score * 100).toStringAsFixed(0);

    if (distKm > AppConstants.areaLabelMaxKm) {
      return 'Nearest reference area: ${e.area}, ${distKm.toStringAsFixed(1)} km away. '
          'Estimated $pct/100 for your surroundings — indicative only.';
    }
    if (riskLevel == 'Low') {
      return '${e.area} scores $pct/100. Generally safe — good lighting and proximity to police.';
    }
    if (riskLevel == 'Medium') {
      return '${e.area} scores $pct/100. Some risk factors present — stay alert and share location.';
    }
    return '${e.area} scores $pct/100. Multiple risk factors — consider an alternative route.';
  }

  String _remoteSummary(double score, String? area, double distKm) {
    final pct = (score * 100).toStringAsFixed(0);
    if (area == null || area.isEmpty) {
      return 'Your area scores $pct/100, including recent community reports.';
    }
    if (distKm > AppConstants.areaLabelMaxKm) {
      return 'Nearest reference area: $area, ${distKm.toStringAsFixed(1)} km away. '
          'Estimated $pct/100 including recent community reports — indicative only.';
    }
    return '$area scores $pct/100, including recent community reports.';
  }

  /// Builds the four XAI rows shown under "Why this score".
  /// Shared by the bundled grid and the backend's feature payload; any feature
  /// the source could not supply is omitted rather than defaulted.
  List<FeatureContribution> _buildContributions({
    double? lighting,
    double? policeDistanceKm,
    double? crowdDensity,
    double? crimeCount,
  }) {
    return [
      if (lighting != null)
        FeatureContribution(
          featureName: 'lighting_score',
          displayName: 'Lighting',
          rawValue: lighting,
          contribution: 0,
          iconAsset: '💡',
          valueLabel: '${lighting.toStringAsFixed(1)} / 10',
          explanation: lighting >= 7
              ? 'Generally well-lit area.'
              : lighting >= 4
                  ? 'Moderate lighting conditions.'
                  : 'Poor average lighting — take care at night.',
        ),
      if (policeDistanceKm != null)
        FeatureContribution(
          featureName: 'police_station_distance_km',
          displayName: 'Police Distance',
          rawValue: policeDistanceKm,
          contribution: 0,
          iconAsset: '🚔',
          valueLabel: '${policeDistanceKm.toStringAsFixed(1)} km',
          explanation: policeDistanceKm <= 2
              ? 'Police station nearby — good response coverage.'
              : policeDistanceKm <= 5
                  ? 'Police at moderate distance.'
                  : 'Police station far away — limited immediate response.',
        ),
      if (crowdDensity != null)
        FeatureContribution(
          featureName: 'crowd_density',
          displayName: 'Crowd Density',
          rawValue: crowdDensity,
          contribution: 0,
          iconAsset: '👥',
          valueLabel: '${crowdDensity.toInt()} density',
          explanation: crowdDensity >= 600
              ? 'Busy area — higher natural surveillance.'
              : crowdDensity >= 300
                  ? 'Moderate foot traffic.'
                  : 'Low foot traffic — less natural surveillance.',
        ),
      if (crimeCount != null)
        FeatureContribution(
          featureName: 'crime_count',
          displayName: 'Crime Count',
          rawValue: crimeCount,
          contribution: 0,
          iconAsset: '⚠️',
          valueLabel: '${crimeCount.toInt()} incidents',
          explanation: crimeCount <= 10
              ? 'Few incidents recorded in this area.'
              : crimeCount <= 30
                  ? 'Moderate incident history recorded.'
                  : 'High number of past incidents reported.',
        ),
    ];
  }

  List<String> _gridTips(double score, SafetyGridEntry e) {
    if (score >= AppConstants.safetyHighThreshold) return [];
    final tips = <String>[];
    if (e.avgLighting < 4) tips.add('Travel during daytime or use well-lit streets.');
    if (e.avgPoliceDist > 5) tips.add('Note the nearest police station before travelling here.');
    if (e.avgCrimeCount > 30) tips.add('High incident history — share location with a guardian.');
    if (e.avgCrowd < 200) tips.add('Low foot traffic — avoid at night, travel with company.');
    if (tips.isEmpty) tips.add('Stay aware and keep your guardian updated.');
    return tips;
  }

  // ── Haversine ───────────────────────────────────────────────────────────────

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final sinDLat = math.sin(dLat / 2);
    final sinDLon = math.sin(dLon / 2);
    final a = sinDLat * sinDLat +
        math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) *
        sinDLon * sinDLon;
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _toRad(double deg) => deg * math.pi / 180;
}
