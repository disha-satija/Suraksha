/// Where a safety score actually came from.
///
/// This exists because the UI previously showed one badge ("Offline estimate")
/// for every non-ONNX path, which told the user nothing true: it fired when the
/// on-device model failed to load, regardless of network state, and it never
/// distinguished a real nearby measurement from a distant guess.
enum ScoreSource {
  /// On-device ONNX ran against a nearby area's real features.
  onDeviceModel,

  /// Precomputed value from the bundled grid — the model was unavailable.
  cachedGrid,

  /// Live `safety_cells` value from the backend, including community reports.
  remoteModel,

  /// Validated AI estimate — the trained grid has no coverage here.
  aiEstimate,

  /// No usable data from any source.
  unavailable,
}

/// Result of a safety lookup for a single location.
/// Carries per-feature XAI contributions, natural language explanations,
/// and an overall summary — all computable in Dart, fully offline.
class SafetyScoreResult {
  final double score;
  final String riskLevel;
  final List<FeatureContribution> contributions;

  /// Provenance of [score]. Drives the badge shown on the score card.
  final ScoreSource source;

  /// Name of the area this score describes, when one can be named honestly.
  ///
  /// Null when the nearest known area is too far away to stand in for the
  /// user's location. Never assume this is the user's own locality — check
  /// [referenceDistanceKm].
  final String? areaLabel;

  /// Distance from the queried point to [areaLabel]'s centroid, in km.
  /// Null for sources that are not centroid-based (AI estimate, unavailable).
  final double? referenceDistanceKm;

  /// One-sentence plain-English verdict shown at the top of the XAI panel.
  final String summaryExplanation;

  /// Ordered list of what-to-improve suggestions (shown when risk is Medium/High).
  final List<String> improvementTips;

  const SafetyScoreResult({
    required this.score,
    required this.riskLevel,
    required this.contributions,
    required this.source,
    this.areaLabel,
    this.referenceDistanceKm,
    this.summaryExplanation = '',
    this.improvementTips = const [],
  });

  /// True when this score came from precomputed data rather than a live model.
  /// Kept for existing call sites; prefer switching on [source].
  bool get isFromCache => source == ScoreSource.cachedGrid;

  /// Short provenance label for the score card badge.
  String get sourceLabel {
    switch (source) {
      case ScoreSource.onDeviceModel:
        return 'On-device AI';
      case ScoreSource.cachedGrid:
        return 'Offline data';
      case ScoreSource.remoteModel:
        return 'Live community data';
      case ScoreSource.aiEstimate:
        return 'AI estimate';
      case ScoreSource.unavailable:
        return 'No data';
    }
  }

  /// Whether this score is precise enough to act on, or only indicative.
  /// AI estimates and distant grid references are indicative only.
  bool get isIndicativeOnly =>
      source == ScoreSource.aiEstimate ||
      source == ScoreSource.unavailable ||
      (referenceDistanceKm != null && referenceDistanceKm! > 3.0);

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
