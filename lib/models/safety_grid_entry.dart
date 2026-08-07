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
    return SafetyGridEntry(
      city: json['city'] as String,
      area: json['area'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      avgSafetyScore: (json['avg_safety_score'] as num).toDouble(),
      avgLighting: (json['avg_lighting'] as num).toDouble(),
      avgPoliceDist: (json['avg_police_dist'] as num).toDouble(),
      avgCrowd: (json['avg_crowd'] as num).toDouble(),
      avgCrimeCount: (json['avg_crime_count'] as num).toDouble(),
      incidentCount: (json['incident_count'] as num).toInt(),
      riskLevel: json['risk_level'] as String,
    );
  }
}
