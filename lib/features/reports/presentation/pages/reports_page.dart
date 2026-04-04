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
import '../widgets/monthly_bar_chart.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthBloc>().state.user?.uid ?? '';
    return BlocProvider(
      create: (_) => ReportsCubit(getIt())..load(userId),
      child: _ReportsView(userId: userId),
    );
  }
}

class _ReportsView extends StatelessWidget {
  final String userId;
  const _ReportsView({required this.userId});

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
              if (state.data == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.copy_outlined),
                tooltip: 'Copiar resumen',
                onPressed: () => _copyReport(context, state),
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
                  const Icon(Icons.error_outline, size: 48, color: AppColors.grey400),
                  const SizedBox(height: AppDimensions.sm),
                  Text(state.errorMessage ?? 'Error',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.grey500)),
                  const SizedBox(height: AppDimensions.md),
                  ElevatedButton(
                    onPressed: () => context
                        .read<ReportsCubit>()
                        .load(userId, month: state.month, year: state.year),
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
              // ── Period selector ─────────────────────────────────────────
              _buildPeriodSelector(context, state),
              const SizedBox(height: AppDimensions.lg),

              // ── Summary cards ────────────────────────────────────────────
              _buildSummaryCards(data),
              const SizedBox(height: AppDimensions.lg),

              // ── Expense donut (UC-27) ────────────────────────────────────
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  child: ExpenseDonutChart(
                    categories: data.expensesByCategory,
                    total: data.totalExpenses,
                    title: 'Gastos por categoría',
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.md),

              // ── Income donut ─────────────────────────────────────────────
              if (data.incomeByCategory.isNotEmpty)
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    child: ExpenseDonutChart(
                      categories: data.incomeByCategory,
                      total: data.totalIncome,
                      title: 'Ingresos por categoría',
                    ),
                  ),
                ),
              if (data.incomeByCategory.isNotEmpty)
                const SizedBox(height: AppDimensions.md),

              // ── Monthly bar chart (UC-28, UC-29) ─────────────────────────
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  child: MonthlyBarChart(trend: data.trend),
                ),
              ),
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
    final canGoForward = !(state.month == now.month && state.year == now.year);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            final prev = DateTime(state.year, state.month - 1);
            cubit.load(userId, month: prev.month, year: prev.year);
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
                  cubit.load(userId, month: next.month, year: next.year);
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
          icon: net >= 0 ? Icons.savings_outlined : Icons.warning_amber_outlined,
          prefix: net >= 0 ? '+' : '-',
        )),
      ],
    );
  }

  // UC-30: Copy text summary to clipboard
  void _copyReport(BuildContext context, ReportsState state) {
    final d = state.data!;
    final buf = StringBuffer()
      ..writeln('📊 Reporte FinTrack — ${_monthNames[state.month - 1]} ${state.year}')
      ..writeln('─────────────────────────')
      ..writeln('Ingresos:  ${CurrencyFormatter.format(d.totalIncome)}')
      ..writeln('Gastos:    ${CurrencyFormatter.format(d.totalExpenses)}')
      ..writeln('Neto:      ${CurrencyFormatter.format(d.netBalance)}')
      ..writeln()
      ..writeln('Gastos por categoría:');
    for (final cat in d.expensesByCategory) {
      buf.writeln(
          '  ${cat.category.icon} ${cat.category.label}: '
          '${CurrencyFormatter.format(cat.amount)} '
          '(${(cat.percentage * 100).toStringAsFixed(0)}%)');
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resumen copiado al portapapeles')),
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
