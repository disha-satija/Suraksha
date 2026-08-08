import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/map_tile_provider.dart';
import '../../models/safe_spot.dart';
import '../../models/safety_score_result.dart';
import '../../viewmodels/guardian_viewmodel.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../viewmodels/safe_spot_viewmodel.dart';
import 'contribute_screen.dart';
import 'download_offline_maps_screen.dart';
import 'incident_screen.dart';
import 'settings_screen.dart';

/// New default tab — a dashboard pulling together the safety score of the
/// user's current area, quick actions, the nearest safe spot, and status of
/// the guardian/offline-map features.
class HomeScreen extends StatefulWidget {
  final ValueChanged<int> onSelectTab;

  const HomeScreen({super.key, required this.onSelectTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final location = context.read<SafeSpotViewModel>().currentLocation;
      if (location != null) {
        context.read<MapViewModel>().refreshAreaScore(location);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer3<MapViewModel, SafeSpotViewModel, GuardianViewModel>(
          builder: (context, mapVm, ssVm, guardianVm, _) {
            // Location arrives asynchronously — once it's available, kick off
            // the area score fetch exactly once. Guarded by areaScore == null
            // so this doesn't fire again on every rebuild, and deferred to a
            // post-frame callback so we never call notifyListeners mid-build.
            if (ssVm.currentLocation != null && mapVm.areaScore == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (mapVm.areaScore == null) {
                  mapVm.refreshAreaScore(ssVm.currentLocation!);
                }
              });
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                _GreetingHeader(locationLabel: ssVm.locationLabel),
                const SizedBox(height: 14),
                _AreaSafetyScoreCard(areaScore: mapVm.areaScore),
                const SizedBox(height: 14),
                _QuickActions(onSelectTab: widget.onSelectTab),
                const SizedBox(height: 14),
                if (ssVm.nearestSpot != null) ...[
                  _NearestSafeSpotCard(
                    spot: ssVm.nearestSpot!,
                    onTap: () => widget.onSelectTab(2),
                  ),
                  const SizedBox(height: 14),
                ],
                _StatusStrip(guardianVm: guardianVm),
                const SizedBox(height: 14),
                const _ContributeNudge(),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── 4a. Greeting header ──────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  final String locationLabel;
  const _GreetingHeader({required this.locationLabel});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Stay safe tonight';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.place_rounded, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                locationLabel.isNotEmpty ? locationLabel : 'Locating you…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.subtitle),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── 4b. Area Safety Score ────────────────────────────────────────────────────

class _AreaSafetyScoreCard extends StatelessWidget {
  final SafetyScoreResult? areaScore;
  const _AreaSafetyScoreCard({required this.areaScore});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: areaScore == null
          ? const _ScoreLoading()
          : _ScoreContent(result: areaScore!),
    );
  }
}

class _ScoreLoading extends StatelessWidget {
  const _ScoreLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Reading your area…',
              style: TextStyle(fontSize: 12.5, color: AppColors.subtitle),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreContent extends StatelessWidget {
  final SafetyScoreResult result;
  const _ScoreContent({required this.result});

  @override
  Widget build(BuildContext context) {
    final scoreColor = AppColors.forScore(result.score);
    final topContributions = [...result.contributions]
      ..sort((a, b) => b.contribution.abs().compareTo(a.contribution.abs()));
    final shownContributions = topContributions.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 108,
              height: 108,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 108,
                    height: 108,
                    child: CircularProgressIndicator(
                      value: result.score,
                      strokeWidth: 9,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(scoreColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(result.score * 100).round()}',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: scoreColor,
                        ),
                      ),
                      const Text(
                        '/100',
                        style: TextStyle(fontSize: 11, color: AppColors.subtitle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AREA SAFETY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: AppColors.subtitle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.riskLabel,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: scoreColor,
                    ),
                  ),
                  if (result.summaryExplanation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      result.summaryExplanation,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.subtitle,
                        height: 1.4,
                      ),
                      maxLines: 7,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 24, color: AppColors.border),
        // Only claim to explain the score when there are measured features
        // behind it. AI estimates and "no coverage" results have none.
        if (shownContributions.isNotEmpty) ...[
          const Text(
            'WHY THIS SCORE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 8),
          ...shownContributions.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.isPositive
                            ? AppColors.safeGreen
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.displayName,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      c.valueLabel,
                      style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
                    ),
                  ],
                ),
              )),
        ],
        const SizedBox(height: 4),
        _ScoreSourceBadge(source: result.source),
      ],
    );
  }
}

