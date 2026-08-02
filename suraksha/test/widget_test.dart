import 'package:flutter_test/flutter_test.dart';
import 'package:suraksha/models/guardian.dart';
import 'package:suraksha/models/incident.dart';

void main() {
  test('guardian is configured only when both fields are present', () {
    expect(const Guardian(name: 'A', phone: '+919876543210').isConfigured, isTrue);
    expect(const Guardian(name: '', phone: '+919876543210').isConfigured, isFalse);
  });

  test('incident payload matches the backend contract', () {
    final incident = Incident(
      localId: 'event-1',
      latitude: 12.9,
      longitude: 77.6,
      crimeType: 'Harassment',
      description: 'Test report',
      timeOfDay: 'Night',
      reportedAt: DateTime.utc(2026, 1, 1),
      isSynced: false,
    );

    expect(incident.toSupabaseJson(), {
      'clientEventId': 'event-1',
      'latitude': 12.9,
      'longitude': 77.6,
      'crimeType': 'Harassment',
      'description': 'Test report',
      'timeOfDay': 'Night',
      'reportedAt': '2026-01-01T00:00:00.000Z',
    });
  });
}
