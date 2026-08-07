import '../models/safe_spot_verification.dart';
import '../models/safe_spot_submission.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';

/// Manages community safe-spot verifications — writes locally first,
/// syncs when online. Mirrors [IncidentRepository]'s outbox pattern.
class ContributeRepository {
  final AppDatabase _db;
  final SupabaseService _supabase;
  final ConnectivityService _connectivity;

  /// How long an answered spot stays out of the question pool.
  static const Duration verificationCooldown = Duration(days: 30);

  ContributeRepository({
    required AppDatabase db,
    required SupabaseService supabase,
    required ConnectivityService connectivity,
  })  : _db = db,
        _supabase = supabase,
        _connectivity = connectivity;

  /// Save an answer locally and attempt immediate sync if online.
  Future<void> submitVerification(SafeSpotVerification verification) async {
    await _db.insertVerification(verification);
    if (_connectivity.isOnline) {
      try {
        await _supabase.syncSafeSpotVerification(verification);
        await _db.markVerificationSynced(verification.localId);
      } catch (_) {
        // Leave as unsynced — will retry next time
      }
    }
  }

  /// Spots already answered about within the cooldown window.
  Future<Set<String>> recentlyVerifiedSpotIds() =>
      _db.getVerifiedSpotIdsSince(DateTime.now().subtract(verificationCooldown));

  /// Save a suggested safe place locally and attempt immediate sync if online.
  Future<void> submitSafeSpot(SafeSpotSubmission submission) async {
    await _db.insertSubmission(submission);
    if (_connectivity.isOnline) {
      try {
        await _supabase.syncSafeSpotSubmission(submission);
        await _db.markSubmissionSynced(submission.localId);
      } catch (_) {
        // Leave as unsynced — will retry next time
      }
    }
  }

  /// This device's own suggestions, newest first.
  Future<List<SafeSpotSubmission>> mySubmissions() => _db.getMySubmissions();

  /// Push all unsynced local verifications and submissions to the backend.
  Future<void> syncPending() async {
    final pending = await _db.getUnsyncedVerifications();
    for (final verification in pending) {
      try {
        await _supabase.syncSafeSpotVerification(verification);
        await _db.markVerificationSynced(verification.localId);
      } catch (_) {
        // Leave as unsynced — will retry next time
      }
    }

    final pendingSubmissions = await _db.getUnsyncedSubmissions();
    for (final submission in pendingSubmissions) {
      try {
        await _supabase.syncSafeSpotSubmission(submission);
        await _db.markSubmissionSynced(submission.localId);
      } catch (_) {
        // Leave as unsynced — will retry next time
      }
    }
  }

  /// Call this when connectivity is restored.
  Future<void> syncOnConnectivityRestore() => syncPending();
}
