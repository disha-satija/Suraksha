import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/safe_spot.dart';
import '../services/safe_spot_service.dart';
import '../services/api_client.dart';

enum LocationState { idle, requesting, granted, denied, searching }

// Simple suggestion result from Nominatim
class LocationSuggestion {
  final String label;
  final double lat;
  final double lng;
  const LocationSuggestion(
      {required this.label, required this.lat, required this.lng});
}

class SafeSpotViewModel extends ChangeNotifier {
  final SafeSpotService _safeSpotService;
  final ApiClient _api;

  SafeSpotViewModel({required SafeSpotService safeSpots, ApiClient? api})
      : _safeSpotService = safeSpots,
        _api = api ?? ApiClient();

  // ── State ─────────────────────────────────────────────────────────────────

  LocationState _locationState = LocationState.idle;
  LatLng? _currentLocation;
  String _locationLabel = '';
  String _searchQuery = '';

  List<SafeSpot> _safeSpots = [];
  SafeSpot? _selectedSpot;
  bool _isLoading = false;
  String? _error;
  int _lastRadiusKm = 5;

  // Search suggestions
  List<LocationSuggestion> _searchSuggestions = [];
  bool _isSuggestionsLoading = false;
  Timer? _debounce;

  LocationState get locationState => _locationState;
  LatLng? get currentLocation => _currentLocation;
  String get locationLabel => _locationLabel;
  String get searchQuery => _searchQuery;
  List<SafeSpot> get safeSpots => _safeSpots;
  SafeSpot? get selectedSpot => _selectedSpot;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get lastRadiusKm => _lastRadiusKm;
  bool get hasLocation => _currentLocation != null;
  List<LocationSuggestion> get searchSuggestions => _searchSuggestions;
  bool get isSuggestionsLoading => _isSuggestionsLoading;

  SafeSpot? get nearestSpot =>
      _safeSpots.isEmpty
          ? null
          : _safeSpots.reduce(
              (a, b) => a.distanceKm <= b.distanceKm ? a : b);

  // ── Search suggestion typing handler ─────────────────────────────────────

  void updateSearchQuery(String query) {
    _searchQuery = query;
    _debounce?.cancel();
    if (query.trim().length < 2) {
      _searchSuggestions = [];
      _isSuggestionsLoading = false;
      notifyListeners();
      return;
    }
    _isSuggestionsLoading = true;
    notifyListeners();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchSuggestions(query.trim());
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final payload = await _api.get('/geocode/search', query: {'q': query, 'limit': 6});
      final data = payload['data'] as List<dynamic>? ?? [];
      _searchSuggestions = data.map((item) {
        final e = Map<String, dynamic>.from(item as Map);
        return LocationSuggestion(label: e['label'] as String, lat: (e['lat'] as num).toDouble(), lng: (e['lng'] as num).toDouble());
      }).toList();
    } catch (_) {
      _searchSuggestions = [];
    } finally {
      _isSuggestionsLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // ── GPS flow ──────────────────────────────────────────────────────────────  /// Called on screen init — tries GPS first, emits state changes throughout.
  Future<void> initLocation() async {
    _locationState = LocationState.requesting;
    _error = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationState = LocationState.denied;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _locationState = LocationState.denied;
        notifyListeners();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _currentLocation = LatLng(pos.latitude, pos.longitude);
      _locationState = LocationState.granted;

      // Reverse-geocode to get a human-readable label
      _locationLabel = await _reverseGeocode(pos.latitude, pos.longitude);
      notifyListeners();

      // Auto-fetch safe spots once we have location
      await fetchSafeSpots();
    } catch (e) {
      _locationState = LocationState.denied;
      _error = 'Could not get location. Use the search bar to set your position.';
      notifyListeners();
    }
  }

  // ── Search bar flow ───────────────────────────────────────────────────────

  /// Called when user submits the location search bar.
  Future<void> searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    _searchQuery = query.trim();
    _isLoading = true;
    _error = null;
    _locationState = LocationState.searching;
    notifyListeners();

    try {
      final coords = await _geocode(query);
      if (coords == null) {
        _error = 'Location not found. Try a more specific name.';
        _isLoading = false;
        _locationState = LocationState.idle;
        notifyListeners();
        return;
      }

      _currentLocation = coords;
      _locationLabel = query;
      _locationState = LocationState.granted;
      notifyListeners();

      await fetchSafeSpots();
    } catch (e) {
      _error = 'Search failed: $e';
      _isLoading = false;
      _locationState = LocationState.idle;
      notifyListeners();
    }
  }

  /// Directly set location from an external coordinate (e.g. map tap).
  Future<void> setLocationFromCoords(LatLng coords, {String? label}) async {
    _currentLocation = coords;
    _locationLabel = label ?? await _reverseGeocode(coords.latitude, coords.longitude);
    _locationState = LocationState.granted;
    _error = null;
    notifyListeners();
    await fetchSafeSpots();
  }

  // ── Safe spot fetch ───────────────────────────────────────────────────────

  Future<void> fetchSafeSpots({int radiusKm = 5}) async {
    if (_currentLocation == null) return;

    _isLoading = true;
    _error = null;
    _lastRadiusKm = radiusKm;
    notifyListeners();

    try {
      _safeSpots = await _safeSpotService.findSafeSpots(
        lat: _currentLocation!.latitude,
        lng: _currentLocation!.longitude,
        locationLabel: _locationLabel.isNotEmpty ? _locationLabel : 'current location',
        radiusKm: radiusKm,
        maxResults: 8,
      );
      _error = null;
    } catch (e) {
      _error = 'Could not load safe spots: $e';
      _safeSpots = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Selection ─────────────────────────────────────────────────────────────

  void selectSpot(SafeSpot spot) {
    _selectedSpot = spot;
    notifyListeners();
  }

  void clearSelection() {
    _selectedSpot = null;
    notifyListeners();
  }

  void clearSpots() {
    _safeSpots = [];
    _selectedSpot = null;
    _searchSuggestions = [];
    notifyListeners();
  }

  // ── Geocoding helpers ─────────────────────────────────────────────────────

  Future<LatLng?> _geocode(String query) async {
    try {
      final payload = await _api.get('/geocode/search', query: {'q': query, 'limit': 1});
      final data = payload['data'] as List<dynamic>? ?? [];
      if (data.isNotEmpty) {
        final item = Map<String, dynamic>.from(data.first as Map);
        return LatLng((item['lat'] as num).toDouble(), (item['lng'] as num).toDouble());
      }
    } catch (_) {}
    return null;
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final payload = await _api.get('/geocode/reverse', query: {'lat': lat, 'lng': lng});
      final data = payload['data'] as Map<String, dynamic>?;
      if (data != null) return data['label'] as String? ?? 'Current Location';
    } catch (_) {}
    return 'Current Location';
  }
}
