/// Represents one precomputed area entry in the safety grid.
class SafetyGridEntry {
  final String city;
  final String area;
  final double lat;
  final double lng;
  final double avgSafetyScore;
  final double avgLighting;
  final double avgPoliceDist;
  final double avgCrowd;
  final double avgCrimeCount;
  final int incidentCount;
  final String riskLevel;

  const SafetyGridEntry({
    required this.city,
    required this.area,
    required this.lat,
    required this.lng,
    required this.avgSafetyScore,
    required this.avgLighting,
    required this.avgPoliceDist,
    required this.avgCrowd,
    required this.avgCrimeCount,
    required this.incidentCount,
    required this.riskLevel,
  });

  factory SafetyGridEntry.fromJson(Map<String, dynamic> json) {
    // The bundled asset uses camelCase; a backend payload may use snake_case.
    // Accept either rather than silently throwing and losing the whole grid.
    num? pick(String camel, String snake) =>
        (json[camel] ?? json[snake]) as num?;

    return SafetyGridEntry(
      city: json['city'] as String? ?? '',
      area: json['area'] as String? ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      avgSafetyScore: pick('avgSafetyScore', 'avg_safety_score')?.toDouble() ?? 0.5,
      avgLighting: pick('avgLighting', 'avg_lighting')?.toDouble() ?? 3.0,
      avgPoliceDist: pick('avgPoliceDist', 'avg_police_dist')?.toDouble() ?? 2.0,
      avgCrowd: pick('avgCrowd', 'avg_crowd')?.toDouble() ?? 300.0,
      avgCrimeCount: pick('avgCrimeCount', 'avg_crime_count')?.toDouble() ?? 5.0,
      incidentCount:
          pick('incidentCount', 'incident_count')?.toInt() ??
              pick('sampleCount', 'sample_count')?.toInt() ??
              0,
      riskLevel: (json['riskLevel'] ?? json['risk_level']) as String? ?? 'Medium',
    );
  }
}
