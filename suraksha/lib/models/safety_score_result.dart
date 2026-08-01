/// Result of on-device ONNX inference for a single location.
/// Carries per-feature XAI contributions, natural language explanations,
/// and an overall summary — all computable in Dart, fully offline.
class SafetyScoreResult {
  final double score;
  final String riskLevel;
  final List<FeatureContribution> contributions;
  final bool isFromCache;

  /// One-sentence plain-English verdict shown at the top of the XAI panel.
  final String summaryExplanation;

  /// Ordered list of what-to-improve suggestions (shown when risk is Medium/High).
  final List<String> improvementTips;

  const SafetyScoreResult({
    required this.score,
    required this.riskLevel,
    required this.contributions,
    required this.isFromCache,
    this.summaryExplanation = '',
    this.improvementTips = const [],
  });

  String get riskLabel {
    if (score >= 0.75) return 'Low Risk';
    if (score >= 0.50) return 'Medium Risk';
    return 'High Risk';
  }

  /// Top negative contributor — the single biggest reason this area is unsafe.
  FeatureContribution? get topRiskFactor {
    if (contributions.isEmpty) return null;
    final negatives = contributions.where((c) => c.contribution < 0).toList();
    if (negatives.isEmpty) return null;
    negatives.sort((a, b) => a.contribution.compareTo(b.contribution));
    return negatives.first;
  }

  /// Top positive contributor — the biggest safety asset of this area.
  FeatureContribution? get topSafetyFactor {
    if (contributions.isEmpty) return null;
    final positives = contributions.where((c) => c.contribution > 0).toList();
    if (positives.isEmpty) return null;
    positives.sort((a, b) => b.contribution.compareTo(a.contribution));
    return positives.first;
  }
}

/// One feature's contribution to the final safety score.
/// contribution = weight × normalizedValue  (linear model)
class FeatureContribution {
  final String featureName;
  final String displayName;
  final double rawValue;

  /// Signed value: positive = raises safety, negative = lowers safety.
  final double contribution;

  /// Icon representing this feature in the UI.
  final String iconAsset; // emoji fallback — no icon assets needed

  /// Human-readable explanation of this feature's impact, e.g.
  /// "Poor lighting (score 2.1) significantly reduces safety."
  final String explanation;

  /// Short label for the raw value, e.g. "Score: 2.1" or "1.2 km away"
  final String valueLabel;

  const FeatureContribution({
    required this.featureName,
    required this.displayName,
    required this.rawValue,
    required this.contribution,
    this.iconAsset = '',
    this.explanation = '',
    this.valueLabel = '',
  });

  /// How dominant this factor is relative to a ±0.5 max range.
  double get normalizedMagnitude =>
      contribution.abs().clamp(0.0, 0.5) / 0.5;

  bool get isPositive => contribution >= 0;
}
