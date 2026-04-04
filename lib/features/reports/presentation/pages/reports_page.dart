import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/models/report_data.dart';
import '../cubit/reports_cubit.dart';
import '../widgets/expense_donut_chart.dart';
import '../widgets/category_horizontal_bars.dart';
import '../widgets/trend_line_chart.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    final userId = user?.uid ?? '';
    final householdId = user?.householdId;
    return BlocProvider(
      create: (_) => ReportsCubit(getIt())..load(userId),
      child: _ReportsView(userId: userId, householdId: householdId),
    );
  }
}

class _ReportsView extends StatelessWidget {
  final String userId;
  final String? householdId;
  const _ReportsView({required this.userId, this.householdId});

  static const _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          BlocBuilder<ReportsCubit, ReportsState>(
            builder: (context, state) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (householdId != null)
                    _ModeToggle(
                      mode: state.mode,
                      onChanged: (m) => context
                          .read<ReportsCubit>()
                          .switchMode(userId, m, householdId),
                    ),
                  if (state.data != null)
                    IconButton(
                      icon: const Icon(Icons.copy_outlined),
                      tooltip: 'Copiar resumen',
                      onPressed: () => _copyReport(context, state),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          if (state.isLoading || state.status == ReportsStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == ReportsStatus.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.grey400),
                  const SizedBox(height: AppDimensions.sm),
                  Text(state.errorMessage ?? 'Error',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.grey500)),
                  const SizedBox(height: AppDimensions.md),
                  ElevatedButton(
                    onPressed: () => context.read<ReportsCubit>().load(userId,
                        month: state.month,
                        year: state.year,
                        mode: state.mode,
                        householdId: householdId),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final data = state.data!;
          return ListView(
            padding: const EdgeInsets.all(AppDimensions.pagePadding),
            children: [
              // ── Period selector ──────────────────────────────────────────
              _buildPeriodSelector(context, state),
              const SizedBox(height: AppDimensions.lg),

              // ── Summary cards ────────────────────────────────────────────
              _buildSummaryCards(data),
              const SizedBox(height: AppDimensions.md),

              // ── Highlight cards: top expense & top income ────────────────
              if (data.topExpense != null || data.topIncome != null) ...[
                _buildHighlightCards(data),
                const SizedBox(height: AppDimensions.md),
              ],

              // ── Expense donut chart ──────────────────────────────────────
              _Card(
                child: ExpenseDonutChart(
                  categories: data.expensesByCategory,
                  total: data.totalExpenses,
                  title: 'Distribución de gastos',
                ),
              ),
              const SizedBox(height: AppDimensions.md),

              // ── Expense horizontal bars ──────────────────────────────────
              _Card(
                child: CategoryHorizontalBars(
                  categories: data.expensesByCategory,
                  total: data.totalExpenses,
                  title: 'Gastos por categoría',
                  barColor: AppColors.danger,
                ),
              ),
              const SizedBox(height: AppDimensions.md),

              // ── Income horizontal bars ───────────────────────────────────
              if (data.incomeByCategory.isNotEmpty || data.totalIncome == 0) ...[
                _Card(
                  child: CategoryHorizontalBars(
                    categories: data.incomeByCategory,
                    total: data.totalIncome,
                    title: 'Ingresos por categoría',
                    barColor: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppDimensions.md),
              ],

              // ── Trend line chart ─────────────────────────────────────────
              _Card(
                child: TrendLineChart(trend: data.trend),
              ),
              const SizedBox(height: AppDimensions.md),

              // ── Goals progress ───────────────────────────────────────────
              if (data.goals.isNotEmpty) ...[
                _buildGoalsSection(context, data),
                const SizedBox(height: AppDimensions.md),
              ],

              const SizedBox(height: AppDimensions.xl),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, ReportsState state) {
    final cubit = context.read<ReportsCubit>();
    final now = DateTime.now();
    final canGoForward =
        !(state.month == now.month && state.year == now.year);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            final prev = DateTime(state.year, state.month - 1);
            cubit.load(userId,
                month: prev.month,
                year: prev.year,
                mode: state.mode,
                householdId: householdId);
          },
        ),
        Text(
          '${_monthNames[state.month - 1]} ${state.year}',
          style: AppTextStyles.headlineSmall,
        ),
        IconButton(
          icon: Icon(Icons.chevron_right,
              color: canGoForward ? null : AppColors.grey300),
          onPressed: canGoForward
              ? () {
                  final next = DateTime(state.year, state.month + 1);
                  cubit.load(userId,
                      month: next.month,
                      year: next.year,
                      mode: state.mode,
                      householdId: householdId);
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildSummaryCards(ReportData data) {
    final net = data.netBalance;
    final netColor = net >= 0 ? AppColors.success : AppColors.danger;
    return Row(
      children: [
        Expanded(
            child: _SummaryCard(
          label: 'Ingresos',
          amount: data.totalIncome,
          color: AppColors.success,
          icon: Icons.trending_up,
        )),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
            child: _SummaryCard(
          label: 'Gastos',
          amount: data.totalExpenses,
          color: AppColors.danger,
          icon: Icons.trending_down,
        )),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
            child: _SummaryCard(
          label: 'Neto',
          amount: net.abs(),
          color: netColor,
          icon: net >= 0
              ? Icons.savings_outlined
              : Icons.warning_amber_outlined,
          prefix: net >= 0 ? '+' : '-',
        )),
      ],
    );
  }

  Widget _buildHighlightCards(ReportData data) {
    return Row(
      children: [
        if (data.topExpense != null)
          Expanded(
            child: _HighlightCard(
              label: 'Mayor gasto',
              categoryData: data.topExpense!,
              color: AppColors.danger,
            ),
          ),
        if (data.topExpense != null && data.topIncome != null)
          const SizedBox(width: AppDimensions.sm),
        if (data.topIncome != null)
          Expanded(
            child: _HighlightCard(
              label: 'Mayor ingreso',
              categoryData: data.topIncome!,
              color: AppColors.success,
            ),
          ),
      ],
    );
  }

  Widget _buildGoalsSection(BuildContext context, ReportData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 18)),
            const SizedBox(width: AppDimensions.sm),
            Text('Metas activas', style: AppTextStyles.headlineSmall),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        ...data.goals.map((g) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
              child: _GoalCard(goal: g),
            )),
      ],
    );
  }

  void _copyReport(BuildContext context, ReportsState state) {
    final d = state.data!;
    final buf = StringBuffer()
      ..writeln(
          '📊 Reporte FinTrack — ${_monthNames[state.month - 1]} ${state.year}')
      ..writeln('─────────────────────────')
      ..writeln('Ingresos:  ${CurrencyFormatter.format(d.totalIncome)}')
      ..writeln('Gastos:    ${CurrencyFormatter.format(d.totalExpenses)}')
      ..writeln('Neto:      ${CurrencyFormatter.format(d.netBalance)}')
      ..writeln()
      ..writeln('Gastos por categoría:');
    for (final cat in d.expensesByCategory) {
      buf.writeln('  ${cat.category.icon} ${cat.category.label}: '
          '${CurrencyFormatter.format(cat.amount)} '
          '(${(cat.percentage * 100).toStringAsFixed(0)}%)');
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resumen copiado al portapapeles')),
    );
  }
}

