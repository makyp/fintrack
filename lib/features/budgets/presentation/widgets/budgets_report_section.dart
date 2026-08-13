import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../reports/domain/models/report_data.dart';
import '../../data/datasources/budget_datasource.dart';
import '../../domain/budget_calculator.dart';
import '../../domain/entities/budget.dart';
import 'budget_progress_tile.dart';

/// "Cómo vas con tus topes" block inside the reports screen.
///
/// Reads the caps directly (they are a handful of documents) and measures them
/// against the report already on screen, so it works for any month the user
/// browses to — not just the current one.
class BudgetsReportSection extends StatefulWidget {
  final String userId;
  final ReportData data;

  const BudgetsReportSection({
    super.key,
    required this.userId,
    required this.data,
  });

  @override
  State<BudgetsReportSection> createState() => _BudgetsReportSectionState();
}

class _BudgetsReportSectionState extends State<BudgetsReportSection> {
  late Future<BudgetSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(BudgetsReportSection old) {
    super.didUpdateWidget(old);
    // The user switched month or mode — remeasure against the new spending.
    if (old.data != widget.data || old.userId != widget.userId) {
      _future = _load();
    }
  }

  Future<BudgetSummary> _load() async {
    final budgets = await getIt<BudgetDataSource>().getBudgets(widget.userId);
    return BudgetCalculator.summarize(
      budgets: budgets,
      spendingByCategory: widget.data.expensesByCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BudgetSummary>(
      future: _future,
      builder: (context, snapshot) {
        final summary = snapshot.data;
        // Nothing configured yet: invite instead of showing an empty block.
        if (summary == null) return const SizedBox.shrink();
        if (summary.isEmpty) return const _NoBudgetsCta();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Cómo vas con tus topes',
                    style: AppTextStyles.headlineSmall),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/budgets'),
                  child: const Text('Ajustar'),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            _Totals(summary: summary),
            const SizedBox(height: AppDimensions.md),
            ...summary.statuses.map((s) => BudgetProgressTile(status: s)),
            const SizedBox(height: AppDimensions.lg),
          ],
        );
      },
    );
  }
}

/// The three numbers the user asked to see: presupuestado, disponible y exceso.
class _Totals extends StatelessWidget {
  final BudgetSummary summary;

  const _Totals({required this.summary});

  @override
  Widget build(BuildContext context) {
    final over = summary.totalOverspent;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        children: [
          _cell('Presupuestado', CurrencyFormatter.format(summary.totalLimit),
              AppColors.grey600),
          _divider(),
          _cell(
            'Disponible',
            CurrencyFormatter.format(summary.totalAvailable),
            AppColors.success,
          ),
          _divider(),
          _cell(
            over > 0 ? 'Te pasaste' : 'Exceso',
            over > 0 ? CurrencyFormatter.format(over) : '\$0',
            over > 0 ? AppColors.danger : AppColors.grey500,
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 32, color: AppColors.grey200);

  Widget _cell(String label, String value, Color color) => Expanded(
        child: Column(
          children: [
            Text(label,
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
            const SizedBox(height: 2),
            Text(value,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelLarge.copyWith(color: color)),
          ],
        ),
      );
}

class _NoBudgetsCta extends StatelessWidget {
  const _NoBudgetsCta();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.lg),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.speed_rounded, color: primary),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              'Ponle un tope mensual a tus categorías y aquí verás cuánto te '
              'queda disponible y en qué te pasaste.',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/budgets'),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}
