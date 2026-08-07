import 'package:shared_preferences/shared_preferences.dart';
import '../models/guardian.dart';
import '../core/constants/app_constants.dart';

/// Persists user preferences (guardian info, user name) via SharedPreferences.
class SettingsService {
  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Guardian ──────────────────────────────────────────────────────────────

  Guardian getGuardian() {
    return Guardian(
      name: _prefs.getString(AppConstants.prefGuardianName) ?? '',
      phone: _prefs.getString(AppConstants.prefGuardianPhone) ?? '',
    );
  }

  Future<void> saveGuardian(Guardian guardian) async {
    await _prefs.setString(AppConstants.prefGuardianName, guardian.name);
    await _prefs.setString(AppConstants.prefGuardianPhone, guardian.phone);
  }

  // ── User ──────────────────────────────────────────────────────────────────

  String getUserName() =>
      _prefs.getString(AppConstants.prefUserName) ?? '';

  Future<void> saveUserName(String name) async {
    await _prefs.setString(AppConstants.prefUserName, name);
  }

  String? get guardianId => _prefs.getString(AppConstants.prefGuardianId);
  String? get sharingSessionId => _prefs.getString(AppConstants.prefSharingSessionId);
  String? get shareToken => _prefs.getString(AppConstants.prefShareToken);

  Future<void> saveGuardianBackendState({String? guardianId, String? sessionId, String? shareToken}) async {
    if (guardianId != null) await _prefs.setString(AppConstants.prefGuardianId, guardianId);
    if (sessionId != null) await _prefs.setString(AppConstants.prefSharingSessionId, sessionId);
    if (shareToken != null) await _prefs.setString(AppConstants.prefShareToken, shareToken);
  }

  Future<void> clearSharingSession() async {
    await _prefs.remove(AppConstants.prefSharingSessionId);
    await _prefs.remove(AppConstants.prefShareToken);
  }
}
