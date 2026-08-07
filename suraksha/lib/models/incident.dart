/// An incident report — lives in local SQLite outbox until synced to the backend.
class Incident {
  final String? id;            // null until assigned by server
  final String localId;        // UUID generated on device (clientEventId)
  final double latitude;
  final double longitude;
  final String? city;
  final String? area;
  final String crimeType;
  final String description;
  final double lightingScore;
  final double policeStationDistanceKm;
  final double crowdDensity;
  final int crimeCount;
  final String weatherCondition;
  final String timeOfDay;
  final DateTime reportedAt;
  final DateTime? incidentTimestamp;
  final bool isSynced;

  // Returned by the server after sync — null until the server responds.
  final double? safetyScore;
  final String? riskLevel;

  const Incident({
    this.id,
    required this.localId,
    required this.latitude,
    required this.longitude,
    this.city,
    this.area,
    required this.crimeType,
    required this.description,
    required this.lightingScore,
    required this.policeStationDistanceKm,
    required this.crowdDensity,
    required this.crimeCount,
    required this.weatherCondition,
    required this.timeOfDay,
    required this.reportedAt,
    this.incidentTimestamp,
    required this.isSynced,
    this.safetyScore,
    this.riskLevel,
  });

  Incident copyWith({
    String? id,
    String? localId,
    double? latitude,
    double? longitude,
    String? city,
    String? area,
    String? crimeType,
    String? description,
    double? lightingScore,
    double? policeStationDistanceKm,
    double? crowdDensity,
    int? crimeCount,
    String? weatherCondition,
    String? timeOfDay,
    DateTime? reportedAt,
    DateTime? incidentTimestamp,
    bool? isSynced,
    double? safetyScore,
    String? riskLevel,
  }) {
    return Incident(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      area: area ?? this.area,
      crimeType: crimeType ?? this.crimeType,
      description: description ?? this.description,
      lightingScore: lightingScore ?? this.lightingScore,
      policeStationDistanceKm: policeStationDistanceKm ?? this.policeStationDistanceKm,
      crowdDensity: crowdDensity ?? this.crowdDensity,
      crimeCount: crimeCount ?? this.crimeCount,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      reportedAt: reportedAt ?? this.reportedAt,
      incidentTimestamp: incidentTimestamp ?? this.incidentTimestamp,
      isSynced: isSynced ?? this.isSynced,
      safetyScore: safetyScore ?? this.safetyScore,
      riskLevel: riskLevel ?? this.riskLevel,
    );
  }

  /// Payload sent to POST /incidents/sync.
  Map<String, dynamic> toSyncJson() => {
        'clientEventId': localId,
        'latitude': latitude,
        'longitude': longitude,
        if (city != null) 'city': city,
        if (area != null) 'area': area,
        'crimeType': crimeType,
        'description': description,
        'lightingScore': lightingScore,
        'policeStationDistanceKm': policeStationDistanceKm,
        'crowdDensity': crowdDensity,
        'crimeCount': crimeCount,
        'weatherCondition': weatherCondition,
        'reportedAt': reportedAt.toUtc().toIso8601String(),
        if (incidentTimestamp != null)
          'incidentTimestamp': incidentTimestamp!.toUtc().toIso8601String(),
      };

  static const List<String> crimeTypes = [
    'Assault',
    'Stalking',
    'Harassment',
    'Chain Snatching',
    'Domestic Violence',
    'Kidnapping',
    'Cyber Crime',
    'Verbal Abuse',
    'Unsafe Transport',
    'Night Safety Complaint',
    'Other',
  ];

  static const List<String> weatherConditions = [
    'Clear',
    'Cloudy',
    'Rainy',
    'Foggy',
    'Stormy',
  ];
}
