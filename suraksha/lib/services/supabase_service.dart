import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/incident.dart';
import '../models/guardian.dart';
import '../core/constants/app_constants.dart';

/// Wraps all Supabase interactions.
/// The app never calls Supabase directly — always goes through this service.
class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  // ── Initialization (called once in main) ─────────────────────────────────

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
    );
  }

  // ── Incidents ─────────────────────────────────────────────────────────────

  Future<void> syncIncident(Incident incident) async {
    await _client.from('incidents').upsert(incident.toSupabaseJson());
  }

  // ── Guardian location sharing ─────────────────────────────────────────────

  /// Upserts user's current location into the `user_locations` table.
  Future<void> updateUserLocation({
    required String userId,
    required double lat,
    required double lng,
  }) async {
    await _client.from('user_locations').upsert({
      'user_id': userId,
      'latitude': lat,
      'longitude': lng,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Returns a Realtime stream of guardian's tracked user's location.
  Stream<Map<String, dynamic>> guardianLocationStream(String userId) {
    return _client
        .from('user_locations')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((rows) => rows.isNotEmpty ? rows.first : {});
  }

  /// Syncs a batch of location updates (offline queue flush).
  Future<void> syncLocationBatch(List<LocationUpdate> updates) async {
    final rows = updates.map((u) => u.toSupabaseJson()).toList();
    await _client.from('location_history').insert(rows);
  }
}
