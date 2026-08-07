import 'package:flutter/foundation.dart';
import '../models/incident.dart';
import '../repositories/incident_repository.dart';

class IncidentViewModel extends ChangeNotifier {
  final IncidentRepository _incidentRepo;

  IncidentViewModel({required IncidentRepository incidentRepo})
      : _incidentRepo = incidentRepo;

  // ── State ─────────────────────────────────────────────────────────────────

  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _error;
  String _selectedCrimeType = Incident.crimeTypes.first;
  String _description = '';

  bool get isSubmitting => _isSubmitting;
  bool get isSuccess => _isSuccess;
  String? get error => _error;
  String get selectedCrimeType => _selectedCrimeType;
  String get description => _description;
  List<String> get crimeTypes => Incident.crimeTypes;

  // ── Actions ───────────────────────────────────────────────────────────────

  void selectCrimeType(String type) {
    _selectedCrimeType = type;
    notifyListeners();
  }

  void updateDescription(String value) {
    _description = value;
    notifyListeners();
  }

  Future<void> submitIncident({
    required double latitude,
    required double longitude,
    required String timeOfDay,
  }) async {
    if (_selectedCrimeType.isEmpty) return;

    _isSubmitting = true;
    _isSuccess = false;
    _error = null;
    notifyListeners();

    try {
      final incident = Incident(
        localId: '${DateTime.now().millisecondsSinceEpoch}_${latitude}_$longitude',
        latitude: latitude,
        longitude: longitude,
        crimeType: _selectedCrimeType,
        description: _description,
        timeOfDay: timeOfDay,
        reportedAt: DateTime.now(),
        isSynced: false,
      );
      await _incidentRepo.reportIncident(incident);
      _isSuccess = true;
      _description = '';
      _selectedCrimeType = Incident.crimeTypes.first;
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
    notifyListeners();
  }
}
