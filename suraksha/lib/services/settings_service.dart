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
}
