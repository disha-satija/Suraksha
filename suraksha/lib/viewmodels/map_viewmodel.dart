import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/safety_grid_entry.dart';
import '../models/safety_score_result.dart';
import '../models/connectivity_state.dart';
import '../repositories/safety_repository.dart';
import '../services/connectivity_service.dart';
import '../core/constants/app_constants.dart';

class MapViewModel extends ChangeNotifier {
  final SafetyRepository _safetyRepo;
  final ConnectivityService _connectivity;

  MapViewModel({
    required SafetyRepository safetyRepo,
    required ConnectivityService connectivity,
  })  : _safetyRepo = safetyRepo,
        _connectivity = connectivity;

  // ── State ─────────────────────────────────────────────────────────────────

  LatLng _center = const LatLng(
    AppConstants.demoDefaultLat,
    AppConstants.demoDefaultLng,
  );
  double _zoom = AppConstants.demoDefaultZoom;
  SafetyScoreResult? _selectedScore;
  SafetyGridEntry? _selectedEntry;
  bool _isLoading = false;
  String? _error;
  SafetyScoreResult? _areaScore;
  bool _isFetchingAreaScore = false;

  LatLng get center => _center;
  double get zoom => _zoom;
  SafetyScoreResult? get selectedScore => _selectedScore;
  SafetyGridEntry? get selectedEntry => _selectedEntry;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SafetyScoreResult? get areaScore => _areaScore;
  List<SafetyGridEntry> get grid => _safetyRepo.grid;
  ConnectivityStatus get connectivityStatus => _connectivity.currentStatus;

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _safetyRepo.initialize();
      _error = null;
    } catch (e) {
      // Non-fatal — grid may still be loaded even if ONNX failed
      _error = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void onMapTap(LatLng position) {
    _center = position;

    // Offline-only path: a map tap must stay synchronous. The repository runs
    // its own nearest-area lookup and applies the distance gate.
    _selectedEntry = _findNearestGridEntry(position);
    _selectedScore = _safetyRepo.getScore(
      lat: position.latitude,
      lng: position.longitude,
      timeOfDay: _currentTimeOfDay(),
      weatherCondition: 'Clear', // no weather API wired up; default is safe
    );
    notifyListeners();
  }

  /// Scores the area the user is currently in, for the home dashboard.
  /// Independent of [selectedScore], which tracks map selection.
  ///
  /// Async because it prefers the backend when online: that is what surfaces
  /// community-reported incidents, and what supplies a validated AI estimate
  /// for locations the trained grid does not cover. Falls back to local data.
  Future<void> refreshAreaScore(LatLng position) async {
    // HomeScreen retries this on every rebuild while [areaScore] is still null.
    // Without this guard the awaited network call would be fired once per
    // frame until the first one returned.
    if (_isFetchingAreaScore) return;
    _isFetchingAreaScore = true;
    try {
      _areaScore = await _safetyRepo.getAreaScore(
        lat: position.latitude,
        lng: position.longitude,
        timeOfDay: _currentTimeOfDay(),
        weatherCondition: 'Clear',
      );
    } finally {
      _isFetchingAreaScore = false;
    }
    notifyListeners();
  }

  /// Maps the current hour to one of the five ONNX time-of-day categories.
  String _currentTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 20) return 'Evening';
    if (hour >= 20 && hour < 23) return 'Night';
    return 'Late Night';
  }

  void moveCamera(LatLng position, {double? zoom}) {
    _center = position;
    if (zoom != null) _zoom = zoom;
    notifyListeners();
  }

  void clearSelection() {
    _selectedScore = null;
    _selectedEntry = null;
    notifyListeners();
  }

  SafetyGridEntry? _findNearestGridEntry(LatLng position) {
    if (grid.isEmpty) return null;
    const dist = Distance();
    return grid.reduce((a, b) {
      final da = dist(position, LatLng(a.lat, a.lng));
      final db = dist(position, LatLng(b.lat, b.lng));
      return da < db ? a : b;
    });
  }
}
