import 'package:flutter/material.dart';
import '../../models/safety_score_result.dart';
import '../../models/safety_grid_entry.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Bottom sheet shown when user taps a location.
/// Full XAI panel:
///   1. Score ring + risk badge
///   2. AI summary sentence
///   3. Per-factor contribution bars (centre-anchored) with raw values
///   4. Natural language explanations (expandable)
///   5. Dominant factor callouts
///   6. Improvement tips for Medium/High risk
///   7. Report incident CTA
class SafetyScoreCard extends StatefulWidget {
  final SafetyScoreResult result;
  final SafetyGridEntry? gridEntry;
  final VoidCallback onClose;
  final VoidCallback onReportIncident;

  const SafetyScoreCard({
    super.key,
    required this.result,
    this.gridEntry,
    required this.onClose,
    required this.onReportIncident,
  });

  @override
  State<SafetyScoreCard> createState() => _SafetyScoreCardState();
}

class _SafetyScoreCardState extends State<SafetyScoreCard> {
  bool _showDetails = false;

  static IconData _sourceIcon(ScoreSource source) {
    switch (source) {
      case ScoreSource.remoteModel:
        return Icons.groups_rounded;
      case ScoreSource.onDeviceModel:
        return Icons.memory;
      case ScoreSource.cachedGrid:
        return Icons.cached;
      case ScoreSource.aiEstimate:
        return Icons.auto_awesome;
      case ScoreSource.unavailable:
        return Icons.help_outline_rounded;
    }
  }

