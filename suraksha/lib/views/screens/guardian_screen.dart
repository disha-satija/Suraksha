import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/guardian_viewmodel.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/connectivity_banner.dart';

/// User's view — shows sharing status + SMS fallback trigger.
class GuardianScreen extends StatefulWidget {
  const GuardianScreen({super.key});

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen> {
  // Simulated user ID — in production, comes from Supabase Auth
  static const String _userId = 'demo_user_001';

  // Demo: simulate current location as Delhi center
  static const double _demoLat = 28.6139;
  static const double _demoLng = 77.2090;

  @override
  void initState() {
    super.initState();
    context.read<GuardianViewModel>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Mode'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(24),
          child: ConnectivityBanner(),
        ),
      ),
      body: Consumer<GuardianViewModel>(
        builder: (context, vm, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Guardian info card
                _GuardianInfoCard(vm: vm),
                const SizedBox(height: 20),

                // Tracking controls
                _TrackingCard(
                  vm: vm,
                  onShareLocation: () => vm.updateLocation(
                    userId: _userId,
                    lat: _demoLat,
                    lng: _demoLng,
                    triggerSms: false,
                  ),
                  onSendSos: () => vm.updateLocation(
                    userId: _userId,
                    lat: _demoLat,
                    lng: _demoLng,
                    triggerSms: true,
                  ),
                ),
                const SizedBox(height: 20),

                // SMS fallback note
                _SmsInfoCard(smsSent: vm.smsSent),
                const SizedBox(height: 20),

                // Mini map — current location
                const Text(
                  'Your Location',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 220,
                    child: FlutterMap(
                      options: const MapOptions(
                        initialCenter: LatLng(_demoLat, _demoLng),
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              AppConstants.onlineTileUrl,
                          userAgentPackageName: 'com.suraksha.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point:
                                  const LatLng(_demoLat, _demoLng),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.person,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

class _GuardianInfoCard extends StatelessWidget {
  final GuardianViewModel vm;
  const _GuardianInfoCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final g = vm.guardian;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined,
                color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: g.isConfigured
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Guardian',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        g.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16),
                      ),
                      Text(
                        g.phone,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'No guardian configured',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.warningAmber),
                      ),
                      Text(
                        'Go to Settings → Guardian to add one',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  final GuardianViewModel vm;
  final VoidCallback onShareLocation;
  final VoidCallback onSendSos;

  const _TrackingCard({
    required this.vm,
    required this.onShareLocation,
    required this.onSendSos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: vm.isGuardianConfigured ? onShareLocation : null,
            icon: const Icon(Icons.location_on),
            label: const Text('Share Location with Guardian'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: vm.isGuardianConfigured
                ? onSendSos
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Please set a guardian in Settings first.'),
                        backgroundColor: AppColors.warningAmber,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
            icon: const Icon(Icons.sos),
            label: Text(vm.isGuardianConfigured
                ? 'SOS — Alert Guardian'
                : 'SOS — Set Guardian First'),
            style: ElevatedButton.styleFrom(
              backgroundColor: vm.isGuardianConfigured
                  ? AppColors.dangerRed
                  : Colors.grey[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (vm.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              vm.error!,
              style: const TextStyle(color: AppColors.dangerRed, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _SmsInfoCard extends StatelessWidget {
  final bool smsSent;
  const _SmsInfoCard({required this.smsSent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: smsSent
            ? AppColors.safeGreen.withValues(alpha: 0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: smsSent
                ? AppColors.safeGreen
                : Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            smsSent ? Icons.check_circle : Icons.sms_outlined,
            color: smsSent ? AppColors.safeGreen : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              smsSent
                  ? 'SMS alert opened — tap Send in Messages to deliver.'
                  : 'When offline, SOS will open a pre-filled SMS to your guardian.',
              style: TextStyle(
                fontSize: 12,
                color: smsSent ? AppColors.safeGreen : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Guardian's view — watches the tracked user's live location.
class GuardianWatchScreen extends StatefulWidget {
  final String trackedUserId;
  const GuardianWatchScreen({super.key, required this.trackedUserId});

  @override
  State<GuardianWatchScreen> createState() =>
      _GuardianWatchScreenState();
}

class _GuardianWatchScreenState extends State<GuardianWatchScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<GuardianViewModel>()
        .subscribeToGuardianStream(widget.trackedUserId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watching Location'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(24),
          child: ConnectivityBanner(),
        ),
      ),
      body: Consumer<GuardianViewModel>(
        builder: (context, vm, _) {
          final loc = vm.guardianTrackedLocation;
          final center =
              loc ?? const LatLng(28.6139, 77.2090);

          return FlutterMap(
            options:
                MapOptions(initialCenter: center, initialZoom: 14),
            children: [
              TileLayer(
                urlTemplate: AppConstants.onlineTileUrl,
                userAgentPackageName: 'com.suraksha.app',
              ),
              if (loc != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: loc,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.dangerRed,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                                blurRadius: 6,
                                color: Colors.black38)
                          ],
                        ),
                        child: const Icon(Icons.person_pin,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              if (loc == null)
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Waiting for location...',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 16),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
