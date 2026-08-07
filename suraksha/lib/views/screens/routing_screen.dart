import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../viewmodels/routing_viewmodel.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../models/route_model.dart';
import '../../core/constants/app_colors.dart';
import '../../services/api_client.dart';
import '../widgets/connectivity_banner.dart';

// ── Data class for a location suggestion ──────────────────────────────────────

class _LocationSuggestion {
  final String label;
  final double lat;
  final double lng;
  final bool isGridEntry; // true = from local grid, false = from Nominatim

  const _LocationSuggestion({
    required this.label,
    required this.lat,
    required this.lng,
    required this.isGridEntry,
  });
}

// ── Main routing screen ───────────────────────────────────────────────────────

class RoutingScreen extends StatefulWidget {
  const RoutingScreen({super.key});

  @override
  State<RoutingScreen> createState() => _RoutingScreenState();
}

class _RoutingScreenState extends State<RoutingScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final FocusNode _fromFocus = FocusNode();
  final FocusNode _toFocus = FocusNode();

  List<_LocationSuggestion> _suggestions = [];
  bool _searchingFrom = true;
  bool _loadingSuggestions = false;
  final ApiClient _api = ApiClient();

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  // ── Suggestion search ─────────────────────────────────────────────────────

  Future<void> _onSearchChanged(String query, bool isFrom) async {
    setState(() => _searchingFrom = isFrom);
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    final mapVm = context.read<MapViewModel>();
    setState(() => _loadingSuggestions = true);

    final results = <_LocationSuggestion>[];

    // 1. Backend geocoding (online search — primary accurate results)
    try {
      final payload = await _api.get('/geocode/search', query: {'q': '$query, India', 'limit': 4});
      final data = payload['data'] as List<dynamic>? ?? [];
      for (final raw in data) {
        final item = Map<String, dynamic>.from(raw as Map);
        results.add(_LocationSuggestion(
          label: item['label'] as String,
          lat: (item['lat'] as num).toDouble(),
          lng: (item['lng'] as num).toDouble(),
          isGridEntry: false,
        ));
      }
    } catch (_) {
      // Offline or timed out — local results only
    }

    // 2. Local grid matches (fallback — offline-safe)
    for (final entry in mapVm.grid) {
      final name = '${entry.area}, ${entry.city}';
      if (name.toLowerCase().contains(query.toLowerCase())) {
        results.add(_LocationSuggestion(
          label: name,
          lat: entry.lat,
          lng: entry.lng,
          isGridEntry: true,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _suggestions = results.take(6).toList();
        _loadingSuggestions = false;
      });
    }
  }

  void _selectSuggestion(_LocationSuggestion s, RoutingViewModel vm) {
    if (_searchingFrom) {
      _fromController.text = s.label;
      vm.setStart(LatLng(s.lat, s.lng));
    } else {
      _toController.text = s.label;
      vm.setEnd(LatLng(s.lat, s.lng));
    }
    setState(() => _suggestions = []);
    FocusScope.of(context).unfocus();

    // Auto-fetch routes if both points are set
    final mapVm = context.read<MapViewModel>();
    if (vm.startPoint != null && vm.endPoint != null) {
      vm.fetchRoutes(mapVm.grid);
    }
  }

  /// Opens Google Maps with turn-by-turn directions for the selected route.
  Future<void> _launchGoogleMaps(RoutingViewModel vm) async {
    final start = vm.startPoint;
    final end = vm.endPoint;
    if (start == null || end == null) return;

    // Google Maps directions URL — opens the native app if installed,
    // falls back to maps.google.com in browser
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${start.latitude},${start.longitude}'
      '&destination=${end.latitude},${end.longitude}'
      '&travelmode=driving',
    );

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Install a browser or Google Maps to open directions.'),
            backgroundColor: AppColors.warningAmber,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps.'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Safe Routing'),
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 40,
        // The app-wide AppBarTheme sets an explicit black titleTextStyle, which
        // wins over foregroundColor — so the title has to be restated here to
        // read white on the red bar.
        titleTextStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(24),
          child: ConnectivityBanner(),
        ),
      ),
      body: Consumer2<RoutingViewModel, MapViewModel>(
        builder: (context, routingVm, mapVm, _) {
          final hasSelectedRoute = routingVm.selectedRoute != null;

          return Stack(
            children: [
              Column(
                children: [
                  // ── Search panel ───────────────────────────────────────
                  _SearchPanel(
                    fromController: _fromController,
                    toController: _toController,
                    fromFocus: _fromFocus,
                    toFocus: _toFocus,
                    selectedProfile: routingVm.selectedProfile,
                    onProfileChanged: (p) => routingVm.setProfile(p),
                    onFromChanged: (q) => _onSearchChanged(q, true),
                    onToChanged: (q) => _onSearchChanged(q, false),
                    onFromTap: () => setState(() {
                      _searchingFrom = true;
                      _suggestions = [];
                    }),
                    onToTap: () => setState(() {
                      _searchingFrom = false;
                      _suggestions = [];
                    }),
                    onSwap: () {
                      final fromText = _fromController.text;
                      _fromController.text = _toController.text;
                      _toController.text = fromText;
                      final start = routingVm.startPoint;
                      final end = routingVm.endPoint;
                      if (start != null) routingVm.setEnd(start);
                      if (end != null) routingVm.setStart(end);
                      if (routingVm.startPoint != null &&
                          routingVm.endPoint != null) {
                        routingVm.fetchRoutes(mapVm.grid);
                      }
                    },
                    onSearch: () {
                      FocusScope.of(context).unfocus();
                      setState(() => _suggestions = []);
                      if (routingVm.startPoint != null &&
                          routingVm.endPoint != null) {
                        routingVm.fetchRoutes(mapVm.grid);
                      }
                    },
                  ),

                  // ── Suggestion dropdown ────────────────────────────────
                  if (_suggestions.isNotEmpty || _loadingSuggestions)
                    _SuggestionList(
                      suggestions: _suggestions,
                      isLoading: _loadingSuggestions,
                      onSelect: (s) => _selectSuggestion(s, routingVm),
                    ),

                  // ── Demo route chips ───────────────────────────────────
                  if (_suggestions.isEmpty &&
                      !_loadingSuggestions &&
                      routingVm.demoRoutes.isNotEmpty)
                    _DemoRouteChips(
                      demoRoutes: routingVm.demoRoutes,
                      onSelect: (demo) {
                        _fromController.text =
                            demo.label.split('→')[0].trim();
                        _toController.text = demo.label.contains('→')
                            ? demo.label.split('→')[1].trim()
                            : '';
                        routingVm.loadDemoRoute(demo, mapVm.grid);
                        setState(() => _suggestions = []);
                      },
                    ),

                  // ── Route cards ────────────────────────────────────────
                  if (routingVm.routes.isNotEmpty && _suggestions.isEmpty)
                    _RouteList(vm: routingVm),

                  // ── In-app map ─────────────────────────────────────────
                  if (_suggestions.isEmpty)
                    Expanded(
                      child: Stack(
                        children: [
                          _RouteMap(vm: routingVm),
                          if (routingVm.isLoading)
                            const Center(
                                child: CircularProgressIndicator()),
                          if (routingVm.hasDeviated)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: AppColors.dangerRed,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                child: const Row(
                                  children: [
                                    Icon(Icons.warning_amber,
                                        color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Route deviation detected!',
                                        style: TextStyle(
                                            color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  if (routingVm.error != null)
                    Container(
                      color: Colors.red[50],
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        routingVm.error!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 13),
                      ),
                    ),

                  // Space for the FAB
                  if (hasSelectedRoute && _suggestions.isEmpty)
                    const SizedBox(height: 80),
                ],
              ),

              // ── Start Journey button (fixed bottom) ────────────────────
              if (hasSelectedRoute && _suggestions.isEmpty)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _StartJourneyButton(
                    route: routingVm.selectedRoute!,
                    onStart: () => _launchGoogleMaps(routingVm),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Start Journey button ───────────────────────────────────────────────────────

class _StartJourneyButton extends StatelessWidget {
  final RouteModel route;
  final VoidCallback onStart;

  const _StartJourneyButton(
      {required this.route, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forScore(route.safetyScore);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onStart,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.navigation, size: 22),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Start Journey',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Opens Google Maps · ${route.distanceLabel} · ${route.durationLabel}',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(route.safetyScore * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

// ── Search panel ───────────────────────────────────────────────────────────────

class _SearchPanel extends StatelessWidget {
  final TextEditingController fromController;
  final TextEditingController toController;
  final FocusNode fromFocus;
  final FocusNode toFocus;
  final String selectedProfile;
  final ValueChanged<String> onProfileChanged;
  final ValueChanged<String> onFromChanged;
  final ValueChanged<String> onToChanged;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback onSwap;
  final VoidCallback onSearch;

  const _SearchPanel({
    required this.fromController,
    required this.toController,
    required this.fromFocus,
    required this.toFocus,
    required this.selectedProfile,
    required this.onProfileChanged,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onFromTap,
    required this.onToTap,
    required this.onSwap,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              // Input column
              Expanded(
                child: Column(
                  children: [
                    // Pickup field
                    _LocationField(
                      controller: fromController,
                      focusNode: fromFocus,
                      hint: 'Pickup point',
                      icon: Icons.trip_origin,
                      iconColor: AppColors.primary,
                      onChanged: onFromChanged,
                      onTap: onFromTap,
                    ),
                    const SizedBox(height: 8),
                    // Drop-off field
                    _LocationField(
                      controller: toController,
                      focusNode: toFocus,
                      hint: 'Drop-off point',
                      icon: Icons.location_pin,
                      iconColor: AppColors.dangerRed,
                      onChanged: onToChanged,
                      onTap: onToTap,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Swap + search buttons
              Column(
                children: [
                  // Swap
                  GestureDetector(
                    onTap: onSwap,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.swap_vert,
                          color: AppColors.primary, size: 20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Search
                  GestureDetector(
                    onTap: onSearch,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.search,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Profile toggle (Driving vs Walking)
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'driving',
                      label: Text('Driving'),
                      icon: Icon(Icons.directions_car, size: 16),
                    ),
                    ButtonSegment(
                      value: 'walking',
                      label: Text('Walking'),
                      icon: Icon(Icons.directions_walk, size: 16),
                    ),
                  ],
                  selected: {selectedProfile},
                  onSelectionChanged: (set) {
                    if (set.isNotEmpty) onProfileChanged(set.first);
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

class _LocationField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;

  const _LocationField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.onChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onTap: onTap,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
    );
  }
}

// ── Suggestion list ────────────────────────────────────────────────────────────

class _SuggestionList extends StatelessWidget {
  final List<_LocationSuggestion> suggestions;
  final bool isLoading;
  final void Function(_LocationSuggestion) onSelect;

  const _SuggestionList({
    required this.suggestions,
    required this.isLoading,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                  child:
                      CircularProgressIndicator(strokeWidth: 2)),
            )
          : ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey[100]),
              itemBuilder: (context, idx) {
                final s = suggestions[idx];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    s.isGridEntry
                        ? Icons.grid_on
                        : Icons.location_on_outlined,
                    color: s.isGridEntry
                        ? AppColors.primary
                        : Colors.grey,
                    size: 18,
                  ),
                  title: Text(
                    s.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    s.isGridEntry ? 'From safety grid' : 'From map search',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
                  onTap: () => onSelect(s),
                );
              },
            ),
    );
  }
}

// ── Demo route chips ───────────────────────────────────────────────────────────

class _DemoRouteChips extends StatelessWidget {
  final List<DemoRoute> demoRoutes;
  final void Function(DemoRoute) onSelect;

  const _DemoRouteChips(
      {required this.demoRoutes, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'Or try a demo route (offline-safe)',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: demoRoutes
                  .map((d) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(d.label,
                              style: const TextStyle(fontSize: 12)),
                          onPressed: () => onSelect(d),
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.08),
                          side: const BorderSide(color: AppColors.primary),
                          visualDensity: VisualDensity.compact,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Route cards list ───────────────────────────────────────────────────────────

class _RouteList extends StatelessWidget {
  final RoutingViewModel vm;
  const _RouteList({required this.vm});

  void _showXai(BuildContext context, RouteModel route) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RouteXaiSheet(route: route),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 160),
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: vm.routes.length,
        itemBuilder: (context, idx) {
          final route = vm.routes[idx];
          final isSelected = vm.selectedRoute?.id == route.id;
          final color = AppColors.forScore(route.safetyScore);
          return GestureDetector(
            onTap: () => vm.selectRoute(route),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.08)
                    : Colors.grey[50],
                border: Border.all(
                  color: isSelected ? color : Colors.grey[200]!,
                  width: isSelected ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  // Index circle
                  Container(
                    width: 28,
                    height: 28,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.riskLevel == 'Low'
                              ? 'Safest Route'
                              : route.riskLevel == 'Medium'
                                  ? 'Moderate Route'
                                  : 'Higher Risk Route',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: color,
                              fontSize: 13),
                        ),
                        Text(
                          '${route.distanceLabel} · ${route.durationLabel}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  if (route.isCached)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child:
                          Icon(Icons.cached, size: 14, color: Colors.grey),
                    ),
                  // Score + XAI button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(route.safetyScore * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 15),
                      ),
                      GestureDetector(
                        onTap: () => _showXai(context, route),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 11, color: color),
                            const SizedBox(width: 2),
                            Text(
                              'Why?',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Route XAI bottom sheet ─────────────────────────────────────────────────────

class _RouteXaiSheet extends StatelessWidget {
  final RouteModel route;
  const _RouteXaiSheet({required this.route});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forScore(route.safetyScore);
    final xai = route.explanation;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(blurRadius: 20, color: Colors.black26)
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (route.safetyScore * 100).toStringAsFixed(0),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              route.riskLevel == 'Low'
                                  ? 'Safest Route'
                                  : route.riskLevel == 'Medium'
                                      ? 'Moderate Route'
                                      : 'Higher Risk Route',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: color),
                            ),
                            Text(
                              '${route.distanceLabel} · ${route.durationLabel}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      if (route.isCached)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cached,
                                  size: 11, color: Colors.grey),
                              SizedBox(width: 3),
                              Text('Cached',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // AI Summary banner
                  if (xai != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: color.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome, color: color, size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI ROUTE ANALYSIS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  xai.summaryText,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Factor breakdown
                    const Text(
                      'Route factor breakdown',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const Text(
                      'Averaged across all points on this route',
                      style:
                          TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                    const SizedBox(height: 10),
                    ...xai.factors.map((f) => _FactorTile(factor: f)),

                    // Tips
                    if (xai.tips.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warningAmber
                              .withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.warningAmber
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lightbulb_outline,
                                    size: 14,
                                    color: AppColors.warningAmber),
                                SizedBox(width: 6),
                                Text(
                                  'Route Safety Tips',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warningAmber,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            ...xai.tips.map(
                              (tip) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ',
                                        style: TextStyle(
                                            color: AppColors.warningAmber,
                                            fontSize: 13)),
                                    Expanded(
                                      child: Text(
                                        tip,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                            height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else
                    const Text(
                      'Detailed analysis not available for this route.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactorTile extends StatelessWidget {
  final RouteFactorRow factor;
  const _FactorTile({required this.factor});

  @override
  Widget build(BuildContext context) {
    final color = factor.isPositive
        ? AppColors.safeGreen
        : factor.isNegative
            ? AppColors.dangerRed
            : AppColors.warningAmber;

    final icon = factor.isPositive
        ? Icons.check_circle_outline
        : factor.isNegative
            ? Icons.cancel_outlined
            : Icons.remove_circle_outline;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(factor.icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        factor.label,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        factor.value,
                        style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(icon, size: 16, color: color),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  factor.detail,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Route map ──────────────────────────────────────────────────────────────────

// ── Route map ──────────────────────────────────────────────────────────────────

class _RouteMap extends StatefulWidget {
  final RoutingViewModel vm;
  const _RouteMap({required this.vm});

  @override
  State<_RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<_RouteMap> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final selected = widget.vm.selectedRoute;
    final LatLng center = (selected != null && selected.polyline.isNotEmpty)
        ? selected.polyline[selected.polyline.length ~/ 2]
        : const LatLng(28.6139, 77.2090);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: center, initialZoom: 12),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.suraksha.app',
            ),
            if (widget.vm.routes.isNotEmpty)
              PolylineLayer(
                polylines: widget.vm.routes.map((r) {
                  final isSel = widget.vm.selectedRoute?.id == r.id;
                  return Polyline(
                    points: r.polyline,
                    strokeWidth: isSel ? 5.5 : 2.5,
                    color: isSel
                        ? AppColors.forScore(r.safetyScore)
                        : AppColors.forScore(r.safetyScore)
                            .withValues(alpha: 0.35),
                  );
                }).toList(),
              ),
            if (widget.vm.startPoint != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.vm.startPoint!,
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.trip_origin,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            if (widget.vm.endPoint != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.vm.endPoint!,
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.dangerRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.location_pin,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
          ],
        ),

        // ── Zoom controls ───────────────────────────────────────────────
        Positioned(
          right: 12,
          bottom: 16,
          child: _ZoomControls(mapController: _mapController),
        ),
      ],
    );
  }
}

// ── Zoom controls widget (reusable) ───────────────────────────────────────────

class _ZoomControls extends StatelessWidget {
  final MapController mapController;
  const _ZoomControls({required this.mapController});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ZoomBtn(
          icon: Icons.add,
          onTap: () {
            final current = mapController.camera.zoom;
            mapController.move(
                mapController.camera.center, current + 1);
          },
        ),
        const SizedBox(height: 4),
        _ZoomBtn(
          icon: Icons.remove,
          onTap: () {
            final current = mapController.camera.zoom;
            mapController.move(
                mapController.camera.center, current - 1);
          },
        ),
      ],
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}
