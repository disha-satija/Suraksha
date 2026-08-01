import 'package:latlong2/latlong.dart';

/// XAI breakdown for a route — computed from grid entries along the polyline.
class RouteExplanation {
  final double avgLighting;
  final double avgPoliceDist;
  final double avgCrowd;
  final double avgCrimeCount;
  final String summaryText;
  final List<String> tips;

  const RouteExplanation({
    required this.avgLighting,
    required this.avgPoliceDist,
    required this.avgCrowd,
    required this.avgCrimeCount,
    required this.summaryText,
    required this.tips,
  });

  /// Per-factor rows for the UI — each has a label, value, icon, and
  /// a simple sentiment (positive/negative/neutral).
  List<RouteFactorRow> get factors => [
        RouteFactorRow(
          icon: '💡',
          label: 'Avg Lighting',
          value: '${avgLighting.toStringAsFixed(1)} / 10',
          sentiment: avgLighting >= 7
              ? RouteSentiment.positive
              : avgLighting >= 4
                  ? RouteSentiment.neutral
                  : RouteSentiment.negative,
          detail: avgLighting >= 7
              ? 'Well-lit route — good visibility throughout.'
              : avgLighting >= 4
                  ? 'Mixed lighting — some poorly lit stretches.'
                  : 'Poorly lit route — avoid at night.',
        ),
        RouteFactorRow(
          icon: '🚔',
          label: 'Avg Police Distance',
          value: '${avgPoliceDist.toStringAsFixed(1)} km',
          sentiment: avgPoliceDist <= 2
              ? RouteSentiment.positive
              : avgPoliceDist <= 5
                  ? RouteSentiment.neutral
                  : RouteSentiment.negative,
          detail: avgPoliceDist <= 2
              ? 'Police stations close to route — fast response.'
              : avgPoliceDist <= 5
                  ? 'Moderate police coverage along route.'
                  : 'Police stations far from route — lower coverage.',
        ),
        RouteFactorRow(
          icon: '👥',
          label: 'Avg Crowd Density',
          value: '${avgCrowd.toInt()}',
          sentiment: avgCrowd >= 600
              ? RouteSentiment.positive
              : avgCrowd >= 300
                  ? RouteSentiment.neutral
                  : RouteSentiment.negative,
          detail: avgCrowd >= 600
              ? 'Busy route — high natural surveillance.'
              : avgCrowd >= 300
                  ? 'Moderate foot traffic along route.'
                  : 'Low foot traffic — less natural surveillance.',
        ),
        RouteFactorRow(
          icon: '⚠️',
          label: 'Avg Incident Count',
          value: '${avgCrimeCount.toInt()} incidents',
          sentiment: avgCrimeCount <= 10
              ? RouteSentiment.positive
              : avgCrimeCount <= 30
                  ? RouteSentiment.neutral
                  : RouteSentiment.negative,
          detail: avgCrimeCount <= 10
              ? 'Very few incidents recorded along this route.'
              : avgCrimeCount <= 30
                  ? 'Moderate incident history along route.'
                  : 'High incident history — exercise caution.',
        ),
      ];
}

enum RouteSentiment { positive, neutral, negative }

class RouteFactorRow {
  final String icon;
  final String label;
  final String value;
  final RouteSentiment sentiment;
  final String detail;

  const RouteFactorRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.sentiment,
    required this.detail,
  });

  bool get isPositive => sentiment == RouteSentiment.positive;
  bool get isNegative => sentiment == RouteSentiment.negative;
}

/// A single route option (from OSRM or pre-cached).
class RouteModel {
  final String id;
  final List<LatLng> polyline;
  final double distanceMeters;
  final double durationSeconds;
  final double safetyScore;
  final String riskLevel;
  final bool isCached;
  final RouteExplanation? explanation; // XAI data — null if grid unavailable

  const RouteModel({
    required this.id,
    required this.polyline,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.safetyScore,
    required this.riskLevel,
    required this.isCached,
    this.explanation,
  });

  String get distanceLabel {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.toInt()} m';
  }

  String get durationLabel {
    final minutes = (durationSeconds / 60).round();
    if (minutes >= 60) {
      return '${minutes ~/ 60}h ${minutes % 60}m';
    }
    return '${minutes}m';
  }
}

/// A pre-cached demo route pair (start → end with stored polylines).
class DemoRoute {
  final String id;
  final String label;
  final LatLng start;
  final LatLng end;
  final List<RouteModel> alternatives;

  const DemoRoute({
    required this.id,
    required this.label,
    required this.start,
    required this.end,
    required this.alternatives,
  });
}
