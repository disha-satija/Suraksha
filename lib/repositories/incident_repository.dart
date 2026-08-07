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
  Future<void> reportIncident(Incident incident) async {
    await _db.insertIncident(incident);
    if (_connectivity.isOnline) {
      await _syncPending();
    }
  }

  /// Push all unsynced local incidents to Supabase.
  Future<void> _syncPending() async {
    final pending = await _db.getUnsyncedIncidents();
    for (final row in pending) {
      try {
        final incident = Incident(
          localId: row.localId,
          latitude: row.latitude,
          longitude: row.longitude,
          crimeType: row.crimeType,
          description: row.description,
          timeOfDay: row.timeOfDay,
          reportedAt: row.reportedAt,
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
  Future<void> syncOnConnectivityRestore() => _syncPending();
}
