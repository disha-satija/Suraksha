import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../viewmodels/routing_viewmodel.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/safety_score_card.dart';
import 'incident_screen.dart';
import 'routing_screen.dart';
import 'settings_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapViewModel>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      body: Consumer<MapViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              // ── Map ────────────────────────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(
                    AppConstants.demoDefaultLat,
                    AppConstants.demoDefaultLng,
                  ),
                  initialZoom: AppConstants.demoDefaultZoom,
                  onTap: (tapPos, latLng) {
                    vm.onMapTap(latLng);
                  },
                ),
                children: [
                  // Tile layer — online OSM or cached
                  TileLayer(
                    urlTemplate: AppConstants.onlineTileUrl,
                    userAgentPackageName: 'com.suraksha.app',
                    fallbackUrl:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),

                  // Safety grid overlay
                  if (vm.grid.isNotEmpty)
                    CircleLayer(
                      circles: vm.grid
                          .map((entry) => CircleMarker(
                                point: LatLng(entry.lat, entry.lng),
                                radius: 600,
                                useRadiusInMeter: true,
                                color: AppColors.forScore(entry.avgSafetyScore)
                                    .withValues(alpha: 0.25),
                                borderColor: AppColors.forScore(
                                    entry.avgSafetyScore),
                                borderStrokeWidth: 1.5,
                              ))
                          .toList(),
                    ),

                  // Route overlay from routing viewmodel
                  Consumer<RoutingViewModel>(
                    builder: (context, routingVm, _) {
                      if (routingVm.routes.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return PolylineLayer(
                        polylines: routingVm.routes.map((route) {
                          final isSelected =
                              routingVm.selectedRoute?.id == route.id;
                          return Polyline(
                            points: route.polyline,
                            strokeWidth: isSelected ? 5 : 3,
                            color: isSelected
                                ? AppColors.forScore(route.safetyScore)
                                : AppColors.forScore(route.safetyScore)
                                    .withValues(alpha: 0.4),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  // Selected location marker
                  if (vm.selectedScore != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: vm.center,
                          width: 36,
                          height: 36,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.forScore(vm.selectedScore!.score),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                    blurRadius: 4, color: Colors.black38)
                              ],
                            ),
                            child: const Icon(Icons.location_pin,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // ── Connectivity banner ────────────────────────────────────────
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: ConnectivityBanner(),
                ),
              ),

              // ── Zoom controls ──────────────────────────────────────────────
              Positioned(
                right: 12,
                bottom: 120,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ZoomButton(
                      icon: Icons.add,
                      onTap: () {
                        final current = _mapController.camera.zoom;
                        _mapController.move(
                            _mapController.camera.center, current + 1);
                      },
                    ),
                    const SizedBox(height: 4),
                    _ZoomButton(
                      icon: Icons.remove,
                      onTap: () {
                        final current = _mapController.camera.zoom;
                        _mapController.move(
                            _mapController.camera.center, current - 1);
                      },
                    ),
                  ],
                ),
              ),

              // ── Top bar ────────────────────────────────────────────────────
              Positioned(
                top: 40,
                left: 12,
                right: 12,
                child: SafeArea(
                  child: Row(
                    children: [
                      Builder(
                        builder: (ctx) => _MapIconButton(
                          icon: Icons.menu,
                          onTap: () => Scaffold.of(ctx).openDrawer(),
                        ),
                      ),
                      const Spacer(),
                      _MapIconButton(
                        icon: Icons.directions,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RoutingScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Safety score bottom sheet ──────────────────────────────────
              if (vm.selectedScore != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafetyScoreCard(
                    result: vm.selectedScore!,
                    gridEntry: vm.selectedEntry,
                    onClose: vm.clearSelection,
                    onReportIncident: () {
                      vm.clearSelection();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IncidentScreen(
                            latitude: vm.center.latitude,
                            longitude: vm.center.longitude,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // ── Error snackbar trigger ─────────────────────────────────────
              if (vm.error != null)
                Positioned(
                  bottom: 80,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: Colors.red[700],
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Text(
                        vm.error!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Suraksha',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Women Safety Navigator',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            _DrawerItem(
              icon: Icons.map_outlined,
              label: 'Safety Map',
              onTap: () => Navigator.pop(context),
            ),
            _DrawerItem(
              icon: Icons.directions_outlined,
              label: 'Safe Routing',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RoutingScreen()),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.people_outline,
              label: 'Guardian Mode',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/guardian');
              },
            ),
            _DrawerItem(
              icon: Icons.report_problem_outlined,
              label: 'Report Incident',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IncidentScreen(
                      latitude: AppConstants.demoDefaultLat,
                      longitude: AppConstants.demoDefaultLng,
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      onTap: onTap,
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}
