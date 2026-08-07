/// A single community yes/no answer about a safe spot.
///
/// Written locally first, then pushed to the backend — the same outbox pattern
/// used by [Incident].
class SafeSpotVerification {
  final String localId;
  final String spotId;
  final String spotName;
  final String question;
  final bool answer;
  final DateTime answeredAt;
  final bool isSynced;

  const SafeSpotVerification({
    required this.localId,
    required this.spotId,
    required this.spotName,
    required this.question,
    required this.answer,
    required this.answeredAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toSyncJson() => {
        'clientEventId': localId,
        'safeSpotId': spotId,
        'question': question,
        'answer': answer,
        'answeredAt': answeredAt.toUtc().toIso8601String(),
      };
}
