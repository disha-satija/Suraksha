/// An incident report — lives in local SQLite outbox until synced to Supabase.
class Incident {
  final String? id;            // null until assigned by Supabase
  final String localId;        // UUID generated on device
  final double latitude;
  final double longitude;
  final String crimeType;
  final String description;
  final String timeOfDay;
  final DateTime reportedAt;
  final bool isSynced;

  const Incident({
    this.id,
    required this.localId,
    required this.latitude,
    required this.longitude,
    required this.crimeType,
    required this.description,
    required this.timeOfDay,
    required this.reportedAt,
    required this.isSynced,
  });

  Incident copyWith({
    String? id,
    String? localId,
    double? latitude,
    double? longitude,
    String? crimeType,
    String? description,
    String? timeOfDay,
    DateTime? reportedAt,
    bool? isSynced,
  }) {
    return Incident(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      crimeType: crimeType ?? this.crimeType,
      description: description ?? this.description,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      reportedAt: reportedAt ?? this.reportedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toSupabaseJson() => {
        'local_id': localId,
        'latitude': latitude,
        'longitude': longitude,
        'crime_type': crimeType,
        'description': description,
        'time_of_day': timeOfDay,
        'reported_at': reportedAt.toIso8601String(),
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
}
