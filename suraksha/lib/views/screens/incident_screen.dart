import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/incident_viewmodel.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/connectivity_banner.dart';

class IncidentScreen extends StatelessWidget {
  final double latitude;
  final double longitude;

  const IncidentScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  String _currentTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 20) return 'Evening';
    if (hour >= 20 && hour < 23) return 'Night';
    return 'Late Night';
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
            return _SuccessView(onDone: () {
              vm.reset();
              Navigator.pop(context);
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location info
                Container(
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
                      Text(
                        'Lat: ${latitude.toStringAsFixed(4)}, '
                        'Lng: ${longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.subtitle),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Crime type dropdown
                const Text(
                  'Type of Incident',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: vm.selectedCrimeType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                  items: vm.crimeTypes
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) vm.selectCrimeType(val);
                  },
                ),
                const SizedBox(height: 20),

                // Description
                const Text(
                  'Description (optional)',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Briefly describe what happened...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  onChanged: vm.updateDescription,
                ),
                const SizedBox(height: 8),

                // Offline note
                Row(
                  children: const [
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

                // Error
                if (vm.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      vm.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: vm.isSubmitting
                        ? null
                        : () => vm.submitIncident(
                              latitude: latitude,
                              longitude: longitude,
                              timeOfDay: _currentTimeOfDay(),
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
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Submit Report',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onDone;
  const _SuccessView({required this.onDone});

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
            const Text(
              'Your report has been saved and will sync to our servers when you\'re online.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
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
