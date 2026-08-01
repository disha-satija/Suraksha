/// Guardian contact set by the user in settings.
class Guardian {
  final String name;
  final String phone; // E.164 format preferred, e.g. +919876543210

  const Guardian({
    required this.name,
    required this.phone,
  });

  bool get isConfigured => name.isNotEmpty && phone.isNotEmpty;
}

/// A queued location update — stored locally when offline,
/// synced to Supabase when connectivity is restored.
class LocationUpdate {
  final String localId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final bool isSynced;

  const LocationUpdate({
    required this.localId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.isSynced,
  });

  Map<String, dynamic> toSupabaseJson() => {
        'local_id': localId,
        'latitude': latitude,
        'longitude': longitude,
        'recorded_at': timestamp.toIso8601String(),
      };
}
