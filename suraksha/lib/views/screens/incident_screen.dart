import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/incident_viewmodel.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/connectivity_banner.dart';

class IncidentScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const IncidentScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off reverse geocode as soon as the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<IncidentViewModel>()
          .fetchLocation(widget.latitude, widget.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
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
                Navigator.pop(context);
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
                  latitude: widget.latitude,
                  longitude: widget.longitude,
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
                _SliderRow(
                  label: 'Area Lighting',
                  sublabel: 'How well-lit was the area?',
                  value: vm.lightingScore,
                  min: 1,
                  max: 5,
                  divisions: 40,
                  displayValue: vm.lightingScore.toStringAsFixed(1),
                  minLabel: 'Very Dark',
                  maxLabel: 'Bright',
                  onChanged: vm.setLightingScore,
                ),
                const SizedBox(height: 16),

                // ── Police distance ────────────────────────────────────────
                _SliderRow(
                  label: 'Nearest Police Station',
                  sublabel: 'Estimated distance in km',
                  value: vm.policeDistanceKm,
                  min: 0.1,
                  max: 20,
                  divisions: 199,
                  displayValue: '${vm.policeDistanceKm.toStringAsFixed(1)} km',
                  minLabel: 'Very Close',
                  maxLabel: '20 km',
                  onChanged: vm.setPoliceDistanceKm,
                ),
                const SizedBox(height: 16),

                // ── Crowd density ──────────────────────────────────────────
                _SliderRow(
                  label: 'Crowd Density',
                  sublabel: 'Approx. people visible nearby',
                  value: vm.crowdDensity,
                  min: 0,
                  max: 1000,
                  divisions: 100,
                  displayValue: vm.crowdDensity.round().toString(),
                  minLabel: 'Empty',
                  maxLabel: 'Crowded',
                  onChanged: vm.setCrowdDensity,
                ),
                const SizedBox(height: 16),

                // ── Crime count ────────────────────────────────────────────
                _SliderRow(
                  label: 'Recent Incidents in Area',
                  sublabel: 'Known incidents nearby (last 90 days)',
                  value: vm.crimeCount.toDouble(),
                  min: 0,
                  max: 50,
                  divisions: 50,
                  displayValue: vm.crimeCount.toString(),
                  minLabel: 'None',
                  maxLabel: '50+',
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
                              latitude: widget.latitude,
                              longitude: widget.longitude,
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

class _SliderRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final String minLabel;
  final String maxLabel;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.minLabel,
    required this.maxLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(sublabel,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                displayValue,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primary),
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(minLabel,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(maxLabel,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
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
