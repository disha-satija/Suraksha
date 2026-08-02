import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../viewmodels/routing_viewmodel.dart';
import '../../viewmodels/safe_spot_viewmodel.dart';
import '../../models/safe_spot.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/connectivity_banner.dart';
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
  final TextEditingController _searchController = TextEditingController();
  bool _searchBarVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapViewModel>().initialize();
      context.read<SafeSpotViewModel>().initLocation();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Animate camera to a latlng ─────────────────────────────────────────────
  void _moveTo(LatLng pos, {double zoom = 14}) {
    _mapController.move(pos, zoom);
  }

  // ── Open Google Maps to a destination from current location ───────────────
  Future<void> _openGoogleMapsTo(SafeSpot spot) async {
    final ssVm = context.read<SafeSpotViewModel>();
    final origin = ssVm.currentLocation;
    final uri = origin != null
        ? Uri.parse(
            'https://www.google.com/maps/dir/?api=1'
            '&origin=${origin.latitude},${origin.longitude}'
            '&destination=${spot.lat},${spot.lng}'
            '&travelmode=walking',
          )
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1'
            '&query=${spot.lat},${spot.lng}',
          );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      body: Consumer2<MapViewModel, SafeSpotViewModel>(
        builder: (context, vm, ssVm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              // ── Map ──────────────────────────────────────────────────────
              _buildMap(vm, ssVm),

              // ── Connectivity banner ──────────────────────────────────────
              const Positioned(
                top: 0, left: 0, right: 0,
                child: SafeArea(child: ConnectivityBanner()),
              ),

              // ── Top bar: menu + location search ─────────────────────────
              _buildTopBar(context, ssVm),

              // ── Location search bar (expanded) ───────────────────────────
              if (_searchBarVisible) _buildSearchBar(context, ssVm),

              // ── Safe spot loading indicator ──────────────────────────────
              if (ssVm.isLoading)
                const Positioned(
                  top: 110, left: 0, right: 0,
                  child: Center(
                    child: _LoadingPill(label: 'Finding safe spots…'),
                  ),
                ),

              // ── Zoom controls ────────────────────────────────────────────
              Positioned(
                right: 12,
                bottom: ssVm.selectedSpot != null ? 320 : 120,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ZoomButton(
                      icon: Icons.add,
                      onTap: () => _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _ZoomButton(
                      icon: Icons.remove,
                      onTap: () => _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      ),
                    ),
                  ],
                ),
              ),

              // Safety score card removed — map tap no longer triggers it

              // ── Safe spot detail card ─────────────────────────────────────
              if (ssVm.selectedSpot != null)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: _SafeSpotCard(
                    spot: ssVm.selectedSpot!,
                    onClose: ssVm.clearSelection,
                    onNavigate: () => _openGoogleMapsTo(ssVm.selectedSpot!),
                    onInAppRoute: () {
                      final origin = ssVm.currentLocation;
                      if (origin == null) return;
                      final routingVm = context.read<RoutingViewModel>();
                      routingVm.setStart(origin);
                      routingVm.setEnd(ssVm.selectedSpot!.latLng);
                      routingVm.fetchRoutes(vm.grid);
                      ssVm.clearSelection();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RoutingScreen(),
                        ),
                      );
                    },
                  ),
                ),

              // ── Error snackbar ────────────────────────────────────────────
              if (vm.error != null)
                Positioned(
                  bottom: 80, left: 16, right: 16,
                  child: Material(
                    color: Colors.red[700],
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Text(vm.error!,
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Map layer builder ─────────────────────────────────────────────────────
  Widget _buildMap(MapViewModel vm, SafeSpotViewModel ssVm) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(
          vm.center.latitude,
          vm.center.longitude,
        ),
        initialZoom: AppConstants.demoDefaultZoom,
        onTap: (_, latLng) {
          ssVm.clearSelection();
          // Map tap only clears selection — no score card popup
        },
      ),
      children: [
        TileLayer(
          urlTemplate: AppConstants.onlineTileUrl,
          userAgentPackageName: 'com.suraksha.app',
          fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),

        // Safety grid circles — hidden, data still available for routing scoring
        // (removed from map display per user request)

        // Route polylines
        Consumer<RoutingViewModel>(
          builder: (_, routingVm, __) {
            if (routingVm.routes.isEmpty) return const SizedBox.shrink();
            return PolylineLayer(
              polylines: routingVm.routes.map((route) {
                final isSelected = routingVm.selectedRoute?.id == route.id;
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

        // ── Green shield markers for safe spots ──────────────────────────
        if (ssVm.safeSpots.isNotEmpty)
          MarkerLayer(
            markers: ssVm.safeSpots.map((spot) {
              final isSelected = ssVm.selectedSpot?.id == spot.id;
              final isNearest = ssVm.nearestSpot?.id == spot.id;
              return Marker(
                point: spot.latLng,
                width: isSelected ? 52 : (isNearest ? 48 : 42),
                height: isSelected ? 52 : (isNearest ? 48 : 42),
                child: GestureDetector(
                  onTap: () {
                    vm.clearSelection();
                    ssVm.selectSpot(spot);
                    _moveTo(spot.latLng, zoom: 15);
                  },
                  child: _ShieldMarker(
                    spot: spot,
                    isSelected: isSelected,
                    isNearest: isNearest,
                  ),
                ),
              );
            }).toList(),
          ),

        // Current location blue dot
        if (ssVm.currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: ssVm.currentLocation!,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: const [
                      BoxShadow(blurRadius: 6, color: Colors.black38),
                    ],
                  ),
                ),
              ),
            ],
          ),

        // Map-tap score marker removed
      ],
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, SafeSpotViewModel ssVm) {
    return Positioned(
      top: 40, left: 12, right: 12,
      child: SafeArea(
        child: Row(
          children: [
            // Hamburger
            Builder(
              builder: (ctx) => _MapIconButton(
                icon: Icons.menu,
                onTap: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            const SizedBox(width: 8),

            // Location chip / search trigger
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _searchBarVisible = !_searchBarVisible),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(blurRadius: 4, color: Color(0x14000000)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        ssVm.locationState == LocationState.granted
                            ? Icons.my_location
                            : Icons.search,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ssVm.locationState == LocationState.requesting
                              ? 'Getting location…'
                              : ssVm.locationState == LocationState.searching
                                  ? 'Searching…'
                                  : ssVm.locationLabel.isNotEmpty
                                      ? ssVm.locationLabel
                                      : 'Search location for safe spots',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: ssVm.locationLabel.isNotEmpty
                                ? AppColors.onSurface
                                : AppColors.hint,
                          ),
                        ),
                      ),
                      if (ssVm.locationState == LocationState.granted &&
                          ssVm.safeSpots.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${ssVm.safeSpots.length}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Directions button
            _MapIconButton(
              icon: Icons.directions,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RoutingScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Expanded search bar with live suggestions ────────────────────────────
  Widget _buildSearchBar(BuildContext context, SafeSpotViewModel ssVm) {
    return Positioned(
      top: 100, left: 12, right: 12,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 14),
                onChanged: (q) {
                  ssVm.updateSearchQuery(q);
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Search area or city…',
                  hintStyle:
                      const TextStyle(fontSize: 13, color: Colors.black38),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      ssVm.updateSearchQuery('');
                      setState(() => _searchBarVisible = false);
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                ),
                onSubmitted: (query) {
                  ssVm.updateSearchQuery('');
                  setState(() => _searchBarVisible = false);
                  if (query.trim().isNotEmpty) {
                    ssVm.searchLocation(query.trim()).then((_) {
                      if (ssVm.currentLocation != null) {
                        _moveTo(ssVm.currentLocation!, zoom: 13);
                      }
                    });
                  }
                },
              ),
            ),
            // Live suggestion list
            if (ssVm.searchSuggestions.isNotEmpty)
              Material(
                elevation: 4,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12)),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(12)),
                  ),
                  child: ssVm.isSuggestionsLoading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2)),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: ssVm.searchSuggestions.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey[100]),
                          itemBuilder: (ctx, i) {
                            final s = ssVm.searchSuggestions[i];
                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                  Icons.location_on_outlined,
                                  color: AppColors.primary,
                                  size: 18),
                              title: Text(s.label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13)),
                              onTap: () {
                                _searchController.text = s.label;
                                ssVm.updateSearchQuery('');
                                setState(() => _searchBarVisible = false);
                                ssVm
                                    .setLocationFromCoords(
                                        LatLng(s.lat, s.lng),
                                        label: s.label)
                                    .then((_) =>
                                        _moveTo(LatLng(s.lat, s.lng),
                                            zoom: 13));
                              },
                            );
                          },
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Safe spot list bottom sheet ───────────────────────────────────────────
  void _showSafeSpotListSheet(
      BuildContext context, SafeSpotViewModel ssVm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(blurRadius: 20, color: Colors.black26),
            ],
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.shield,
                        color: AppColors.safeGreen, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Safe Spots Nearby',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '${ssVm.safeSpots.length} found',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Sorted by distance · tap to navigate',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              // List
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: ssVm.safeSpots.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey[100]),
                  itemBuilder: (ctx, i) {
                    final spot = ssVm.safeSpots[i];
                    final isNearest = ssVm.nearestSpot?.id == spot.id;
                    return ListTile(
                      leading: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.safeGreen
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(spot.category.emoji,
                                  style:
                                      const TextStyle(fontSize: 20)),
                            ),
                          ),
                          if (isNearest)
                            Positioned(
                              top: -4, right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF9A825),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.star,
                                    size: 10, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        spot.name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            spot.category.label,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.safeGreen,
                                fontWeight: FontWeight.w600),
                          ),
                          if (spot.address.isNotEmpty)
                            Text(
                              spot.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black45),
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${spot.distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.safeGreen),
                          ),
                          Text(
                            '${(spot.safetyScore * 100).toStringAsFixed(0)}% safe',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context); // close sheet
                        ssVm.selectSpot(spot);
                        _moveTo(spot.latLng, zoom: 15);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Drawer ────────────────────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suraksha',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Women Safety Navigator',
                    style: TextStyle(
                        color: AppColors.subtitle, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 4),

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
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RoutingScreen()));
              },
            ),

            // ── Nearest Safe Spot ──────────────────────────────────────────
            Consumer<SafeSpotViewModel>(
              builder: (ctx, ssVm, _) {
                final nearest = ssVm.nearestSpot;
                return _DrawerItem(
                  icon: Icons.shield_outlined,
                  label: 'Nearest Safe Spot',
                  iconColor: AppColors.safeGreen,
                  badge: nearest != null
                      ? '${nearest.distanceKm.toStringAsFixed(1)} km'
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (ssVm.safeSpots.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Set your location first to find safe spots.'),
                          backgroundColor: AppColors.warningAmber,
                        ),
                      );
                      return;
                    }
                    _showSafeSpotListSheet(context, ssVm);
                  },
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
                final current = context.read<SafeSpotViewModel>().currentLocation ??
                    context.read<MapViewModel>().center;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IncidentScreen(
                      latitude: current.latitude,
                      longitude: current.longitude,
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
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Green Shield Marker ────────────────────────────────────────────────────────

class _ShieldMarker extends StatelessWidget {
  final SafeSpot spot;
  final bool isSelected;
  final bool isNearest;

  const _ShieldMarker({
    required this.spot,
    required this.isSelected,
    required this.isNearest,
  });

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 48.0 : (isNearest ? 44.0 : 38.0);
    final bgColor = isSelected
        ? AppColors.primary
        : isNearest
            ? AppColors.primaryDark
            : AppColors.safeGreen;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: isSelected ? 2.5 : 2),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: isSelected ? 24 : (isNearest ? 20 : 18),
            ),
          ),
        ),
        if (isNearest && !isSelected)
          Positioned(
            top: -7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.warningAmber,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'NEAREST',
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Safe Spot Detail Card ──────────────────────────────────────────────────────

class _SafeSpotCard extends StatelessWidget {
  final SafeSpot spot;
  final VoidCallback onClose;
  final VoidCallback onNavigate;
  final VoidCallback onInAppRoute;

  const _SafeSpotCard({
    required this.spot,
    required this.onClose,
    required this.onNavigate,
    required this.onInAppRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [BoxShadow(blurRadius: 12, color: Color(0x1A000000), offset: Offset(0, -2))],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle + close
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: 32, height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, size: 18, color: AppColors.subtitle),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category chip + name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    spot.category.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      spot.category.label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                    if (spot.address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        spot.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.subtitle),
                      ),
                    ],
                  ],
                ),
              ),
              // Safety score badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.safeGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.safeGreen.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${(spot.safetyScore * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                          color: AppColors.safeGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${spot.distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 11, color: AppColors.subtitle),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Why safe
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined,
                  color: AppColors.safeGreen, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  spot.whySafe,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.subtitle,
                      height: 1.5),
                ),
              ),
            ],
          ),

          // Hours + contact
          if (spot.operatingHours != null || spot.contactNumber != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (spot.operatingHours != null) ...[
                  const Icon(Icons.access_time_outlined,
                      size: 12, color: AppColors.hint),
                  const SizedBox(width: 4),
                  Text(spot.operatingHours!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.hint)),
                ],
                if (spot.operatingHours != null && spot.contactNumber != null)
                  const SizedBox(width: 14),
                if (spot.contactNumber != null) ...[
                  const Icon(Icons.phone_outlined,
                      size: 12, color: AppColors.hint),
                  const SizedBox(width: 4),
                  Text(spot.contactNumber!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.hint)),
                ],
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onInAppRoute,
                  icon: const Icon(Icons.alt_route_outlined, size: 15),
                  label: const Text('Safe Route'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation_outlined, size: 15),
                  label: const Text('Open in Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Loading pill ───────────────────────────────────────────────────────────────

class _LoadingPill extends StatelessWidget {
  final String label;
  const _LoadingPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(blurRadius: 4, color: Color(0x14000000)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 13, height: 13,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Shared small widgets ───────────────────────────────────────────────────────

class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(blurRadius: 4, color: Color(0x14000000)),
          ],
        ),
        child: Icon(icon, color: AppColors.onSurface, size: 18),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final String? badge;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon,
          color: iconColor ?? AppColors.subtitle, size: 18),
      title: Text(
        label,
        style: const TextStyle(
            fontSize: 14,
            color: AppColors.onSurface,
            fontWeight: FontWeight.w500),
      ),
      trailing: badge != null
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600),
              ),
            )
          : null,
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
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 4),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.onSurface),
      ),
    );
  }
}
