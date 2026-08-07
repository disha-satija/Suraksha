import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/incident_viewmodel.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../viewmodels/safe_spot_viewmodel.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/connectivity_banner.dart';

class IncidentScreen extends StatefulWidget {
  final double? latitude;
  final double? longitude;

  const IncidentScreen({
    super.key,
    this.latitude,
    this.longitude,
  });

  @override
  State<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {
  // ── Resolve the coordinates to report against ─────────────────────────────
  // Prefer the values passed in by the caller; when this screen is opened as
  // a tab root there is no caller, so fall back to the last known safe-spot
  // location, then to the map's current center.
  double get _latitude =>
      widget.latitude ??
      context.read<SafeSpotViewModel>().currentLocation?.latitude ??
      context.read<MapViewModel>().center.latitude;

  double get _longitude =>
      widget.longitude ??
      context.read<SafeSpotViewModel>().currentLocation?.longitude ??
      context.read<MapViewModel>().center.longitude;

  @override
  void initState() {
    super.initState();
    // Kick off reverse geocode as soon as the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncidentViewModel>().fetchLocation(_latitude, _longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
        automaticallyImplyLeading: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(24),
          child: ConnectivityBanner(),
        ),
      ),
      body: Consumer<IncidentViewModel>(
        builder: (context, vm, _) {
          if (vm.isSuccess) {
            return _SuccessView(
              safetyScore: vm.safetyScore,
              riskLevel: vm.riskLevel,
              onDone: () {
                vm.reset();
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Location chip ──────────────────────────────────────────
                _LocationChip(
                  latitude: _latitude,
                  longitude: _longitude,
                  city: vm.city,
                  area: vm.area,
                ),
                const SizedBox(height: 20),

                // ── Crime type ─────────────────────────────────────────────
                _SectionLabel('Type of Incident'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: vm.selectedCrimeType,
                  decoration: _inputDecoration(),
                  items: vm.crimeTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) vm.selectCrimeType(val);
                  },
                ),
                const SizedBox(height: 20),

                // ── Lighting score ─────────────────────────────────────────
                _ChoiceField(
                  label: 'Area Lighting',
                  sublabel: 'How well-lit was the area?',
                  value: vm.lightingScore,
                  options: const [
                    (text: 'Dark', value: 1.0),
                    (text: 'Dim', value: 2.5),
                    (text: 'Moderate', value: 3.0),
                    (text: 'Well lit', value: 5.0),
                  ],
                  onChanged: vm.setLightingScore,
                ),
                const SizedBox(height: 16),

                // ── Police distance ────────────────────────────────────────
                _ChoiceField(
                  label: 'Nearest Police Station',
                  sublabel: 'Roughly how far was the nearest police station?',
                  value: vm.policeDistanceKm,
                  options: const [
                    (text: 'Very close', value: 0.5),
                    (text: 'Nearby', value: 2.0),
                    (text: 'Far', value: 6.0),
                    (text: 'Very far / not sure', value: 15.0),
                  ],
                  onChanged: vm.setPoliceDistanceKm,
                ),
                const SizedBox(height: 16),

                // ── Crowd density ──────────────────────────────────────────
                _ChoiceField(
                  label: 'How busy was it?',
                  sublabel: 'Roughly how many people were around?',
                  value: vm.crowdDensity,
                  options: const [
                    (text: 'Empty', value: 0.0),
                    (text: 'A few people', value: 50.0),
                    (text: 'Busy', value: 300.0),
                    (text: 'Crowded', value: 800.0),
                  ],
                  onChanged: vm.setCrowdDensity,
                ),
                const SizedBox(height: 16),

                // ── Crime count ────────────────────────────────────────────
                _ChoiceField(
                  label: 'Recent Incidents Nearby',
                  sublabel: 'Incidents you know of here in the last 90 days',
                  value: vm.crimeCount.toDouble(),
                  options: const [
                    (text: 'None I know of', value: 0.0),
                    (text: 'A few', value: 5.0),
                    (text: 'Several', value: 15.0),
                    (text: 'Many', value: 35.0),
                  ],
                  onChanged: vm.setCrimeCount,
                ),
                const SizedBox(height: 20),

                // ── Weather ────────────────────────────────────────────────
                _SectionLabel('Current Weather'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: vm.selectedWeather,
                  decoration: _inputDecoration(),
                  items: vm.weatherConditions
                      .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) vm.selectWeather(val);
                  },
                ),
                const SizedBox(height: 20),

                // ── Description ────────────────────────────────────────────
                _SectionLabel('Description (optional)'),
                const SizedBox(height: 8),
                TextFormField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Briefly describe what happened...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  onChanged: vm.updateDescription,
                ),
                const SizedBox(height: 8),

                // ── Offline note ───────────────────────────────────────────
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.grey),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Report is saved locally and will sync automatically when online.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Error ──────────────────────────────────────────────────
                if (vm.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      vm.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                // ── Submit ─────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: vm.isSubmitting
                        ? null
                        : () => vm.submitIncident(
                              latitude: _latitude,
                              longitude: _longitude,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: vm.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Submit Report',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration() => InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );
}

// ── Private widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      );
}

class _LocationChip extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? city;
  final String? area;

  const _LocationChip({
    required this.latitude,
    required this.longitude,
    this.city,
    this.area,
  });

  @override
  Widget build(BuildContext context) {
    final label = (area != null && city != null)
        ? '$area, $city'
        : (city ?? 'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined,
              color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.subtitle),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceField extends StatelessWidget {
  final String label;
  final String sublabel;
  final double value;
  final List<({String text, double value})> options;
  final ValueChanged<double> onChanged;

  const _ChoiceField({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        Text(sublabel,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              _ChoiceChip(
                text: option.text,
                selected: (value - option.value).abs() < 0.01,
                onTap: () => onChanged(option.value),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: selected
                ? null
                : Border.all(color: AppColors.border),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: selected ? Colors.white : AppColors.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Success view ───────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final VoidCallback onDone;
  final double? safetyScore;
  final String? riskLevel;

  const _SuccessView({
    required this.onDone,
    this.safetyScore,
    this.riskLevel,
  });

  Color _riskColor() {
    switch (riskLevel?.toLowerCase()) {
      case 'low':
        return AppColors.safeGreen;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.safeGreen, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Report Submitted',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),

            // ── Safety score card (shown only when server returned a score) ─
            if (safetyScore != null && riskLevel != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _riskColor().withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _riskColor().withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Area Safety Score',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _riskColor(),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            riskLevel!.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: safetyScore!.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_riskColor()),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(safetyScore! * 100).toStringAsFixed(1)} / 100',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _riskColor()),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                'Your report has been saved and will sync to our servers when you\'re online.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Done',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
