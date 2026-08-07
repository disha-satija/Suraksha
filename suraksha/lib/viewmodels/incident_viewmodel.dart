import 'package:flutter/foundation.dart';
import '../models/incident.dart';
import '../repositories/incident_repository.dart';
import '../services/supabase_service.dart';

class IncidentViewModel extends ChangeNotifier {
  final IncidentRepository _incidentRepo;
  final SupabaseService _supabase;

  IncidentViewModel({
    required IncidentRepository incidentRepo,
    required SupabaseService supabase,
  })  : _incidentRepo = incidentRepo,
        _supabase = supabase;

  // ── State ──────────────────────────────────────────────────────────────────

  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _error;

  // Form fields
  String _selectedCrimeType = Incident.crimeTypes.first;
  String _description = '';
  double _lightingScore = 3.0;
  double _policeDistanceKm = 2.0;
  double _crowdDensity = 300.0;
  int _crimeCount = 5;
  String _selectedWeather = Incident.weatherConditions.first;

  // Reverse-geocoded location labels
  String? _city;
  String? _area;

  // Server result (populated after successful online sync)
  double? _safetyScore;
  String? _riskLevel;

  // ── Getters ────────────────────────────────────────────────────────────────

  bool get isSubmitting => _isSubmitting;
  bool get isSuccess => _isSuccess;
  String? get error => _error;

  String get selectedCrimeType => _selectedCrimeType;
  String get description => _description;
  double get lightingScore => _lightingScore;
  double get policeDistanceKm => _policeDistanceKm;
  double get crowdDensity => _crowdDensity;
  int get crimeCount => _crimeCount;
  String get selectedWeather => _selectedWeather;

  String? get city => _city;
  String? get area => _area;

  double? get safetyScore => _safetyScore;
  String? get riskLevel => _riskLevel;

  List<String> get crimeTypes => Incident.crimeTypes;
  List<String> get weatherConditions => Incident.weatherConditions;

  // ── Slider / dropdown setters ──────────────────────────────────────────────

  void selectCrimeType(String type) {
    _selectedCrimeType = type;
    notifyListeners();
  }

  void updateDescription(String value) {
    _description = value;
    notifyListeners();
  }

  void setLightingScore(double value) {
    _lightingScore = value;
    notifyListeners();
  }

  void setPoliceDistanceKm(double value) {
    _policeDistanceKm = value;
    notifyListeners();
  }

  void setCrowdDensity(double value) {
    _crowdDensity = value;
    notifyListeners();
  }

  void setCrimeCount(double value) {
    _crimeCount = value.round();
    notifyListeners();
  }

  void selectWeather(String value) {
    _selectedWeather = value;
    notifyListeners();
  }

  // ── Reverse geocode ────────────────────────────────────────────────────────

  Future<void> fetchLocation(double lat, double lng) async {
    try {
      final result = await _supabase.reverseGeocode(lat, lng);
      final address = result['address'] as Map<String, dynamic>? ?? {};
      _city = (address['city'] as String?) ??
          (address['town'] as String?) ??
          (address['state'] as String?);
      _area = (address['suburb'] as String?) ??
          (address['neighbourhood'] as String?) ??
          (address['road'] as String?);
      notifyListeners();
    } catch (_) {
      // Non-fatal: city/area remain null; form still works
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> submitIncident({
    required double latitude,
    required double longitude,
  }) async {
    if (_selectedCrimeType.isEmpty) return;

    _isSubmitting = true;
    _isSuccess = false;
    _error = null;
    _safetyScore = null;
    _riskLevel = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final incident = Incident(
        localId: '${now.millisecondsSinceEpoch}_${latitude}_$longitude',
        latitude: latitude,
        longitude: longitude,
        city: _city,
        area: _area,
        crimeType: _selectedCrimeType,
        description: _description,
        lightingScore: _lightingScore,
        policeStationDistanceKm: _policeDistanceKm,
        crowdDensity: _crowdDensity,
        crimeCount: _crimeCount,
        weatherCondition: _selectedWeather,
        timeOfDay: _currentTimeOfDay(now),
        reportedAt: now,
        incidentTimestamp: now,
        isSynced: false,
      );

      final response = await _incidentRepo.reportIncident(incident);

      // Extract server-computed scores if the device was online
      if (response != null) {
        final data = response['data'] as Map<String, dynamic>?;
        _safetyScore = (data?['safetyScore'] as num?)?.toDouble();
        _riskLevel   = data?['riskLevel'] as String?;
      }

      _isSuccess = true;
      _description = '';
      _selectedCrimeType = Incident.crimeTypes.first;
      _lightingScore = 3.0;
      _policeDistanceKm = 2.0;
      _crowdDensity = 300.0;
      _crimeCount = 5;
      _selectedWeather = Incident.weatherConditions.first;
    } catch (e) {
      _error = 'Failed to submit report: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void reset() {
    _isSuccess = false;
    _error = null;
    _safetyScore = null;
    _riskLevel = null;
    _city = null;
    _area = null;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _currentTimeOfDay(DateTime dt) {
    final h = dt.hour;
    if (h >= 5 && h < 12) return 'Morning';
    if (h >= 12 && h < 17) return 'Afternoon';
    if (h >= 17 && h < 21) return 'Evening';
    if (h >= 21 || h < 1) return 'Night';
    return 'Late Night';
  }
}
