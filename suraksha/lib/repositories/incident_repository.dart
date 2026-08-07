import '../models/incident.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';

/// Manages incident reporting — writes locally first, syncs when online.
class IncidentRepository {
  final AppDatabase _db;
  final SupabaseService _supabase;
  final ConnectivityService _connectivity;

  IncidentRepository({
    required AppDatabase db,
    required SupabaseService supabase,
    required ConnectivityService connectivity,
  })  : _db = db,
        _supabase = supabase,
        _connectivity = connectivity;

  /// Save an incident locally and attempt immediate sync if online.
  /// Returns the server response map (with safetyScore/riskLevel) on success,
  /// or null if the device is offline (will sync later).
  Future<Map<String, dynamic>?> reportIncident(Incident incident) async {
    await _db.insertIncident(incident);
    if (_connectivity.isOnline) {
      return _syncSingle(incident);
    }
    return null;
  }

  /// Sync a single incident to the backend immediately.
  Future<Map<String, dynamic>?> _syncSingle(Incident incident) async {
    try {
      final response = await _supabase.syncIncident(incident);
      await _db.markIncidentSynced(incident.localId);
      return response;
    } catch (_) {
      // Leave as unsynced — will retry next time
      return null;
    }
  }

  /// Push all unsynced local incidents to the backend.
  Future<void> syncPending() async {
    final pending = await _db.getUnsyncedIncidents();
    for (final row in pending) {
      try {
        final incident = Incident(
          localId: row.localId,
          latitude: row.latitude,
          longitude: row.longitude,
          city: row.city,
          area: row.area,
          crimeType: row.crimeType,
          description: row.description,
          lightingScore: row.lightingScore,
          policeStationDistanceKm: row.policeStationDistanceKm,
          crowdDensity: row.crowdDensity,
          crimeCount: row.crimeCount,
          weatherCondition: row.weatherCondition,
          timeOfDay: row.timeOfDay,
          reportedAt: row.reportedAt,
          incidentTimestamp: row.incidentTimestamp,
          isSynced: false,
        );
        await _supabase.syncIncident(incident);
        await _db.markIncidentSynced(row.localId);
      } catch (_) {
        // Leave as unsynced — will retry next time
      }
    }
  }

  /// Call this when connectivity is restored.
  Future<void> syncOnConnectivityRestore() => syncPending();
}
