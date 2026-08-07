import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/safe_spot.dart';
import '../../models/safe_spot_submission.dart';
import '../../viewmodels/contribute_viewmodel.dart';
import '../../viewmodels/safe_spot_viewmodel.dart';
import 'suggest_safe_place_screen.dart';

/// Community contribution screen — short yes/no questions about nearby safe
/// spots that help keep the safety data accurate for everyone else.
class ContributeScreen extends StatefulWidget {
  const ContributeScreen({super.key});

  @override
  State<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends State<ContributeScreen> {
  final Set<String> _answered = {};

  /// Guards the build-time re-request below so it fires at most once per
  /// screen visit — without it, the "no candidates left" empty state (spots
  /// non-empty, questions still empty) would re-trigger loadQuestions on
  /// every rebuild.
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final spots = context.read<SafeSpotViewModel>().safeSpots;
      context.read<ContributeViewModel>().loadQuestions(spots);
      context.read<ContributeViewModel>().loadMySubmissions();
    });
  }

  Future<void> _openSuggestSafePlace(
      BuildContext context, ContributeViewModel vm) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SuggestSafePlaceScreen()),
    );
    if (!mounted) return;
    vm.loadMySubmissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contribute'),
        actions: [
          Consumer<ContributeViewModel>(
            builder: (context, vm, _) => IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Suggest a safe place',
              onPressed: () => _openSuggestSafePlace(context, vm),
            ),
          ),
        ],
      ),
      body: Consumer2<ContributeViewModel, SafeSpotViewModel>(
        builder: (context, vm, ssVm, _) {
          // If the screen opened before location resolved, safeSpots was
          // empty on the first load and nothing re-ran loadQuestions. Once
          // spots show up, request questions once per screen visit.
          if (!_requested &&
              ssVm.safeSpots.isNotEmpty &&
              vm.questions.isEmpty &&
              !vm.isLoading) {
            _requested = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              vm.loadQuestions(ssVm.safeSpots);
            });
          }
          final Widget content;
          if (vm.isLoading) {
            content = const Center(child: CircularProgressIndicator());
          } else if (vm.questions.isEmpty) {
            content = vm.hasNearbySpots
                ? const _EmptyState(
                    icon: Icons.volunteer_activism_rounded,
                    title: 'All caught up',
                    message:
                        'You\'ve already helped with every spot near you. '
                        'Check back in a few weeks.',
                  )
                : const _EmptyState(
                    icon: Icons.explore_off_rounded,
                    title: 'Nothing to verify right now',
                    message:
                        'Set your location on the map to find safe spots '
                        'near you, then come back to help others.',
                  );
          } else if (vm.isComplete) {
            content = const _EmptyState(
              icon: Icons.volunteer_activism_rounded,
              title: 'Thank you!',
              message:
                  'Your answers make these safe spots more reliable for every '
                  'woman using Suraksha.',
            );
          } else {
            content = ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                const Text(
                  'Help others stay safe',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Answer a couple of quick questions about places near you.',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.subtitle, height: 1.4),
                ),
                const SizedBox(height: 20),
                _ProgressRow(
                  answered: vm.answeredCount,
                  total: vm.questions.length,
                ),
                const SizedBox(height: 20),
                for (final question in vm.questions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _QuestionCard(
                      question: question,
                      isAnswered: _answered.contains(question.spotId),
                      onAnswer: (value) {
                        setState(() => _answered.add(question.spotId));
                        vm.answer(question, value);
                      },
                    ),
                  ),
              ],
            );
          }

          return Column(
            children: [
              Expanded(child: content),
              if (vm.mySubmissions.isNotEmpty)
                _MySubmissionsSection(submissions: vm.mySubmissions),
            ],
          );
        },
      ),
    );
  }
}

// ── Progress row ─────────────────────────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  final int answered;
  final int total;

  const _ProgressRow({required this.answered, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : answered / total,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$answered/$total answered',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitle,
          ),
        ),
      ],
    );
  }
}

// ── Question card ────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final ContributeQuestion question;
  final bool isAnswered;
  final ValueChanged<bool> onAnswer;

  const _QuestionCard({
    required this.question,
    required this.isAnswered,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.spot.category.label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          if (isAnswered)
            const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 18, color: AppColors.safeGreen),
                SizedBox(width: 8),
                Text(
                  'Thanks — recorded',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.safeGreen),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onAnswer(true),
                    child: const Text('Yes'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onAnswer(false),
                    child: const Text('No'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Empty / done state ───────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.primary),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.subtitle, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Your suggestions ─────────────────────────────────────────────────────────

class _MySubmissionsSection extends StatelessWidget {
  final List<SafeSpotSubmission> submissions;

  const _MySubmissionsSection({required this.submissions});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        shrinkWrap: true,
        children: [
          const Text(
            'YOUR SUGGESTIONS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 10),
          for (final submission in submissions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      submission.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusPill(status: submission.status),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  Color get _color {
    switch (status) {
      case 'pending':
        return AppColors.warningAmber;
      case 'approved':
        return AppColors.safeGreen;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label =
        status.isEmpty ? status : status[0].toUpperCase() + status.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
