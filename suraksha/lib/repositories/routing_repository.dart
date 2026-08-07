import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../models/safety_grid_entry.dart';
import '../services/routing_service.dart';
import '../services/connectivity_service.dart';

/// Fetches routes — online via OSRM, offline from pre-cached demo routes.
class RoutingRepository {
  final RoutingService _routingService;
  final ConnectivityService _connectivity;

  RoutingRepository({
    required RoutingService routingService,
    required ConnectivityService connectivity,
  })  : _routingService = routingService,
        _connectivity = connectivity;

  List<DemoRoute> get demoRoutes => _routingService.cachedDemoRoutes;

  /// Returns routes for start → end.
  /// Online → live OSRM with safety scoring.
  /// Offline → nearest pre-cached demo route alternatives.
  Future<List<RouteModel>> getRoutes({
    required LatLng start,
    required LatLng end,
    required List<SafetyGridEntry> grid,
    String profile = 'driving',
  }) async {
    if (_connectivity.isOnline) {
      try {
        return await _routingService.fetchOnlineRoutes(
          start: start,
          end: end,
          grid: grid,
          profile: profile,
        );
      } catch (_) {
        // Fall through to cached
      }
    }

    final cached = _routingService.findNearestCachedRoute(start, end);
    if (cached == null) return [];

    // Compute real XAI from the actual safety grid for every cached alternative
    return cached.alternatives.map((route) {
      final xai = _routingService.buildExplanationForRoute(
        route.polyline,
        grid,
        route.safetyScore,
      );
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
  }

  bool hasDeviated(LatLng currentPosition, List<LatLng> plannedPolyline) {
    return _routingService.hasDeviated(currentPosition, plannedPolyline);
  }

  RouteExplanation buildExplanation(List<LatLng> polyline, List<SafetyGridEntry> grid, double score) {
    return _routingService.buildExplanationForRoute(polyline, grid, score);
  }
}
