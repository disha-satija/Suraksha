import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../models/safety_grid_entry.dart';
import '../repositories/routing_repository.dart';

class RoutingViewModel extends ChangeNotifier {
  final RoutingRepository _routingRepo;

  RoutingViewModel({required RoutingRepository routingRepo})
      : _routingRepo = routingRepo;

  // ── State ─────────────────────────────────────────────────────────────────

  LatLng? _startPoint;
  LatLng? _endPoint;
  List<RouteModel> _routes = [];
  RouteModel? _selectedRoute;
  bool _isLoading = false;
  String? _error;
  bool _hasDeviated = false;
  String _selectedProfile = 'driving';
  List<SafetyGridEntry>? _lastGrid;

  LatLng? get startPoint => _startPoint;
  LatLng? get endPoint => _endPoint;
  List<RouteModel> get routes => _routes;
  RouteModel? get selectedRoute => _selectedRoute;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasDeviated => _hasDeviated;
  String get selectedProfile => _selectedProfile;
  List<DemoRoute> get demoRoutes => _routingRepo.demoRoutes;

  // ── Actions ───────────────────────────────────────────────────────────────

  void setStart(LatLng point) {
    _startPoint = point;
    notifyListeners();
  }

  void setEnd(LatLng point) {
    _endPoint = point;
    notifyListeners();
  }

  void setProfile(String profile) {
    if (_selectedProfile == profile) return;
    _selectedProfile = profile;
    notifyListeners();
    if (_startPoint != null && _endPoint != null && _lastGrid != null) {
      fetchRoutes(_lastGrid!);
    }
  }

  Future<void> fetchRoutes(List<SafetyGridEntry> grid) async {
    if (_startPoint == null || _endPoint == null) return;
    _lastGrid = grid;
    _isLoading = true;
    _error = null;
    _routes = [];
    _selectedRoute = null;
    notifyListeners();

    try {
      _routes = await _routingRepo.getRoutes(
        start: _startPoint!,
        end: _endPoint!,
        grid: grid,
        profile: _selectedProfile,
      );
      if (_routes.isNotEmpty) {
        // Auto-select safest route
        _selectedRoute = _routes.reduce((a, b) =>
            a.safetyScore >= b.safetyScore ? a : b);
      }
    } catch (e) {
      _error = 'Could not fetch routes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectRoute(RouteModel route) {
    _selectedRoute = route;
    notifyListeners();
  }

  void checkDeviation(LatLng currentPosition) {
    if (_selectedRoute == null) return;
    final deviated = _routingRepo.hasDeviated(
      currentPosition,
      _selectedRoute!.polyline,
    );
    if (deviated != _hasDeviated) {
      _hasDeviated = deviated;
      notifyListeners();
    }
  }

  /// Load a pre-cached demo route directly (for offline demo).
  void loadDemoRoute(DemoRoute demo, List<SafetyGridEntry> grid) {
    _startPoint = demo.start;
    _endPoint = demo.end;
    _routes = demo.alternatives.map((route) {
      final xai = _routingRepo.buildExplanation(route.polyline, grid, route.safetyScore);
      return RouteModel(
        id: route.id,
        polyline: route.polyline,
        distanceMeters: route.distanceMeters,
        durationSeconds: route.durationSeconds,
        safetyScore: route.safetyScore,
        riskLevel: route.riskLevel,
        isCached: route.isCached,
        explanation: xai,
      );
    }).toList();
    _selectedRoute = _routes.isNotEmpty
        ? _routes.reduce((a, b) => a.safetyScore >= b.safetyScore ? a : b)
        : null;
    notifyListeners();
  }

  void clear() {
    _startPoint = null;
    _endPoint = null;
    _routes = [];
    _selectedRoute = null;
    _hasDeviated = false;
    notifyListeners();
  }
}
