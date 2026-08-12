import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../reports/data/datasources/reports_datasource.dart';
import '../../../reports/domain/models/report_data.dart';
import '../../domain/entities/financial_tip.dart';
import '../../domain/insights_engine.dart';

/// Dashboard section that shows locally-generated financial tips.
///
/// Loads the current month's [ReportData] once (reusing the reports
/// datasource) and runs [InsightsEngine] on it — no extra services, no cost.
/// Renders nothing until there is at least one tip to show.
class TipsSection extends StatefulWidget {
  final String userId;

  const TipsSection({super.key, required this.userId});

  @override
  State<TipsSection> createState() => _TipsSectionState();
}

class _TipsSectionState extends State<TipsSection> {
  late final Future<List<FinancialTip>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadTips();
  }

  Future<List<FinancialTip>> _loadTips() async {
    final now = DateTime.now();
    final ReportData data =
        await getIt<ReportsDataSource>().loadReport(widget.userId, now.year, now.month);
    return InsightsEngine.generate(data);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FinancialTip>>(
      future: _future,
      builder: (context, snapshot) {
        final tips = snapshot.data ?? const <FinancialTip>[];
        // Stay invisible while loading or when there is nothing to say.
        if (tips.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePadding, 0, AppDimensions.pagePadding, AppDimensions.sm,
              ),
              child: Row(
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 18)),
                  Text('Consejos para ti', style: AppTextStyles.headlineSmall),
                ],
              ),
            ),
            if (tips.length == 1)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.pagePadding),
                child: _TipCard(tip: tips.first),
              )
            else
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.pagePadding),
                  itemCount: tips.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppDimensions.sm),
                  itemBuilder: (_, i) => SizedBox(
                    width: MediaQuery.of(context).size.width * 0.82,
                    child: _TipCard(tip: tips[i]),
                  ),
                ),
              ),
            const SizedBox(height: AppDimensions.lg),
          ],
        );
      },
    );
  }
}

class _TipCard extends StatelessWidget {
  final FinancialTip tip;

  const _TipCard({required this.tip});

  Color _accent(BuildContext context) {
    switch (tip.severity) {
      case TipSeverity.positive:
        return AppColors.success;
      case TipSeverity.warning:
        return AppColors.warning;
      case TipSeverity.danger:
        return AppColors.danger;
      case TipSeverity.info:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    final canTap = tip.actionRoute != null && tip.actionLabel != null;

    return GestureDetector(
      onTap: canTap ? () => context.push(tip.actionRoute!) : null,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(tip.emoji, style: const TextStyle(fontSize: 17)),
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    tip.title,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Expanded(
              child: Text(
                tip.message,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (canTap) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    tip.actionLabel!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward, size: 13, color: accent),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
