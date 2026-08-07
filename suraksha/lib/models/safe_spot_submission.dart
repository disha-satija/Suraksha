/// A user-suggested safe place awaiting moderation.
///
/// Stored locally first and synced when a backend is reachable. A submission is
/// never shown to other users until it comes back approved — this device only
/// ever sees its own pending suggestions.
class SafeSpotSubmission {
  final String localId;
  final String name;
  final String category;
  final String address;
  final double lat;
  final double lng;
  final String whySafe;
  final DateTime submittedAt;

  /// 'pending' | 'approved' | 'rejected' — set by the backend on review.
  final String status;
  final bool isSynced;

  const SafeSpotSubmission({
    required this.localId,
    required this.name,
    required this.category,
    required this.address,
    required this.lat,
    required this.lng,
    required this.whySafe,
    required this.submittedAt,
    this.status = 'pending',
    this.isSynced = false,
  });

  Map<String, dynamic> toSyncJson() => {
        'clientEventId': localId,
        'name': name,
        'category': category,
        'address': address,
        'latitude': lat,
        'longitude': lng,
        'whySafe': whySafe,
        'submittedAt': submittedAt.toUtc().toIso8601String(),
      };
}
