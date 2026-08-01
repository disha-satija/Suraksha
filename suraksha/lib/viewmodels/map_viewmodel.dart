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
    final result = _safetyRepo.getScore(
      lat: position.latitude,
      lng: position.longitude,
    );
    _selectedScore = result;

    // Find nearest grid entry for area name
    _selectedEntry = _findNearestGridEntry(position);
    notifyListeners();
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
    final dist = const Distance();
    return grid.reduce((a, b) {
      final da = dist(position, LatLng(a.lat, a.lng));
      final db = dist(position, LatLng(b.lat, b.lng));
      return da < db ? a : b;
    });
  }
}