/// States where the number actually came from.
///
/// The previous badge said "Offline estimate" for every non-ONNX result, which
/// was wrong in both directions: it appeared when the device model simply
/// failed to load (nothing to do with being offline), and it hid the difference
/// between a real measurement, a distant fallback, and an AI guess.
class _ScoreSourceBadge extends StatelessWidget {
  final ScoreSource source;
  const _ScoreSourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color color;
    late final String label;

    switch (source) {
      case ScoreSource.remoteModel:
        icon = Icons.groups_rounded;
        color = AppColors.safeGreen;
        label = 'Live data — includes community reports';
      case ScoreSource.onDeviceModel:
        icon = Icons.memory;
        color = AppColors.safeGreen;
        label = 'On-device AI';
      case ScoreSource.cachedGrid:
        icon = Icons.offline_bolt_rounded;
        color = AppColors.warningAmber;
        label = 'Offline data — on-device AI unavailable';
      case ScoreSource.aiEstimate:
        icon = Icons.auto_awesome;
        color = AppColors.warningAmber;
        label = 'AI estimate — not from the trained model';
      case ScoreSource.unavailable:
        icon = Icons.help_outline_rounded;
        color = AppColors.subtitle;
        label = 'No safety data for this location';
    }

    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ),
      ],
    );
  }
}

// ── 4c. Quick actions ─────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final ValueChanged<int> onSelectTab;
  const _QuickActions({required this.onSelectTab});

  Future<void> _sendSos(BuildContext context) async {
    await context.read<GuardianViewModel>().updateCurrentLocation(triggerSms: true);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SOS sent to your guardian.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            icon: Icons.sos_rounded,
            label: 'SOS',
            filled: true,
            onTap: () => _sendSos(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.alt_route_rounded,
            label: 'Safe Route',
            filled: false,
            onTap: () => onSelectTab(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.campaign_rounded,
            label: 'Report',
            filled: false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IncidentScreen()),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : AppColors.primary;
    return Material(
      color: filled ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: fg),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 4d. Nearest safe spot ─────────────────────────────────────────────────────

class _NearestSafeSpotCard extends StatelessWidget {
  final SafeSpot spot;
  final VoidCallback onTap;
  const _NearestSafeSpotCard({required this.spot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.safeGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    spot.category.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NEAREST SAFE SPOT',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.subtitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      spot.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${spot.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.safeGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 4e. Status strip ──────────────────────────────────────────────────────────

class _StatusStrip extends StatelessWidget {
  final GuardianViewModel guardianVm;
  const _StatusStrip({required this.guardianVm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _StatusRow(
            icon: guardianVm.isGuardianConfigured
                ? Icons.verified_user_rounded
                : Icons.person_off_rounded,
            iconColor: guardianVm.isGuardianConfigured
                ? AppColors.safeGreen
                : AppColors.warningAmber,
            label: 'Guardian',
            status: guardianVm.isGuardianConfigured
                ? guardianVm.guardian.name
                : 'Not set',
            onTap: guardianVm.isGuardianConfigured
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
          ),
          const SizedBox(height: 10),
          _StatusRow(
            icon: MapTileProvider.isOfflineCacheReady
                ? Icons.cloud_done_rounded
                : Icons.cloud_off_rounded,
            iconColor: MapTileProvider.isOfflineCacheReady
                ? AppColors.safeGreen
                : AppColors.warningAmber,
            label: 'Offline maps',
            status: MapTileProvider.isOfflineCacheReady ? 'Ready' : 'Unavailable',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DownloadOfflineMapsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String status;
  final VoidCallback? onTap;

  const _StatusRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.onSurface),
          ),
        ),
        Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

// ── 4f. Contribute nudge ──────────────────────────────────────────────────────

class _ContributeNudge extends StatelessWidget {
  const _ContributeNudge();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.hoverBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ContributeScreen()),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.volunteer_activism_rounded, color: AppColors.primary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Answer 2 quick questions to help women near you.',
                  style: TextStyle(fontSize: 12.5, height: 1.35),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.subtitle),
            ],
          ),
        ),
      ),
    );
  }
}
