import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/entities/transaction.dart';
import '../cubit/recurring_cubit.dart';
import 'recurring_transaction_form_page.dart';

class RecurringTransactionsPage extends StatelessWidget {
  const RecurringTransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthBloc>().state.user?.uid ?? '';
    return BlocProvider(
      create: (_) => getIt<RecurringCubit>()..watch(userId),
      child: _RecurringView(userId: userId),
    );
  }
}

class _RecurringView extends StatelessWidget {
  final String userId;
  const _RecurringView({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transacciones recurrentes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: BlocBuilder<RecurringCubit, RecurringState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == RecurringStatus.error) {
            return Center(
              child: Text(state.errorMessage ?? 'Error',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger)),
            );
          }
          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.repeat, size: 64, color: AppColors.grey300),
                  const SizedBox(height: AppDimensions.md),
                  Text('Sin recurrentes', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.grey500)),
                  const SizedBox(height: AppDimensions.sm),
                  Text('Agrega gastos o ingresos automáticos',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey400)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: state.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _RecurringTile(
              item: state.items[i],
              onTap: () => _openForm(context, item: state.items[i]),
              onDeactivate: () async {
                final ok = await context
                    .read<RecurringCubit>()
                    .deactivate(userId, state.items[i].id);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.read<RecurringCubit>().state.errorMessage ?? 'Error'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, {RecurringTransaction? item}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BlocProvider.value(
          value: context.read<RecurringCubit>(),
          child: RecurringTransactionFormPage(userId: userId, item: item),
        ),
      ),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  final RecurringTransaction item;
  final VoidCallback onTap;
  final VoidCallback onDeactivate;

  const _RecurringTile({
    required this.item,
    required this.onTap,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = item.type == TransactionType.expense;
    final color = isExpense ? AppColors.danger : AppColors.success;
    final sign = isExpense ? '-' : '+';
    final daysUntil = item.nextDueDate.difference(DateTime.now()).inDays;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text(item.category.icon, style: const TextStyle(fontSize: 20))),
      ),
      title: Text(
        item.description.isNotEmpty ? item.description : item.category.label,
        style: AppTextStyles.bodyMedium,
      ),
      subtitle: Row(
        children: [
          const Icon(Icons.repeat, size: 12, color: AppColors.grey500),
          const SizedBox(width: 4),
          Text(item.frequency.label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
          const SizedBox(width: 8),
          if (item.isDue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Vence hoy', style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger, fontSize: 10)),
            )
          else if (item.isDueSoon)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('En $daysUntil días', style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning, fontSize: 10)),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$sign${CurrencyFormatter.format(item.amount)}',
            style: AppTextStyles.monoMedium.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.pause_circle_outline, size: 18, color: AppColors.grey400),
            onPressed: onDeactivate,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Desactivar',
          ),
        ],
      ),
    );
  }
}
