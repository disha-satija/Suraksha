import '../models/guardian.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';
import '../services/settings_service.dart';
import '../services/sms_service.dart';

/// Manages guardian mode — location sharing, offline queue, SMS fallback.
class GuardianRepository {
  final AppDatabase _db;
  final SupabaseService _supabase;
  final ConnectivityService _connectivity;
  final SettingsService _settings;
  final SmsService _sms;

  GuardianRepository({
    required AppDatabase db,
    required SupabaseService supabase,
    required ConnectivityService connectivity,
    required SettingsService settings,
    required SmsService sms,
  })  : _db = db,
        _supabase = supabase,
        _connectivity = connectivity,
        _settings = settings,
        _sms = sms;

  Guardian getGuardian() => _settings.getGuardian();

  Future<void> saveGuardian(Guardian guardian) =>
      _settings.saveGuardian(guardian);

  /// Called with the user's current GPS location.
  /// Online → push to Supabase AND send SMS if triggerSmsFallback is true.
  /// Offline → queue locally and send SMS if triggerSmsFallback is true.
  Future<void> updateLocation({
    required String userId,
    required double lat,
    required double lng,
    bool triggerSmsFallback = false,
  }) async {
    final update = LocationUpdate(
      localId: DateTime.now().millisecondsSinceEpoch.toString(),
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      isSynced: _connectivity.isOnline,
    );

    // Always queue locally first
    await _db.insertLocationUpdate(update);

    // Try Supabase sync if online
    if (_connectivity.isOnline) {
      try {
        await _supabase.updateUserLocation(
          userId: userId,
          lat: lat,
          lng: lng,
        );
      } catch (_) {
        // Supabase failed — location already queued locally
      }
    }

    // SMS alert fires regardless of connectivity whenever SOS is triggered
    if (triggerSmsFallback) {
      final guardian = getGuardian();
      if (guardian.isConfigured) {
        await _sms.sendGuardianAlert(
          guardianPhone: guardian.phone,
          latitude: lat,
          longitude: lng,
          userName: _settings.getUserName(),
          guardianName: guardian.name,
        );
      }
    }
  }

  /// Flush location queue to Supabase when connectivity restores.
  Future<void> syncOnConnectivityRestore(String userId) async {
    final pending = await _db.getUnsyncedLocations();
    if (pending.isEmpty) return;

    final updates = pending
        .map((row) => LocationUpdate(
              localId: row.localId,
              latitude: row.latitude,
              longitude: row.longitude,
              timestamp: row.recordedAt,
              isSynced: false,
            ))
        .toList();

    try {
      await _supabase.syncLocationBatch(updates);
      for (final row in pending) {
        await _db.markLocationSynced(row.localId);
      }
    } catch (_) {
      // Will retry on next restore
    }
  }

  /// Realtime stream from Supabase for the guardian's view.
  Stream<Map<String, dynamic>> guardianLocationStream(String userId) =>
      _supabase.guardianLocationStream(userId);
}
