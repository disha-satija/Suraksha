import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Category of a verified real-world safe spot returned by the backend.
enum SafeSpotCategory {
  policeStation,
  hospital,
  fireStation,
  publicSpace,
  metroStation,
  shoppingMall,
  other,
}

extension SafeSpotCategoryX on SafeSpotCategory {
  String get label {
    switch (this) {
      case SafeSpotCategory.policeStation:
        return 'Police Station';
      case SafeSpotCategory.hospital:
        return 'Hospital';
      case SafeSpotCategory.fireStation:
        return 'Fire Station';
      case SafeSpotCategory.publicSpace:
        return 'Public Space';
      case SafeSpotCategory.metroStation:
        return 'Metro Station';
      case SafeSpotCategory.shoppingMall:
        return 'Shopping Mall';
      case SafeSpotCategory.other:
        return 'Safe Spot';
    }
  }

  String get emoji {
    switch (this) {
      case SafeSpotCategory.policeStation:
        return '🚔';
      case SafeSpotCategory.hospital:
        return '🏥';
      case SafeSpotCategory.fireStation:
        return '🚒';
      case SafeSpotCategory.publicSpace:
        return '🌳';
      case SafeSpotCategory.metroStation:
        return '🚇';
      case SafeSpotCategory.shoppingMall:
        return '🏬';
      case SafeSpotCategory.other:
        return '🛡️';
    }
  }

  static SafeSpotCategory fromString(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('police')) return SafeSpotCategory.policeStation;
    if (s.contains('hospital') || s.contains('clinic') || s.contains('medical')) {
      return SafeSpotCategory.hospital;
    }
    if (s.contains('fire')) return SafeSpotCategory.fireStation;
    if (s.contains('metro') || s.contains('station')) {
      return SafeSpotCategory.metroStation;
    }
    if (s.contains('mall') || s.contains('market')) {
      return SafeSpotCategory.shoppingMall;
    }
    if (s.contains('park') || s.contains('public')) {
      return SafeSpotCategory.publicSpace;
    }
    return SafeSpotCategory.other;
  }
}

/// A real-world safe location returned by the backend for a given centre point.
class SafeSpot {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final SafeSpotCategory category;

  /// 0–1 safety relevance score (higher = safer / more relevant).
  final double safetyScore;

  /// Straight-line distance from the query origin in km.
  final double distanceKm;

  /// Short human-readable explanation of why this is a safe spot.
  final String whySafe;

  /// Operating hours or availability note, e.g. "Open 24/7" or "9 AM – 9 PM".
  final String? operatingHours;

  /// Contact number if available.
  final String? contactNumber;

  const SafeSpot({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.category,
    required this.safetyScore,
    required this.distanceKm,
    required this.whySafe,
    this.operatingHours,
    this.contactNumber,
  });

  LatLng get latLng => LatLng(lat, lng);

  factory SafeSpot.fromJson(Map<String, dynamic> json, {double originLat = 0, double originLng = 0}) {
    final lat = (json['lat'] as num?)?.toDouble() ?? originLat;
    final lng = (json['lng'] as num?)?.toDouble() ?? originLng;
    final categoryStr = json['category'] as String? ?? 'other';
    final category = SafeSpotCategoryX.fromString(categoryStr);

    // Always recompute haversine distance from real coordinates —
    // Recompute distance from the returned coordinates rather than trusting
    // a provider's derived value.
    final distKm = (originLat != 0 || originLng != 0)
        ? _haversine(originLat, originLng, lat, lng)
        : (json['distance_km'] as num?)?.toDouble() ?? 0.0;

    return SafeSpot(
      id: json['id'] as String? ?? '${lat}_$lng',
      name: json['name'] as String? ?? category.label,
      address: json['address'] as String? ?? '',
      lat: lat,
      lng: lng,
      category: category,
      safetyScore: (json['safety_score'] as num?)?.toDouble() ?? 0.8,
      distanceKm: distKm,
      whySafe: json['why_safe'] as String? ?? '${category.label} — a designated safe public location.',
      operatingHours: json['operating_hours'] as String?,
      contactNumber: json['contact_number'] as String?,
    );
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.pow(math.sin(dLon / 2), 2);
    return r * 2 * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
  }
}
