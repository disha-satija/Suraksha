import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../models/safety_grid_entry.dart';
import '../models/safety_score_result.dart';
import '../services/onnx_service.dart';
import '../core/constants/app_constants.dart';

/// Single source of truth for safety scores.
/// Tries ONNX inference first; falls back to precomputed grid on failure.
class SafetyRepository {
  final OnnxService _onnxService;
  List<SafetyGridEntry>? _grid;

  SafetyRepository({required OnnxService onnxService})
      : _onnxService = onnxService;

  Future<void> initialize() async {
    await _loadGrid();
    // ONNX init is best-effort — grid fallback works without it
    try {
      if (!_onnxService.isInitialized) {
        await _onnxService.initialize();
      }
    } catch (_) {
      // ONNX unavailable (common on simulator) — grid fallback will be used
    }
  }

  Future<void> _loadGrid() async {
    final jsonStr = await rootBundle.loadString(AppConstants.safetyGridPath);
    final data = jsonDecode(jsonStr) as List<dynamic>;
    _grid = data
        .map((e) => SafetyGridEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<SafetyGridEntry> get grid => _grid ?? [];

  /// Returns a safety score with full XAI for a location.
  /// Uses live ONNX if available; falls back to precomputed grid.
  SafetyScoreResult getScore({
    required double lat,
    required double lng,
    double? lightingScore,
    double? policeDistanceKm,
    double? crowdDensity,
    double? crimeCount,
    String timeOfDay = 'Morning',
    String weatherCondition = 'Clear',
  }) {
    if (_onnxService.isInitialized &&
        lightingScore != null &&
        policeDistanceKm != null &&
        crowdDensity != null &&
        crimeCount != null) {
      try {
        return _onnxService.predict(
          lightingScore: lightingScore,
          policeDistanceKm: policeDistanceKm,
          crowdDensity: crowdDensity,
          crimeCount: crimeCount,
          timeOfDay: timeOfDay,
          weatherCondition: weatherCondition,
        );
      } catch (_) {
        // fall through to grid
      }
    }
    return _getGridScore(lat, lng);
  }

  // ── Grid fallback with full XAI ─────────────────────────────────────────────

  SafetyScoreResult _getGridScore(double lat, double lng) {
    if (_grid == null || _grid!.isEmpty) {
      return const SafetyScoreResult(
        score: 0.5,
        riskLevel: 'Medium',
        contributions: [],
        isFromCache: true,
        summaryExplanation:
            'No safety data available for this location. Exercise caution.',
      );
    }

    double minDist = double.infinity;
    SafetyGridEntry? nearest;
    for (final entry in _grid!) {
      final d = _haversine(lat, lng, entry.lat, entry.lng);
      if (d < minDist) {
        minDist = d;
        nearest = entry;
      }
    }

    final e = nearest!;
    final score = e.avgSafetyScore;
    final riskLevel = e.riskLevel;

    return SafetyScoreResult(
      score: score,
      riskLevel: riskLevel,
      isFromCache: true,
      summaryExplanation: _gridSummary(score, riskLevel, e),
      improvementTips: _gridTips(score, e),
      contributions: [
        FeatureContribution(
          featureName: 'lighting_score',
          displayName: 'Lighting',
          rawValue: e.avgLighting,
          contribution: 0,
          iconAsset: '💡',
          valueLabel: '${e.avgLighting.toStringAsFixed(1)} / 10',
          explanation: e.avgLighting >= 7
              ? 'Generally well-lit area.'
              : e.avgLighting >= 4
                  ? 'Moderate lighting conditions.'
                  : 'Poor average lighting — take care at night.',
        ),
        FeatureContribution(
          featureName: 'police_station_distance_km',
          displayName: 'Police Distance',
          rawValue: e.avgPoliceDist,
          contribution: 0,
          iconAsset: '🚔',
          valueLabel: '${e.avgPoliceDist.toStringAsFixed(1)} km',
          explanation: e.avgPoliceDist <= 2
              ? 'Police station nearby — good response coverage.'
              : e.avgPoliceDist <= 5
                  ? 'Police at moderate distance.'
                  : 'Police station far away — limited immediate response.',
        ),
        FeatureContribution(
          featureName: 'crowd_density',
          displayName: 'Crowd Density',
          rawValue: e.avgCrowd,
          contribution: 0,
          iconAsset: '👥',
          valueLabel: '${e.avgCrowd.toInt()} density',
          explanation: e.avgCrowd >= 600
              ? 'Busy area — higher natural surveillance.'
              : e.avgCrowd >= 300
                  ? 'Moderate foot traffic.'
                  : 'Low foot traffic — less natural surveillance.',
        ),
        FeatureContribution(
          featureName: 'crime_count',
          displayName: 'Crime Count',
          rawValue: e.avgCrimeCount,
          contribution: 0,
          iconAsset: '⚠️',
          valueLabel: '${e.avgCrimeCount.toInt()} incidents',
          explanation: e.avgCrimeCount <= 10
              ? 'Few incidents recorded in this area.'
              : e.avgCrimeCount <= 30
                  ? 'Moderate incident history recorded.'
                  : 'High number of past incidents reported.',
        ),
      ],
    );
  }

  String _gridSummary(double score, String riskLevel, SafetyGridEntry e) {
    final pct = (score * 100).toStringAsFixed(0);
    if (riskLevel == 'Low') {
      return '${e.area} scores $pct/100. Generally safe — good lighting and proximity to police.';
    }
    if (riskLevel == 'Medium') {
      return '${e.area} scores $pct/100. Some risk factors present — stay alert and share location.';
    }
    return '${e.area} scores $pct/100. Multiple risk factors — consider an alternative route.';
  }

  List<String> _gridTips(double score, SafetyGridEntry e) {
    if (score >= 0.75) return [];
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
