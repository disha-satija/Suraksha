import 'dart:async';
import '../models/guardian.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';
import '../services/settings_service.dart';
import '../services/sms_service.dart';

/// Manages guardian contacts, secure sharing sessions, location sync, and SOS.
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

  Future<void> saveGuardian(Guardian guardian) async {
    await _settings.saveGuardian(guardian);
    if (!SupabaseService.isInitialized || !guardian.isConfigured) return;
    final body = {
      'name': guardian.name,
      'phone': guardian.phone,
    };
    final guardians = await _supabase.getGuardians();
    final existing = guardians.whereType<Map>().cast<Map<String, dynamic>>().where(
      (item) => item['phone'] == guardian.phone,
    ).toList();
    final created = existing.isNotEmpty
        ? await _supabase.updateGuardian(existing.first['id'] as String, body)
        : await _supabase.createGuardian(body);
    final data = created['data'] as Map<String, dynamic>?;
    if (data?['id'] is String) await _settings.saveGuardianBackendState(guardianId: data!['id'] as String);
  }

  Future<String?> _ensureSharingSession() async {
    final existing = _settings.sharingSessionId;
    if (existing != null && existing.isNotEmpty) return existing;
    if (!SupabaseService.isInitialized) return null;

    String? guardianId = _settings.guardianId;
    if (guardianId == null) {
      final guardians = await _supabase.getGuardians();
      final local = getGuardian();
      final matching = guardians.whereType<Map>().cast<Map<String, dynamic>>().where(
        (item) => item['phone'] == local.phone,
      ).toList();
      if (matching.isNotEmpty) {
        guardianId = matching.first['id'] as String?;
      } else if (local.isConfigured) {
        final created = await _supabase.createGuardian({'name': local.name, 'phone': local.phone});
        guardianId = (created['data'] as Map<String, dynamic>?)?['id'] as String?;
      }
      if (guardianId != null) await _settings.saveGuardianBackendState(guardianId: guardianId);
    }
    if (guardianId == null) return null;

    final created = await _supabase.createSharingSession(guardianId: guardianId);
    final data = created['data'] as Map<String, dynamic>?;
    final session = data?['session'] as Map<String, dynamic>?;
    final sessionId = session?['id'] as String?;
    final shareToken = data?['shareToken'] as String?;
    if (sessionId == null) return null;
    await _settings.saveGuardianBackendState(sessionId: sessionId, shareToken: shareToken);
    return sessionId;
  }

  Future<void> updateLocation({
    required double lat,
    required double lng,
    double? accuracyM,
    bool triggerSmsFallback = false,
  }) async {
    final now = DateTime.now();
    final localId = '${now.microsecondsSinceEpoch}_${lat}_$lng';
    final update = LocationUpdate(
      localId: localId,
      latitude: lat,
      longitude: lng,
      timestamp: now,
      isSynced: false,
    );
    await _db.insertLocationUpdate(update);

    // ── SOS: /sos/direct — no auth required, always works ─────────────────────
    // Passes the guardian phone stored on device so the backend can call
    // Twilio immediately without needing a Supabase session.
    if (triggerSmsFallback && _connectivity.isOnline) {
      final guardian = getGuardian();
      if (guardian.isConfigured) {
        try {
          await _supabase.sendDirectSos(
            guardianPhone: guardian.phone,
            lat: lat,
            lng: lng,
            userName: _settings.getUserName(),
          );
        } catch (_) {
          // best-effort — swallow so navigation/UI is never blocked
        }
      }
    }

    // ── Location sync (session-gated) ──────────────────────────────────
    if (_connectivity.isOnline && SupabaseService.isInitialized) {
      try {
        final sessionId = await _ensureSharingSession();
        if (sessionId != null) {
          await _supabase.updateUserLocation(
            sessionId: sessionId,
            lat: lat,
            lng: lng,
            clientEventId: localId,
            recordedAt: now,
            accuracyM: accuracyM,
          );
          await _db.markLocationSynced(localId);
        }
      } catch (_) {
        // Non-fatal — local outbox will sync on next connectivity restore.
      }
    }
  }

  Future<void> syncOnConnectivityRestore() async {
    final sessionId = _settings.sharingSessionId;
    if (sessionId == null || sessionId.isEmpty) return;
    final pending = await _db.getUnsyncedLocations();
    if (pending.isEmpty) return;

    final updates = pending.map((row) => LocationUpdate(
      localId: row.localId,
      latitude: row.latitude,
      longitude: row.longitude,
      timestamp: row.recordedAt,
      isSynced: false,
    )).toList();
    try {
      await _supabase.syncLocationBatch(sessionId, updates);
      for (final row in pending) {
        await _db.markLocationSynced(row.localId);
      }
    } catch (_) {
      // The outbox remains intact for the next retry.
    }
  }

  Stream<Map<String, dynamic>> guardianLocationStream(String shareToken) =>
      _supabase.guardianLocationStream(shareToken);
}
