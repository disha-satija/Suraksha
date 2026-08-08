import 'package:flutter/foundation.dart';
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

  /// Save an answer locally and attempt immediate sync.
  Future<void> submitVerification(SafeSpotVerification verification) async {
    await _db.insertVerification(verification);
    try {
      await _supabase.syncSafeSpotVerification(verification);
      await _db.markVerificationSynced(verification.localId);
    } catch (_) {
      // Leave as unsynced — will retry on syncPending()
    }
  }

  /// Spots already answered about within the cooldown window.
  Future<Set<String>> recentlyVerifiedSpotIds() =>
      _db.getVerifiedSpotIdsSince(DateTime.now().subtract(verificationCooldown));

  /// Save a suggested safe place locally and attempt immediate sync.
  ///
  /// Throws only if the local outbox write fails. That is a genuine defect, not
  /// an offline condition, and it must not be confused with "queued for later":
  /// a failure here means the suggestion is gone. A failed *sync*, by contrast,
  /// is expected and simply leaves the row queued.
  Future<void> submitSafeSpot(SafeSpotSubmission submission) async {
    try {
      await _db.insertSubmission(submission);
    } catch (e, stack) {
      debugPrint('[ContributeRepo] LOCAL WRITE FAILED for ${submission.localId} — '
          'suggestion not stored anywhere: $e');
      debugPrintStack(stackTrace: stack, maxFrames: 6);
      rethrow;
    }

    try {
      await _supabase.syncSafeSpotSubmission(submission);
      await _db.markSubmissionSynced(submission.localId);
      debugPrint('[ContributeRepo] synced submission ${submission.localId}');
    } catch (e) {
      // Offline or API unreachable — the row stays queued for syncPending().
      debugPrint('[ContributeRepo] sync deferred for ${submission.localId}: $e');
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
    if (pendingSubmissions.isNotEmpty) {
      debugPrint('[ContributeRepo] ${pendingSubmissions.length} submission(s) pending sync');
    }
    for (final submission in pendingSubmissions) {
      try {
        await _supabase.syncSafeSpotSubmission(submission);
        await _db.markSubmissionSynced(submission.localId);
        debugPrint('[ContributeRepo] synced submission ${submission.localId}');
      } catch (e) {
        debugPrint('[ContributeRepo] retry failed for ${submission.localId}: $e');
      }
    }
  }

  /// Call this when connectivity is restored.
  Future<void> syncOnConnectivityRestore() => syncPending();
}
