import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/thousands_separator_formatter.dart';
import '../../../categories/domain/category_registry.dart';
import '../../../categories/domain/entities/transaction_category.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../domain/entities/budget.dart';
import '../cubit/budgets_cubit.dart';
import '../cubit/budgets_state.dart';
import '../widgets/budget_progress_tile.dart';

/// Set a monthly cap per expense category, and see how this month is going
/// against each one.
class BudgetsPage extends StatefulWidget {
  final String userId;

  const BudgetsPage({super.key, required this.userId});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  late final BudgetsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<BudgetsCubit>();
    _cubit.watchBudgets(widget.userId);
  }

  Future<void> _editLimit(TransactionCategory category, double? current) async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LimitSheet(category: category, current: current),
    );
    if (amount == null) return;
    final ok = await _cubit.setBudget(category.id, amount);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el tope')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: const Text('Topes de gasto')),
        body: BlocBuilder<BudgetsCubit, BudgetsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final summary = state.summary;
            // Only expense categories can have a cap, and only active ones —
            // a hidden category can no longer receive spending.
            final categories =
                CategoryRegistry.forType(TransactionType.expense);
            final withLimit =
                categories.where((c) => state.limitFor(c.id) != null).toList();
            final withoutLimit =
                categories.where((c) => state.limitFor(c.id) == null).toList();

            return RefreshIndicator(
              onRefresh: _cubit.refreshSpending,
              child: ListView(
                padding: const EdgeInsets.all(AppDimensions.pagePadding),
                children: [
                  if (!summary.isEmpty) ...[
                    _SummaryCard(summary: summary),
                    const SizedBox(height: AppDimensions.lg),
                  ] else
                    const _EmptyHint(),

                  if (withLimit.isNotEmpty) ...[
                    Text('CON TOPE',
                        style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.grey500, letterSpacing: 0.8)),
                    const SizedBox(height: AppDimensions.sm),
                    ...summary.statuses.map((s) => BudgetProgressTile(
                          status: s,
                          onTap: () => _editLimit(s.category, s.limit),
                        )),
                    const SizedBox(height: AppDimensions.lg),
                  ],

                  Text('SIN TOPE',
                      style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.grey500, letterSpacing: 0.8)),
                  const SizedBox(height: AppDimensions.sm),
                  ...withoutLimit.map((c) => _AddLimitTile(
                        category: c,
                        onTap: () => _editLimit(c, null),
                      )),
                  const SizedBox(height: AppDimensions.xl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.lg),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.grey500),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              'Ponle un tope mensual a las categorías que se te van de las '
              'manos. Te aviso al llegar al 80% y cuando lo pases.',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final BudgetSummary summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final overspent = summary.totalOverspent;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Este mes, con tus topes',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(summary.totalSpent),
            style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
          ),
          Text(
            'de ${CurrencyFormatter.format(summary.totalLimit)} presupuestados',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppDimensions.md),
          Row(
            children: [
              Expanded(
                child: _stat('Disponible',
                    CurrencyFormatter.format(summary.totalAvailable)),
              ),
              Container(width: 1, height: 34, color: Colors.white24),
              Expanded(
                child: _stat(
                  overspent > 0 ? 'Te pasaste' : 'Sin excesos',
                  overspent > 0
                      ? CurrencyFormatter.format(overspent)
                      : '—',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
          Text(value,
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
        ],
      );
}

class _AddLimitTile extends StatelessWidget {
  final TransactionCategory category;
  final VoidCallback onTap;

  const _AddLimitTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.grey200),
      ),
      child: ListTile(
        leading: Text(category.icon, style: const TextStyle(fontSize: 20)),
        title: Text(category.label, style: AppTextStyles.labelLarge),
        subtitle: Text('Sin tope',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
        trailing: const Icon(Icons.add_circle_outline),
        onTap: onTap,
      ),
    );
  }
}

/// Amount sheet for one category's cap.
class _LimitSheet extends StatefulWidget {
  final TransactionCategory category;
  final double? current;

  const _LimitSheet({required this.category, this.current});

  @override
  State<_LimitSheet> createState() => _LimitSheetState();
}

class _LimitSheetState extends State<_LimitSheet> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.current != null) {
      _ctrl.text = ThousandsSeparatorFormatter()
          .formatEditUpdate(
            TextEditingValue.empty,
            TextEditingValue(text: widget.current!.toStringAsFixed(0)),
          )
          .text;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double? get _parsed {
    final digits = _ctrl.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding,
          AppDimensions.sm,
          AppDimensions.pagePadding,
          AppDimensions.lg,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppDimensions.md),
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(widget.category.icon,
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Text('Tope de ${widget.category.label}',
                        style: AppTextStyles.headlineSmall),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.xs),
              Text('¿Cuánto quieres gastar como máximo al mes?',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey500)),
              const SizedBox(height: AppDimensions.lg),
              TextFormField(
                controller: _ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorFormatter(),
                ],
                style: AppTextStyles.displaySmall,
                decoration: InputDecoration(
                  labelText: 'Tope mensual',
                  prefixText: '\$ ',
                  prefixStyle:
                      AppTextStyles.displaySmall.copyWith(color: primary),
                ),
                validator: (_) =>
                    (_parsed ?? 0) <= 0 ? 'Escribe un monto' : null,
              ),
              const SizedBox(height: AppDimensions.lg),
              Row(
                children: [
                  if (widget.current != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(0.0),
                        child: const Text('Quitar tope'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        Navigator.of(context).pop(_parsed);
                      },
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
