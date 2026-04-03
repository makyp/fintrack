import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/transactions_bloc.dart';
import '../bloc/transactions_event.dart';
import '../bloc/transactions_state.dart';
import '../widgets/transaction_filter_bar.dart';
import 'transaction_form_page.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransactionsBloc>(),
      child: const _TransactionsView(),
    );
  }
}

class _TransactionsView extends StatefulWidget {
  const _TransactionsView();

  @override
  State<_TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<_TransactionsView> {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthBloc>().state.user?.uid ?? '';
      context.read<TransactionsBloc>().add(TransactionsWatchStarted(userId));
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionsBloc, TransactionsState>(
      listener: (context, state) {
        if (state.status == TransactionsStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Error'), backgroundColor: AppColors.danger),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: _showSearch
                ? TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Buscar transacción…',
                      border: InputBorder.none,
                    ),
                    onChanged: (q) {
                      final userId = context.read<AuthBloc>().state.user?.uid ?? '';
                      context.read<TransactionsBloc>().add(
                            TransactionsFiltered(userId: userId, searchQuery: q),
                          );
                    },
                  )
                : const Text('Transacciones'),
            actions: [
              IconButton(
                icon: Icon(_showSearch ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() => _showSearch = !_showSearch);
                  if (!_showSearch) {
                    _searchCtrl.clear();
                    final userId = context.read<AuthBloc>().state.user?.uid ?? '';
                    context.read<TransactionsBloc>().add(TransactionsWatchStarted(userId));
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterSheet(context),
              ),
            ],
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.transactions.isEmpty
                  ? _buildEmpty()
                  : _buildList(context, state),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            icon: const Icon(Icons.add),
            label: const Text('Nueva'),
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, TransactionsState state) {
    final grouped = state.groupedByDate;
    final dateKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: dateKeys.length,
      itemBuilder: (_, i) {
        final key = dateKeys[i];
        final txs = grouped[key]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.pagePadding, AppDimensions.md,
                  AppDimensions.pagePadding, AppDimensions.sm),
              child: Text(key,
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.grey500)),
            ),
            ...txs.map((tx) => _TransactionTile(
                  transaction: tx,
                  onTap: () => _openForm(context, transaction: tx),
                )),
          ],
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.grey300),
          const SizedBox(height: AppDimensions.md),
          Text('Sin transacciones', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.grey500)),
          const SizedBox(height: AppDimensions.sm),
          Text('Registra tu primer gasto o ingreso', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey400)),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, {Transaction? transaction}) {
    final userId = context.read<AuthBloc>().state.user?.uid ?? '';
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BlocProvider.value(
          value: context.read<TransactionsBloc>(),
          child: TransactionFormPage(userId: userId, transaction: transaction),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final userId = context.read<AuthBloc>().state.user?.uid ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<TransactionsBloc>(),
        child: TransactionFilterBar(userId: userId),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _TransactionTile({required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final isTransfer = transaction.type == TransactionType.transfer;
    final amountColor = isExpense
        ? AppColors.danger
        : isTransfer
            ? AppColors.secondary
            : AppColors.success;
    final sign = isExpense ? '-' : isTransfer ? '' : '+';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePadding, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(transaction.category.icon,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description.isNotEmpty
                        ? transaction.description
                        : transaction.category.label,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${transaction.category.label} · ${DateFormatter.formatTime(transaction.date)}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
                  ),
                ],
              ),
            ),
            Text(
              '$sign${CurrencyFormatter.format(transaction.amount)}',
              style: AppTextStyles.monoMedium.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
