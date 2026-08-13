import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/cubit/theme_cubit.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../budgets/data/datasources/budget_datasource.dart';
import '../../../budgets/domain/budget_calculator.dart';
import '../../../budgets/domain/entities/budget.dart';
import '../../../budgets/presentation/widgets/budgets_report_section.dart';
import '../../domain/models/report_data.dart';
import '../cubit/reports_cubit.dart';
import '../widgets/expense_donut_chart.dart';
import '../widgets/category_horizontal_bars.dart';
import '../widgets/trend_line_chart.dart';
import '../widgets/daily_bar_chart.dart';
import '../utils/report_pdf_generator.dart';

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

  /// Caps are measured against the month being exported, so the PDF says the
  /// same thing the screen does.
  Future<void> _sharePdf(ReportData data) async {
    var budgets = const BudgetSummary([]);
    if (userId.isNotEmpty) {
      try {
        budgets = BudgetCalculator.summarize(
          budgets: await getIt<BudgetDataSource>().getBudgets(userId),
          spendingByCategory: data.expensesByCategory,
        );
      } catch (_) {
        // Export the report without the caps rather than failing outright.
      }
    }
    await ReportPdfGenerator.shareReport(data, budgets: budgets);
  }

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
                  if (state.data != null) ...[
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      tooltip: 'Descargar PDF',
                      onPressed: () => _sharePdf(state.data!),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_outlined),
                      tooltip: 'Copiar resumen',
                      onPressed: () => _copyReport(context, state),
                    ),
                  ],
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
              _buildSummaryCards(context, data),
              const SizedBox(height: AppDimensions.md),

              // ── Highlight cards: top expense & top income ────────────────
              if (data.topExpense != null || data.topIncome != null) ...[
                _buildHighlightCards(context, data),
                const SizedBox(height: AppDimensions.md),
              ],

              // ── Topes de gasto (solo modo personal: los topes son tuyos) ─
              if (state.mode != ReportMode.household && userId.isNotEmpty) ...[
                BudgetsReportSection(userId: userId, data: data),
              ],

              // ── Member breakdown (household mode only) ──────────────────
              if (state.mode == ReportMode.household && householdId != null) ...[
                _HouseholdMemberBreakdown(
                  householdId: householdId!,
                  year: state.year,
                  month: state.month,
                ),
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
              Builder(builder: (ctx) {
                final p = AppColorPalette.fromType(ctx.read<ThemeCubit>().state);
                return _Card(
                  child: CategoryHorizontalBars(
                    categories: data.expensesByCategory,
                    total: data.totalExpenses,
                    title: 'Gastos por categoría',
                    barColor: p.expense,
                  ),
                );
              }),
              const SizedBox(height: AppDimensions.md),

              // ── Income horizontal bars ───────────────────────────────────
              if (data.incomeByCategory.isNotEmpty || data.totalIncome == 0) ...[
                Builder(builder: (ctx) {
                  final p = AppColorPalette.fromType(ctx.read<ThemeCubit>().state);
                  return _Card(
                    child: CategoryHorizontalBars(
                      categories: data.incomeByCategory,
                      total: data.totalIncome,
                      title: 'Ingresos por categoría',
                      barColor: p.income,
                    ),
                  );
                }),
                const SizedBox(height: AppDimensions.md),
              ],

              // ── Daily bar chart ──────────────────────────────────────────
              if (data.daily.isNotEmpty)
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Actividad diaria',
                          style: AppTextStyles.headlineSmall),
                      const SizedBox(height: AppDimensions.sm),
                      DailyBarChart(data: data.daily),
                    ],
                  ),
                ),
              if (data.daily.isNotEmpty) const SizedBox(height: AppDimensions.md),

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

  Widget _buildSummaryCards(BuildContext context, ReportData data) {
    final palette = AppColorPalette.fromType(context.read<ThemeCubit>().state);
    final net = data.netBalance;
    final netColor = net >= 0 ? palette.income : palette.expense;
    return Row(
      children: [
        Expanded(
            child: _SummaryCard(
          label: 'Ingresos',
          amount: data.totalIncome,
          color: palette.income,
          icon: Icons.trending_up,
        )),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
            child: _SummaryCard(
          label: 'Gastos',
          amount: data.totalExpenses,
          color: palette.expense,
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

  Widget _buildHighlightCards(BuildContext context, ReportData data) {
    final palette = AppColorPalette.fromType(context.read<ThemeCubit>().state);
    return Row(
      children: [
        if (data.topExpense != null)
          Expanded(
            child: _HighlightCard(
              label: 'Mayor gasto',
              categoryData: data.topExpense!,
              color: palette.expense,
            ),
          ),
        if (data.topExpense != null && data.topIncome != null)
          const SizedBox(width: AppDimensions.sm),
        if (data.topIncome != null)
          Expanded(
            child: _HighlightCard(
              label: 'Mayor ingreso',
              categoryData: data.topIncome!,
              color: palette.income,
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

  Future<void> _copyReport(BuildContext context, ReportsState state) async {
    final d = state.data!;
    final buf = StringBuffer()
      ..writeln(
          'Reporte Fimakyp — ${_monthNames[state.month - 1]} ${state.year}')
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
    if (d.incomeByCategory.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('Ingresos por categoría:');
      for (final cat in d.incomeByCategory) {
        buf.writeln('  ${cat.category.icon} ${cat.category.label}: '
            '${CurrencyFormatter.format(cat.amount)} '
            '(${(cat.percentage * 100).toStringAsFixed(0)}%)');
      }
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resumen copiado al portapapeles')),
      );
    }
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
    final daysLeft = goal.targetDate?.difference(DateTime.now()).inDays;

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
              Builder(builder: (ctx) {
                final p = AppColorPalette.fromType(ctx.read<ThemeCubit>().state);
                return Text(
                  '$pct%',
                  style: AppTextStyles.monoSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: p.primary,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Builder(builder: (ctx) {
            final p = AppColorPalette.fromType(ctx.read<ThemeCubit>().state);
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
                backgroundColor: AppColors.grey200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  goal.progress >= 0.8 ? p.income : p.primary,
                ),
              ),
            );
          }),
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

// ── Household member breakdown ────────────────────────────────────────────────

class _HouseholdMemberBreakdown extends StatefulWidget {
  final String householdId;
  final int year;
  final int month;

  const _HouseholdMemberBreakdown({
    required this.householdId,
    required this.year,
    required this.month,
  });

  @override
  State<_HouseholdMemberBreakdown> createState() =>
      _HouseholdMemberBreakdownState();
}

class _HouseholdMemberBreakdownState
    extends State<_HouseholdMemberBreakdown> {
  late Future<_HouseholdMemberStats> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void didUpdateWidget(_HouseholdMemberBreakdown old) {
    super.didUpdateWidget(old);
    if (old.month != widget.month || old.year != widget.year) {
      setState(() => _future = _fetch());
    }
  }

  Future<_HouseholdMemberStats> _fetch() async {
    final db = FirebaseFirestore.instance;

    final householdDoc =
        await db.collection('households').doc(widget.householdId).get();
    final membersRaw =
        (householdDoc.data()?['members'] as List<dynamic>?) ?? [];
    final members = membersRaw
        .map((m) => _MemberInfo(
              uid: m['uid'] as String? ?? '',
              displayName: m['displayName'] as String? ?? '',
            ))
        .where((m) => m.uid.isNotEmpty)
        .toList();

    final start =
        Timestamp.fromDate(DateTime(widget.year, widget.month, 1));
    final end =
        Timestamp.fromDate(DateTime(widget.year, widget.month + 1, 1));

    final snap = await db
        .collection('households')
        .doc(widget.householdId)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .get();

    final expenses = <String, double>{};

    for (final doc in snap.docs) {
      final d = doc.data();
      final uid = d['userId'] as String? ?? '';
      final amount = (d['amount'] as num?)?.toDouble() ?? 0;
      final type = d['type'] as String? ?? 'expense';
      if (type == 'expense') {
        expenses[uid] = (expenses[uid] ?? 0) + amount;
      }
    }

    return _HouseholdMemberStats(members: members, expenses: expenses);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HouseholdMemberStats>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final stats = snap.data;
        if (stats == null || stats.members.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gastos por miembro', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppDimensions.sm),
            _MemberStatCard(
              members: stats.members,
              amounts: stats.expenses,
              color: AppColorPalette.fromType(context.read<ThemeCubit>().state).expense,
              totalLabel: 'Total gastos',
              emptyText: 'Sin gastos compartidos este mes',
            ),
            const SizedBox(height: AppDimensions.md),
          ],
        );
      },
    );
  }
}

class _MemberStatCard extends StatelessWidget {
  final List<_MemberInfo> members;
  final Map<String, double> amounts;
  final Color color;
  final String totalLabel;
  final String emptyText;

  const _MemberStatCard({
    required this.members,
    required this.amounts,
    required this.color,
    required this.totalLabel,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final total = amounts.values.fold(0.0, (a, b) => a + b);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: total == 0
            ? Text(emptyText,
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.grey400))
            : Column(
                children: [
                  ...members.map((m) {
                    final amount = amounts[m.uid] ?? 0;
                    if (amount == 0) return const SizedBox.shrink();
                    final pct = amount / total;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: color.withOpacity(0.15),
                                child: Text(
                                  m.displayName.isNotEmpty
                                      ? m.displayName[0].toUpperCase()
                                      : '?',
                                  style: AppTextStyles.labelMedium
                                      .copyWith(color: color, fontSize: 11),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(m.displayName,
                                    style: AppTextStyles.bodySmall),
                              ),
                              Text(
                                CurrencyFormatter.format(amount),
                                style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600, color: color),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${(pct * 100).toStringAsFixed(0)}%',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.grey400, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 5,
                              backgroundColor: AppColors.grey200,
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(totalLabel,
                          style: AppTextStyles.bodySmall
                              .copyWith(fontWeight: FontWeight.w600)),
                      Text(CurrencyFormatter.format(total),
                          style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600, color: color)),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _HouseholdMemberStats {
  final List<_MemberInfo> members;
  final Map<String, double> expenses;

  const _HouseholdMemberStats(
      {required this.members, required this.expenses});
}

class _MemberInfo {
  final String uid;
  final String displayName;

  const _MemberInfo({required this.uid, required this.displayName});
}
