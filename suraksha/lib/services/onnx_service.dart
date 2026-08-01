import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import '../models/safety_score_result.dart';
import '../core/constants/app_constants.dart';

/// Handles loading the ONNX model and running on-device inference.
/// Also computes per-feature XAI contributions with natural language
/// explanations — fully offline, no SHAP runtime needed.
class OnnxService {
  OrtSession? _session;
  Map<String, dynamic>? _weights;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  static const Map<String, String> _displayNames = {
    'lighting_score': 'Lighting',
    'police_station_distance_km': 'Police Distance',
    'crowd_density': 'Crowd Density',
    'crime_count': 'Crime Count',
  };

  static const Map<String, String> _icons = {
    'lighting_score': '💡',
    'police_station_distance_km': '🚔',
    'crowd_density': '👥',
    'crime_count': '⚠️',
  };

  Future<void> initialize() async {
    try {
      OrtEnv.instance.init();
      final modelBytes = await rootBundle.load(AppConstants.onnxModelPath);
      final sessionOptions = OrtSessionOptions();
      _session = OrtSession.fromBuffer(
        modelBytes.buffer.asUint8List(),
        sessionOptions,
      );
      final weightsStr =
          await rootBundle.loadString(AppConstants.modelWeightsPath);
      _weights = jsonDecode(weightsStr) as Map<String, dynamic>;
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  /// Run inference and return a fully enriched [SafetyScoreResult] with
  /// XAI contributions, natural language explanations, and improvement tips.
  SafetyScoreResult predict({
    required double lightingScore,
    required double policeDistanceKm,
    required double crowdDensity,
    required double crimeCount,
    String timeOfDay = 'Morning',
    String weatherCondition = 'Clear',
  }) {
    if (!_isInitialized || _session == null || _weights == null) {
      throw StateError('OnnxService not initialized.');
    }

    final weights = _weights!;
    final List<String> featureNames =
        List<String>.from(weights['feature_names'] as List);
    final List<double> scalerMean = List<double>.from(
        (weights['scaler_mean'] as List).map((e) => (e as num).toDouble()));
    final List<double> scalerScale = List<double>.from(
        (weights['scaler_scale'] as List).map((e) => (e as num).toDouble()));
    final List<double> modelWeights = List<double>.from(
        (weights['weights'] as List).map((e) => (e as num).toDouble()));
    final _ = (weights['intercept'] as num).toDouble();
    final int numNumeric = (weights['numeric_features'] as List).length;

    final Map<String, double> rawValues = {
      'lighting_score': lightingScore,
      'police_station_distance_km': policeDistanceKm,
      'crowd_density': crowdDensity,
      'crime_count': crimeCount,
    };

    // Build standardized input vector
    final inputList = List<double>.filled(featureNames.length, 0.0);
    for (int i = 0; i < featureNames.length; i++) {
      final name = featureNames[i];
      if (rawValues.containsKey(name) && i < numNumeric) {
        inputList[i] =
            (rawValues[name]! - scalerMean[i]) / scalerScale[i];
      } else if (name.startsWith('time_')) {
        final cat = name
            .replaceFirst('time_', '')
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w[0].toUpperCase() + w.substring(1))
            .join(' ');
        inputList[i] = (timeOfDay == cat) ? 1.0 : 0.0;
      } else if (name.startsWith('weather_')) {
        final catKey = name.replaceFirst('weather_', '');
        inputList[i] =
            (weatherCondition.toLowerCase() == catKey.toLowerCase())
                ? 1.0
                : 0.0;
      }
    }

    // ONNX inference
    final inputTensor = OrtValueTensor.createTensorWithDataList(
      Float32List.fromList(inputList),
      [1, featureNames.length],
    );
    final outputs = _session!.run(OrtRunOptions(), {'float_input': inputTensor});
    inputTensor.release();

    double rawScore = 0.5;
    if (outputs.isNotEmpty && outputs.first != null) {
      final outputData = outputs.first!.value;
      if (outputData is List) {
        rawScore = (outputData.first as num).toDouble();
      }
    }
    for (final o in outputs) o?.release();
    final score = rawScore.clamp(0.0, 1.0);

    // ── Build XAI contributions ──────────────────────────────────────────────
    final numericFeatureNames =
        List<String>.from(weights['numeric_features'] as List);
    final contributions = <FeatureContribution>[];

    for (int i = 0; i < numNumeric; i++) {
      final name = numericFeatureNames[i];
      if (!_displayNames.containsKey(name)) continue;
      final raw = rawValues[name] ?? 0.0;
      final contrib = modelWeights[i] * inputList[i];
      contributions.add(FeatureContribution(
        featureName: name,
        displayName: _displayNames[name]!,
        rawValue: raw,
        contribution: contrib,
        iconAsset: _icons[name] ?? '',
        explanation: _buildExplanation(name, raw, contrib),
        valueLabel: _buildValueLabel(name, raw),
      ));
    }

    // Sort by absolute contribution magnitude (most impactful first)
    contributions.sort((a, b) =>
        b.contribution.abs().compareTo(a.contribution.abs()));

    final riskLevel = _scoreToRisk(score);
    final summary = _buildSummary(score, riskLevel, contributions);
    final tips = _buildTips(score, rawValues);

    return SafetyScoreResult(
      score: score,
      riskLevel: riskLevel,
      contributions: contributions,
      isFromCache: false,
      summaryExplanation: summary,
      improvementTips: tips,
    );
  }

  // ── Natural language builders ──────────────────────────────────────────────

  String _buildExplanation(String name, double raw, double contrib) {
    final direction = contrib >= 0 ? 'raises' : 'lowers';
    switch (name) {
      case 'lighting_score':
        if (raw >= 7) return 'Well-lit area (${raw.toStringAsFixed(1)}/10) — $direction safety.';
        if (raw >= 4) return 'Moderate lighting (${raw.toStringAsFixed(1)}/10) — mild impact on safety.';
        return 'Poor lighting (${raw.toStringAsFixed(1)}/10) — significantly $direction safety.';
      case 'police_station_distance_km':
        if (raw <= 1.5) return 'Police station very close (${raw.toStringAsFixed(1)} km) — $direction safety.';
        if (raw <= 4) return 'Police station at moderate distance (${raw.toStringAsFixed(1)} km).';
        return 'Police station far away (${raw.toStringAsFixed(1)} km) — $direction safety.';
      case 'crowd_density':
        if (raw >= 700) return 'High crowd density (${ raw.toInt()} people) — busy area, $direction safety.';
        if (raw >= 300) return 'Moderate crowd (${ raw.toInt()} people) — typical activity level.';
        return 'Low crowd density (${ raw.toInt()} people) — isolated area, $direction safety.';
      case 'crime_count':
        if (raw <= 10) return 'Very few incidents recorded (${ raw.toInt()}) — $direction safety.';
        if (raw <= 30) return 'Moderate incident history (${ raw.toInt()} recorded) — some risk.';
        return 'High number of past incidents (${ raw.toInt()}) — significantly $direction safety.';
      default:
        return '';
    }
  }

  String _buildValueLabel(String name, double raw) {
    switch (name) {
      case 'lighting_score':
        return '${raw.toStringAsFixed(1)} / 10';
      case 'police_station_distance_km':
        return '${raw.toStringAsFixed(1)} km';
      case 'crowd_density':
        return '${raw.toInt()} density';
      case 'crime_count':
        return '${raw.toInt()} incidents';
      default:
        return raw.toStringAsFixed(2);
    }
  }

  String _buildSummary(
      double score, String riskLevel, List<FeatureContribution> contribs) {
    if (contribs.isEmpty) {
      return riskLevel == 'Low'
          ? 'This area appears generally safe based on available data.'
          : 'Limited data available — exercise caution.';
    }

    final topPositive =
        contribs.where((c) => c.contribution > 0).isNotEmpty
            ? contribs.firstWhere((c) => c.contribution > 0)
            : null;
    final topNegative =
        contribs.where((c) => c.contribution < 0).isNotEmpty
            ? contribs.firstWhere((c) => c.contribution < 0)
            : null;

    if (riskLevel == 'Low') {
      if (topPositive != null) {
        return '${topPositive.displayName} is the strongest safety factor here. '
            'This area scores ${(score * 100).toStringAsFixed(0)}/100 — generally safe.';
      }
      return 'This area scores ${(score * 100).toStringAsFixed(0)}/100 — generally safe to travel.';
    }

    if (riskLevel == 'Medium') {
      final parts = <String>[];
      if (topNegative != null) parts.add('${topNegative.displayName} is a concern');
      if (topPositive != null) parts.add('${topPositive.displayName} helps');
      if (parts.isNotEmpty) {
        return '${parts.join(', but ')}. Score: ${(score * 100).toStringAsFixed(0)}/100 — proceed with awareness.';
      }
      return 'Mixed safety signals. Score ${(score * 100).toStringAsFixed(0)}/100 — stay alert.';
    }

    // High risk
    if (topNegative != null) {
      return '${topNegative.displayName} is the primary risk factor. '
          'Score ${(score * 100).toStringAsFixed(0)}/100 — consider a safer route.';
    }
    return 'Multiple risk factors detected. Score ${(score * 100).toStringAsFixed(0)}/100 — avoid if possible.';
  }

  List<String> _buildTips(double score, Map<String, double> raw) {
    if (score >= 0.75) return []; // safe — no tips needed
    final tips = <String>[];
    final lighting = raw['lighting_score'] ?? 5.0;
    final policeDist = raw['police_station_distance_km'] ?? 3.0;
    final crimeCount = raw['crime_count'] ?? 20.0;
    final crowd = raw['crowd_density'] ?? 400.0;

    if (lighting < 4) tips.add('Travel during daytime or stay on well-lit streets.');
    if (policeDist > 5) tips.add('Note the nearest police station before travelling here.');
    if (crimeCount > 30) tips.add('High incident history — share your location with a guardian.');
    if (crowd < 200) {
      tips.add('Low foot traffic — avoid this area at night and travel with company.');
    }
    if (tips.isEmpty) {
      tips.add('Stay aware of your surroundings and keep your guardian updated.');
    }
    return tips;
  }

  String _scoreToRisk(double score) {
    if (score >= AppConstants.safetyHighThreshold) return 'Low';
    if (score >= AppConstants.safetyMediumThreshold) return 'Medium';
    return 'High';
  }

  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
  }
}
