import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
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

  Future<void> updateCurrentLocation({bool triggerSms = false}) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw StateError('Location services are disabled');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw StateError('Location permission was not granted');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
      );
      await updateLocation(
        lat: position.latitude,
        lng: position.longitude,
        accuracyM: position.accuracy,
        triggerSms: triggerSms,
      );
    } catch (e) {
      _error = 'Could not get current location: $e';
      notifyListeners();
    }
  }

  Future<void> updateLocation({
    required double lat,
    required double lng,
    double? accuracyM,
    bool triggerSms = false,
  }) async {
    _lastKnownLocation = LatLng(lat, lng);
    _smsSent = false;
    _error = null;

    try {
      await _guardianRepo.updateLocation(
        lat: lat,
        lng: lng,
        accuracyM: accuracyM,
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
  void subscribeToGuardianStream(String shareToken) {
    _locationStreamSub?.cancel();
    _locationStreamSub = _guardianRepo
        .guardianLocationStream(shareToken)
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

  Future<void> syncOnRestore() async {
    await _guardianRepo.syncOnConnectivityRestore();
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
