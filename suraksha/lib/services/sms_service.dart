import 'package:url_launcher/url_launcher.dart';

/// Sends an SMS alert to the guardian using the phone's native SMS capability.
///
/// iOS behaviour: opens the native Messages compose sheet — the user taps Send.
/// Android behaviour: same tap-to-confirm flow (see note in roadmap about
/// SEND_SMS permission restriction on Play-published apps).
///
/// No paid API, no developer cost — uses the device's own SIM.
class SmsService {
  /// Opens native SMS compose sheet pre-filled with the guardian alert.
  Future<SmsResult> sendGuardianAlert({
    required String guardianPhone,
    required double latitude,
    required double longitude,
    String? userName,
    String? guardianName,
  }) async {
    final senderName = (userName != null && userName.isNotEmpty) ? userName : 'Someone';
    final recipientName = (guardianName != null && guardianName.isNotEmpty) ? guardianName : null;
    final mapsLink = 'https://maps.google.com/?q=$latitude,$longitude';

    final greeting = recipientName != null ? 'Hi $recipientName, ' : '';
    final message =
        '🚨 SOS Alert! ${greeting}$senderName needs immediate help! '
        'Current location: $mapsLink '
        '(Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}) '
        '— Sent via Suraksha';

    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:$guardianPhone?body=$encoded');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return SmsResult.success;
      } else {
        return SmsResult.cannotLaunch;
      }
    } catch (_) {
      return SmsResult.error;
    }
  }
}

enum SmsResult {
  success,
  cannotLaunch,
  error,
}
