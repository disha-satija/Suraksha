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

  LatLng get center => _center;
  double get zoom => _zoom;
  SafetyScoreResult? get selectedScore => _selectedScore;
  SafetyGridEntry? get selectedEntry => _selectedEntry;
  bool get isLoading => _isLoading;
  String? get error => _error;
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

    // Find nearest grid entry first so we can pass its features to ONNX.
    _selectedEntry = _findNearestGridEntry(position);
    final entry = _selectedEntry;

    _selectedScore = _safetyRepo.getScore(
      lat: position.latitude,
      lng: position.longitude,
      // Pass grid cell features so ONNX inference fires (safety_repository.dart:51-55
      // requires all four non-null to use the model rather than the grid fallback).
      lightingScore: entry?.avgLighting,
      policeDistanceKm: entry?.avgPoliceDist,
      crowdDensity: entry?.avgCrowd,
      crimeCount: entry?.avgCrimeCount,
      timeOfDay: _currentTimeOfDay(),
      weatherCondition: 'Clear', // no weather API wired up; default is safe
    );
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