  static Color _sourceColor(ScoreSource source) {
    switch (source) {
      case ScoreSource.remoteModel:
      case ScoreSource.onDeviceModel:
        return AppColors.safeGreen;
      case ScoreSource.cachedGrid:
      case ScoreSource.aiEstimate:
        return AppColors.warningAmber;
      case ScoreSource.unavailable:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final scoreColor = AppColors.forScore(result.score);

    // Name the area only when the nearest known centroid is actually close.
    // The grid holds one point per area, so the nearest one can be most of a
    // city away — titling the sheet with it claimed a location we do not know.
    final entry = widget.gridEntry;
    final referenceKm = result.referenceDistanceKm;
    final isNamedArea = entry != null &&
        referenceKm != null &&
        referenceKm <= AppConstants.areaLabelMaxKm;
    final areaLabel =
        isNamedArea ? '${entry.area}, ${entry.city}' : 'Selected Location';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(blurRadius: 20, color: Colors.black26, offset: Offset(0, -2))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ─────────────────────────────────────────────────
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
          const SizedBox(height: 4),

          // ── Scrollable content ──────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              areaLabel,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _StatusChip(
                                  label: result.sourceLabel,
                                  icon: _sourceIcon(result.source),
                                  color: _sourceColor(result.source),
                                ),
                                // State the distance whenever the score comes
                                // from an area that is not the user's own.
                                if (!isNamedArea && entry != null && referenceKm != null)
                                  _StatusChip(
                                    label:
                                        'Nearest data ${referenceKm.toStringAsFixed(0)} km away',
                                    icon: Icons.near_me_outlined,
                                    color: AppColors.warningAmber,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: widget.onClose,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Score card ─────────────────────────────────────────
                  _ScoreCard(result: result, scoreColor: scoreColor),
                  const SizedBox(height: 14),

                  // ── AI Summary ─────────────────────────────────────────
                  if (result.summaryExplanation.isNotEmpty) ...[
                    _AISummaryBanner(
                      summary: result.summaryExplanation,
                      riskLevel: result.riskLevel,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Factor breakdown ───────────────────────────────────
                  if (result.contributions.isNotEmpty) ...[
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Why this score',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'AI-computed factor contributions',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.black45),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _showDetails = !_showDetails),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _showDetails ? 'Less' : 'More detail',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...result.contributions.map(
                      (c) => _FactorRow(
                        contribution: c,
                        showDetail: _showDetails,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Dominant factor callouts
                    if (result.topRiskFactor != null)
                      _FactorCallout(
                        label: 'Biggest risk',
                        factor: result.topRiskFactor!,
                        color: AppColors.dangerRed,
                        icon: Icons.warning_amber_rounded,
                      ),
                    if (result.topSafetyFactor != null)
                      _FactorCallout(
                        label: 'Biggest asset',
                        factor: result.topSafetyFactor!,
                        color: AppColors.safeGreen,
                        icon: Icons.shield_outlined,
                      ),
                  ],

                  // ── Tips ──────────────────────────────────────────────
                  if (result.improvementTips.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _TipsSection(tips: result.improvementTips),
                  ],

                  const SizedBox(height: 18),

                  // ── Report CTA ─────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onReportIncident,
                      icon: const Icon(Icons.report_problem_outlined, size: 18),
                      label: const Text('Report an Incident Here'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
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

// ── Score card ─────────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final SafetyScoreResult result;
  final Color scoreColor;

  const _ScoreCard({required this.result, required this.scoreColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          // Score ring
          SizedBox(
            width: 66,
            height: 66,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: result.score,
                  strokeWidth: 7,
                  backgroundColor: scoreColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
                Center(
                  child: Text(
                    (result.score * 100).toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.riskLabel,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Score: ${(result.score * 100).toStringAsFixed(0)} / 100',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                const Row(
                  children: [
                    _RiskLegendDot(
                        color: AppColors.safeGreen, label: '≥75 Safe'),
                    SizedBox(width: 8),
                    _RiskLegendDot(
                        color: AppColors.warningAmber, label: '50–74'),
                    SizedBox(width: 8),
                    _RiskLegendDot(
                        color: AppColors.dangerRed, label: '<50 High'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskLegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _RiskLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: Colors.black45)),
      ],
    );
  }
}

// ── AI Summary ─────────────────────────────────────────────────────────────────

class _AISummaryBanner extends StatelessWidget {
  final String summary;
  final String riskLevel;

  const _AISummaryBanner({required this.summary, required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    final color = riskLevel == 'Low'
        ? AppColors.safeGreen
        : riskLevel == 'Medium'
            ? AppColors.warningAmber
            : AppColors.dangerRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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
                  'AI EXPLANATION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  summary,
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
    );
  }
}

// ── Factor row ─────────────────────────────────────────────────────────────────

class _FactorRow extends StatelessWidget {
  final FeatureContribution contribution;
  final bool showDetail;

  const _FactorRow({required this.contribution, required this.showDetail});

  @override
  Widget build(BuildContext context) {
    final c = contribution;
    final hasContrib = c.contribution != 0;
    final barColor = hasContrib
        ? (c.isPositive ? AppColors.safeGreen : AppColors.dangerRed)
        : Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + value + score
          Row(
            children: [
              Text(c.iconAsset,
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  c.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Raw value badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  c.valueLabel,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 48,
                child: Text(
                  hasContrib
                      ? '${c.isPositive ? '+' : ''}${c.contribution.toStringAsFixed(2)}'
                      : '—',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: barColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Centre-anchored contribution bar
          _CentreBar(
            magnitude: c.normalizedMagnitude,
            isPositive: c.isPositive,
            hasContrib: hasContrib,
            color: barColor,
          ),

          // Natural language detail (expandable)
          if (showDetail && c.explanation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 22),
              child: Text(
                c.explanation,
                style: const TextStyle(
                    fontSize: 11, color: Colors.black45, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }
}

class _CentreBar extends StatelessWidget {
  final double magnitude;
  final bool isPositive;
  final bool hasContrib;
  final Color color;

  const _CentreBar({
    required this.magnitude,
    required this.isPositive,
    required this.hasContrib,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final totalWidth = constraints.maxWidth;
      final half = totalWidth / 2;
      final barWidth = (half * magnitude).clamp(2.0, half);

      return SizedBox(
        height: 9,
        child: Stack(
          children: [
            // Background
            Container(
              height: 9,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Centre marker
            Positioned(
              left: half - 1,
              child: Container(width: 2, height: 9, color: Colors.grey[400]),
            ),
            // Fill bar
            if (hasContrib)
              Positioned(
                left: isPositive ? half : half - barWidth,
                child: Container(
                  width: barWidth,
                  height: 9,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ── Dominant factor callout ────────────────────────────────────────────────────

class _FactorCallout extends StatelessWidget {
  final String label;
  final FeatureContribution factor;
  final Color color;
  final IconData icon;

  const _FactorCallout({
    required this.label,
    required this.factor,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text('$label: ',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
          Text(
            '${factor.iconAsset} ${factor.displayName} (${factor.valueLabel})',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// ── Tips section ───────────────────────────────────────────────────────────────

class _TipsSection extends StatelessWidget {
  final List<String> tips;
  const _TipsSection({required this.tips});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.warningAmber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  size: 14, color: AppColors.warningAmber),
              SizedBox(width: 6),
              Text(
                'Safety Tips',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warningAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(
                          color: AppColors.warningAmber, fontSize: 13)),
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
    );
  }
}

// ── Status chip ────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusChip(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
