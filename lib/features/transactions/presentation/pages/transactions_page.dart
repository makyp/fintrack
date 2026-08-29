import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/theme_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/expandable_text.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../capture/domain/entities/transaction_draft.dart';
import '../../../capture/presentation/pages/capture_options_sheet.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/transactions_bloc.dart';
import '../bloc/transactions_event.dart';
import '../bloc/transactions_state.dart';
import '../widgets/transaction_filter_bar.dart';
import '../utils/transactions_export.dart';
import 'transaction_form_page.dart';
import 'recurring_transactions_page.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<TransactionsBloc>()),
        BlocProvider(create: (_) => getIt<AccountsCubit>()),
      ],
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
      context.read<AccountsCubit>().watchAccounts(userId);
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
                : const Text('Movimientos'),
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
                icon: const Icon(Icons.repeat),
                tooltip: 'Recurrentes',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RecurringTransactionsPage()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined),
                tooltip: 'Descargar histórico',
                onPressed: state.transactions.isEmpty
                    ? null
                    : () => _showExportSheet(context),
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
            onPressed: () => _startCapture(context),
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
    final accountsById = {
      for (final a in context.watch<AccountsCubit>().state.accounts ?? <Account>[])
        a.id: a,
    };

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      // +1 for the footer ("Ver más" / counter).
      itemCount: dateKeys.length + 1,
      itemBuilder: (_, i) {
        if (i == dateKeys.length) {
          return _buildFooter(context, state);
        }
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
                  account: accountsById[tx.accountId],
                  toAccount: tx.toAccountId != null ? accountsById[tx.toAccountId] : null,
                  onTap: () => _openForm(context, transaction: tx),
                )),
          ],
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, TransactionsState state) {
    final count = state.transactions.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding, AppDimensions.lg,
          AppDimensions.pagePadding, AppDimensions.md),
      child: Column(
        children: [
          if (state.hasMore && !state.isFiltered)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: state.loadingMore
                    ? null
                    : () => context.read<TransactionsBloc>().add(
                          const TransactionsLoadMore(),
                        ),
                icon: state.loadingMore
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more),
                label: Text(state.loadingMore ? 'Cargando…' : 'Ver más'),
              ),
            ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            state.isFiltered
                ? '$count movimientos (filtro aplicado)'
                : state.hasMore
                    ? 'Mostrando $count movimientos'
                    : '$count movimientos en total',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey400),
          ),
        ],
      ),
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

  void _openForm(
    BuildContext context, {
    Transaction? transaction,
    TransactionDraft? draft,
  }) {
    final userId = context.read<AuthBloc>().state.user?.uid ?? '';
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BlocProvider.value(
          value: context.read<TransactionsBloc>(),
          child: TransactionFormPage(
            userId: userId,
            transaction: transaction,
            draft: draft,
          ),
        ),
      ),
    );
  }

  /// Voice, receipt photo or by hand — then the form, prefilled.
  Future<void> _startCapture(BuildContext context) async {
    final draft = await showCaptureFlow(context);
    if (draft == null || !context.mounted) return;
    _openForm(context, draft: draft);
  }

  void _showExportSheet(BuildContext context) {
    final isFiltered = context.read<TransactionsBloc>().state.isFiltered;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppDimensions.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePadding),
              child: Row(
                children: [
                  Text('Descargar histórico',
                      style: AppTextStyles.headlineSmall),
                ],
              ),
            ),
            if (isFiltered)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pagePadding, 4, AppDimensions.pagePadding, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Se exporta todo lo que coincide con el filtro',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey500)),
                ),
              ),
            const SizedBox(height: AppDimensions.sm),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined,
                  color: AppColors.success),
              title: const Text('Excel / CSV'),
              subtitle: const Text('Abre en Excel o Google Sheets'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _export(context, asPdf: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined,
                  color: AppColors.danger),
              title: const Text('PDF'),
              subtitle: const Text('Documento para imprimir o compartir'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _export(context, asPdf: true);
              },
            ),
            const SizedBox(height: AppDimensions.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, {required bool asPdf}) async {
    final bloc = context.read<TransactionsBloc>();
    final accountsCubit = context.read<AccountsCubit>();
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(const SnackBar(
      content: Text('Preparando archivo…'),
      duration: Duration(seconds: 1),
    ));

    try {
      final txs = await bloc.fetchAllForExport();
      if (txs.isEmpty) {
        messenger.showSnackBar(const SnackBar(
          content: Text('No hay movimientos para exportar'),
        ));
        return;
      }
      final accountNames = {
        for (final a in accountsCubit.state.accounts ?? <Account>[])
          a.id: a.name,
      };
      if (asPdf) {
        await TransactionsExport.sharePdf(txs, accountNames: accountNames);
      } else {
        await TransactionsExport.shareCsv(txs, accountNames: accountNames);
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('No se pudo exportar: $e'),
        backgroundColor: AppColors.danger,
      ));
    }
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
  final Account? account;
  final Account? toAccount;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.transaction,
    required this.onTap,
    this.account,
    this.toAccount,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final isTransfer = transaction.type == TransactionType.transfer;
    // Follow the active theme palette (same colors as the dashboard).
    final palette = AppColorPalette.fromType(context.watch<ThemeCubit>().state);
    final amountColor = isExpense
        ? palette.expense
        : isTransfer
            ? palette.primary
            : palette.income;
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
                  ExpandableText(
                    text: transaction.description.isNotEmpty
                        ? transaction.description
                        : transaction.category.label,
                    style: AppTextStyles.bodyMedium,
                  ),
                  if (account != null) ...[
                    const SizedBox(height: 3),
                    _AccountChip(
                      account: account!,
                      toAccount: isTransfer ? toAccount : null,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    '${transaction.category.label} · ${DateFormatter.formatTime(transaction.date)}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign${CurrencyFormatter.format(transaction.amount, code: transaction.currency)}',
                  style: AppTextStyles.monoMedium.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // A deferred card purchase hits the debt in full, but the user
                // budgets by the monthly instalment — show both.
                if (transaction.isDeferred)
                  Text(
                    '${transaction.installments} cuotas de '
                    '${CurrencyFormatter.format(transaction.installmentAmount!)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey500,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  final Account account;
  final Account? toAccount;

  const _AccountChip({required this.account, this.toAccount});

  @override
  Widget build(BuildContext context) {
    final color = Color(account.colorValue);
    final label = toAccount != null
        ? '${account.icon} → ${toAccount!.icon}'
        : '${account.icon} ${account.name}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color.withOpacity(0.9),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
