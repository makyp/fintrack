import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/domain/currency_registry.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../categories/domain/category_registry.dart';
import '../../domain/entities/household.dart';
import '../../domain/entities/shared_expense.dart';
import '../../domain/settlement_calculator.dart';
import '../cubit/shared_expenses_cubit.dart';
import 'shared_expense_form_page.dart';

/// Who paid what, and who owes whom.
///
/// The household already shares movements; this is the other half people ask
/// for — one person pays the whole rent and the app keeps the score instead of
/// everyone keeping it in their head.
class SharedExpensesPage extends StatefulWidget {
  final Household household;
  final String userId;

  const SharedExpensesPage({
    super.key,
    required this.household,
    required this.userId,
  });

  @override
  State<SharedExpensesPage> createState() => _SharedExpensesPageState();
}

class _SharedExpensesPageState extends State<SharedExpensesPage> {
  final _cubit = getIt<SharedExpensesCubit>();

  @override
  void initState() {
    super.initState();
    _cubit.watch(
      widget.household.id,
      widget.household.members.map((m) => m.uid).toList(),
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String _nameOf(String uid) {
    final member = widget.household.members
        .where((m) => m.uid == uid)
        .firstOrNull;
    if (member == null) return 'Alguien que ya no está';
    if (uid == widget.userId) return 'Tú';
    final name = member.displayName.trim();
    return name.isEmpty ? member.email : name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: const Text('Gastos compartidos')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openForm,
          icon: const Icon(Icons.add),
          label: const Text('Nuevo gasto'),
        ),
        body: BlocBuilder<SharedExpensesCubit, SharedExpensesState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == SharedExpensesStatus.error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.pagePadding),
                  child: Text(state.errorMessage ?? 'Error',
                      textAlign: TextAlign.center),
                ),
              );
            }
            if (state.expenses.isEmpty && state.settlements.isEmpty) {
              return _buildEmpty();
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppDimensions.pagePadding,
                  AppDimensions.pagePadding, AppDimensions.pagePadding, 96),
              children: [
                _buildBalances(state),
                const SizedBox(height: AppDimensions.xl),
                _buildSettleSection(state),
                const SizedBox(height: AppDimensions.xl),
                Text('Movimientos del hogar',
                    style: AppTextStyles.labelLarge),
                const SizedBox(height: AppDimensions.sm),
                ...state.expenses.map((e) => _buildExpenseTile(e)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 56, color: AppColors.grey400),
            const SizedBox(height: AppDimensions.md),
            Text('Todavía no hay gastos compartidos',
                style: AppTextStyles.labelLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.xs),
            Text(
              'Registra lo que pagó una sola persona y se divide entre '
              'quienes correspondan. La app lleva la cuenta de quién le debe '
              'a quién.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalances(SharedExpensesState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cómo van las cuentas', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppDimensions.sm),
        ...state.balances.map((b) => _buildBalanceRow(b)),
      ],
    );
  }

  Widget _buildBalanceRow(MemberBalance balance) {
    final isMe = balance.uid == widget.userId;
    final Color color;
    final String label;
    if (balance.isSettled) {
      color = AppColors.grey500;
      label = 'Sin deudas';
    } else if (balance.isCreditor) {
      color = AppColors.success;
      label = isMe ? 'Te deben' : 'Le deben';
    } else {
      color = AppColors.danger;
      label = isMe ? 'Debes' : 'Debe';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.15),
            child: Text(
              _nameOf(balance.uid).characters.first.toUpperCase(),
              style: AppTextStyles.labelMedium.copyWith(color: color),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_nameOf(balance.uid), style: AppTextStyles.bodyMedium),
                Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey500)),
              ],
            ),
          ),
          Text(
            balance.isSettled
                ? '—'
                : CurrencyFormatter.format(balance.net.abs()),
            style: AppTextStyles.monoSmall
                .copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSettleSection(SharedExpensesState state) {
    if (state.isSettled) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.success, size: 20),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Text('Todo el mundo está a mano',
                  style: AppTextStyles.bodyMedium),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Para quedar a mano', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppDimensions.xs),
        Text(
          'La forma más corta de saldar todo: ${state.transfers.length} '
          '${state.transfers.length == 1 ? 'pago' : 'pagos'}.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
        ),
        const SizedBox(height: AppDimensions.sm),
        ...state.transfers.map((t) => Card(
              margin: const EdgeInsets.only(bottom: AppDimensions.sm),
              child: ListTile(
                leading: const Icon(Icons.swap_horiz, color: AppColors.primary),
                title: Text('${_nameOf(t.from)} → ${_nameOf(t.to)}'),
                subtitle: Text(CurrencyFormatter.format(t.amount),
                    style: AppTextStyles.monoSmall),
                trailing: TextButton(
                  onPressed: () => _confirmSettle(t),
                  child: const Text('Ya se pagó'),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildExpenseTile(SharedExpense expense) {
    final category = CategoryRegistry.byId(expense.categoryId);
    final myShare = expense.shares[widget.userId] ?? 0;
    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimensions.md),
        color: AppColors.danger,
        child: const Icon(Icons.delete_outline, color: AppColors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(expense),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: AppColors.grey100,
          child: Text(category.icon),
        ),
        title: Text(
          expense.description.isEmpty ? category.label : expense.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Pagó ${_nameOf(expense.paidBy)} · '
          '${DateFormatter.formatShortDate(expense.date)} · '
          '${expense.participants.length} personas',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(expense.amount,
                  code: expense.currency),
              style: AppTextStyles.monoSmall
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            if (myShare > 0)
              Text(
                'te toca ${CurrencyFormatter.format(myShare, code: expense.currency)}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.grey500, fontSize: 10.5),
              ),
          ],
        ),
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _openForm() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: _cubit,
        child: SharedExpenseFormPage(
          household: widget.household,
          userId: widget.userId,
        ),
      ),
    ));
  }

  Future<bool> _confirmDelete(SharedExpense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar el gasto?'),
        content: const Text(
            'Se recalculan los saldos de todos los miembros del hogar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _cubit.deleteExpense(expense.id);
      return true;
    }
    return false;
  }

  Future<void> _confirmSettle(Transfer transfer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Ya se hizo el pago?'),
        content: Text(
          '${_nameOf(transfer.from)} le pagó '
          '${CurrencyFormatter.format(transfer.amount)} a '
          '${_nameOf(transfer.to)}. Queda registrado y los saldos se ponen '
          'al día.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Todavía no'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _cubit.settle(Settlement(
        id: '',
        householdId: widget.household.id,
        from: transfer.from,
        to: transfer.to,
        amount: transfer.amount,
        currency: CurrencyRegistry.base,
        date: DateTime.now(),
        createdBy: widget.userId,
      ));
    }
  }
}
