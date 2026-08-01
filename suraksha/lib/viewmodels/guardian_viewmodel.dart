import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/guardian.dart';
import '../repositories/guardian_repository.dart';

class GuardianViewModel extends ChangeNotifier {
  final GuardianRepository _guardianRepo;

  GuardianViewModel({
    required GuardianRepository guardianRepo,
    // connectivity kept in constructor signature for DI compatibility
    required dynamic connectivity,
  })  : _guardianRepo = guardianRepo;

  // ── State ─────────────────────────────────────────────────────────────────

  Guardian _guardian = const Guardian(name: '', phone: '');
  bool _isTracking = false;
  LatLng? _lastKnownLocation;
  bool _smsSent = false;
  String? _error;
  StreamSubscription<Map<String, dynamic>>? _locationStreamSub;
  LatLng? _guardianTrackedLocation; // for guardian's view screen

  Guardian get guardian => _guardian;
  bool get isTracking => _isTracking;
  LatLng? get lastKnownLocation => _lastKnownLocation;
  bool get smsSent => _smsSent;
  String? get error => _error;
  LatLng? get guardianTrackedLocation => _guardianTrackedLocation;
  bool get isGuardianConfigured => _guardian.isConfigured;

  // ── Initialize ────────────────────────────────────────────────────────────

  void initialize() {
    _guardian = _guardianRepo.getGuardian();
    notifyListeners();
  }

  // ── Guardian settings ─────────────────────────────────────────────────────

  Future<void> saveGuardian(String name, String phone) async {
    final updated = Guardian(name: name, phone: phone);
    await _guardianRepo.saveGuardian(updated);
    _guardian = updated;
    notifyListeners();
  }

  // ── Location sharing ──────────────────────────────────────────────────────

  Future<void> updateLocation({
    required String userId,
    required double lat,
    required double lng,
    bool triggerSms = false,
  }) async {
    _lastKnownLocation = LatLng(lat, lng);
    _smsSent = false;
    _error = null;

    try {
      await _guardianRepo.updateLocation(
        userId: userId,
        lat: lat,
        lng: lng,
        triggerSmsFallback: triggerSms,
      );

      // smsSent = true whenever SOS was triggered and guardian is configured
      if (triggerSms && _guardian.isConfigured) {
        _smsSent = true;
      }
    } catch (e) {
      _error = 'Location update failed: $e';
    }
    notifyListeners();
  }

  void startTracking() {
    _isTracking = true;
    _smsSent = false;
    notifyListeners();
  }

  void stopTracking() {
    _isTracking = false;
    _locationStreamSub?.cancel();
    notifyListeners();
  }

  /// Guardian's view — subscribe to Realtime stream for tracked user.
  void subscribeToGuardianStream(String trackedUserId) {
    _locationStreamSub?.cancel();
    _locationStreamSub = _guardianRepo
        .guardianLocationStream(trackedUserId)
        .listen((data) {
      if (data.containsKey('latitude') && data.containsKey('longitude')) {
        _guardianTrackedLocation = LatLng(
          (data['latitude'] as num).toDouble(),
          (data['longitude'] as num).toDouble(),
        );
        notifyListeners();
      }
    });
  }

  Future<void> syncOnRestore(String userId) async {
    await _guardianRepo.syncOnConnectivityRestore(userId);
  }

  void clearSmsFlag() {
    _smsSent = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _locationStreamSub?.cancel();
    super.dispose();
  }
}