// ── Mode Toggle ───────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  final ReportMode mode;
  final ValueChanged<ReportMode> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: SegmentedButton<ReportMode>(
        style: SegmentedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: const TextStyle(fontSize: 11),
          visualDensity: VisualDensity.compact,
        ),
        segments: const [
          ButtonSegment(
            value: ReportMode.personal,
            label: Text('Personal'),
            icon: Icon(Icons.person_outline, size: 14),
          ),
          ButtonSegment(
            value: ReportMode.household,
            label: Text('Hogar'),
            icon: Icon(Icons.home_outlined, size: 14),
          ),
        ],
        selected: {mode},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

// ── Shared card wrapper ───────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: child,
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final String prefix;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.sm + 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            '$prefix${CurrencyFormatter.format(amount, compact: true)}',
            style: AppTextStyles.monoSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.grey500, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Highlight Card ────────────────────────────────────────────────────────────

class _HighlightCard extends StatelessWidget {
  final String label;
  final CategoryData categoryData;
  final Color color;

  const _HighlightCard({
    required this.label,
    required this.categoryData,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md, vertical: AppDimensions.sm + 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(categoryData.category.icon,
              style: const TextStyle(fontSize: 24)),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey500, fontSize: 10)),
                Text(
                  categoryData.category.label,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  CurrencyFormatter.format(categoryData.amount,
                      compact: true),
                  style: AppTextStyles.monoSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
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

// ── Goal Card ─────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final GoalProgressData goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final pct = (goal.progress * 100).toStringAsFixed(0);
    final daysLeft = goal.targetDate != null
        ? goal.targetDate!.difference(DateTime.now()).inDays
        : null;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(goal.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  goal.name,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$pct%',
                style: AppTextStyles.monoSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation<Color>(
                goal.progress >= 0.8
                    ? AppColors.success
                    : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.xs),
          Row(
            children: [
              Text(
                '${CurrencyFormatter.format(goal.currentAmount, compact: true)} '
                'de ${CurrencyFormatter.format(goal.targetAmount, compact: true)}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.grey500),
              ),
              const Spacer(),
              if (daysLeft != null)
                Text(
                  daysLeft > 0
                      ? '$daysLeft días restantes'
                      : daysLeft == 0
                          ? '¡Vence hoy!'
                          : 'Vencida',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: daysLeft <= 7
                        ? AppColors.warning
                        : AppColors.grey500,
                    fontWeight: daysLeft <= 7
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
            ],
          ),
          if (goal.remaining > 0) ...[
            const SizedBox(height: AppDimensions.xs),
            Text(
              'Faltan ${CurrencyFormatter.format(goal.remaining, compact: true)} para completar la meta',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.grey400,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
