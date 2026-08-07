import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/incident.dart';
import '../models/guardian.dart';
import '../models/safe_spot_verification.dart';
import '../models/safe_spot_submission.dart';
import '../core/constants/app_constants.dart';
import 'api_client.dart';

/// Supabase Auth initialization plus the backend API adapter.
class SupabaseService {
  final ApiClient _api;
  SupabaseService({ApiClient? api}) : _api = api ?? ApiClient();

  static bool _initialized = false;
  static bool get isConfigured => AppConstants.supabaseUrl.isNotEmpty && AppConstants.supabaseAnonKey.isNotEmpty;
  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (!isConfigured) return;
    await Supabase.initialize(url: AppConstants.supabaseUrl, publishableKey: AppConstants.supabaseAnonKey);
    _initialized = true;
  }

  static Future<void> signOut() async {
    if (!_initialized) return;
    await Supabase.instance.client.auth.signOut();
  }

  /// Syncs an incident to the backend.
  /// Returns the server response map containing [safetyScore] and [riskLevel].
  Future<Map<String, dynamic>> syncIncident(Incident incident) async {
    return _api.post('/incidents/sync', incident.toSyncJson());
  }

  /// Pushes a community safe-spot verification to the backend.
  Future<void> syncSafeSpotVerification(SafeSpotVerification verification) async {
    await _api.post('/safe-spots/verifications', verification.toSyncJson());
  }

  /// Submits a user-suggested safe place for moderation.
  Future<void> syncSafeSpotSubmission(SafeSpotSubmission submission) async {
    await _api.post('/safe-spots/submissions', submission.toSyncJson());
  }

  Future<void> updateUserLocation({
    required String sessionId,
    required double lat,
    required double lng,
    required String clientEventId,
    required DateTime recordedAt,
    double? accuracyM,
  }) async {
    await _api.post('/locations/current', {
      'sessionId': sessionId,
      'clientEventId': clientEventId,
      'latitude': lat,
      'longitude': lng,
      'accuracyM': accuracyM,
      'recordedAt': recordedAt.toUtc().toIso8601String(),
    });
  }

  Future<List<dynamic>> getGuardians() async =>
      (await _api.get('/guardians'))['data'] as List<dynamic>? ?? [];

  Future<Map<String, dynamic>> createGuardian(Map<String, dynamic> body) => _api.post('/guardians', body);

  Future<Map<String, dynamic>> updateGuardian(String id, Map<String, dynamic> body) => _api.patch('/guardians/$id', body);

  Future<Map<String, dynamic>> createSharingSession({required String guardianId, int expiresInHours = 8}) =>
      _api.post('/guardians/$guardianId/sessions', {'guardianId': guardianId, 'expiresInHours': expiresInHours});

  Future<void> stopSharingSession(String sessionId) async {
    await _api.post('/guardians/sessions/$sessionId/stop');
  }

  Future<void> syncLocationBatch(String sessionId, List<LocationUpdate> updates) async {
    await _api.post('/locations/batch', {
      'sessionId': sessionId,
      'events': updates.map((u) => {
        'clientEventId': u.localId,
        'latitude': u.latitude,
        'longitude': u.longitude,
        'recordedAt': u.timestamp.toUtc().toIso8601String(),
      }).toList(),
    });
  }

  Future<Map<String, dynamic>> triggerSos({required double lat, required double lng, required String clientEventId, String? sessionId}) =>
      _api.post('/sos', {'clientEventId': clientEventId, 'latitude': lat, 'longitude': lng, 'sharingSessionId': sessionId});

  /// Reverse-geocode a coordinate via the backend. Returns city and area strings.
  Future<Map<String, dynamic>> reverseGeocode(double lat, double lng) async {
    final result = await _api.get('/geocode/reverse', query: {'lat': lat, 'lng': lng});
    return result['data'] as Map<String, dynamic>? ?? {};
  }

  /// Polls the secure public share endpoint. The token is not a user ID.
  Stream<Map<String, dynamic>> guardianLocationStream(String shareToken) async* {
    while (true) {
      try {
        final payload = await _api.get('/public/shares/$shareToken/location');
        final location = payload['data'] as Map<String, dynamic>?;
        if (location != null) yield location;
      } catch (_) {
        // Temporary network failures do not terminate a guardian watch.
      }
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }
}
