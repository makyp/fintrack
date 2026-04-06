import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/thousands_separator_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/datasources/debt_datasource.dart';
import '../../domain/entities/debt.dart';
import '../cubit/debts_cubit.dart';
import 'debt_form_page.dart';

class DebtsPage extends StatelessWidget {
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthBloc>().state.user?.uid ?? '';
    return BlocProvider(
      create: (_) => DebtsCubit(getIt<DebtDataSource>())..watch(userId),
      child: _DebtsView(userId: userId),
    );
  }
}

class _DebtsView extends StatefulWidget {
  final String userId;
  const _DebtsView({required this.userId});

  @override
  State<_DebtsView> createState() => _DebtsViewState();
}

class _DebtsViewState extends State<_DebtsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deudas y Deudores'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Me deben'),
            Tab(text: 'Les debo'),
          ],
        ),
      ),
      body: BlocConsumer<DebtsCubit, DebtsState>(
        listener: (context, state) {
          if (state.status == DebtsStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Error'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final theyOweMe = state.debts
              .where((d) => d.direction == DebtDirection.theyOweMe)
              .toList();
          final iOweThem = state.debts
              .where((d) => d.direction == DebtDirection.iOweThem)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _DebtList(
                debts: theyOweMe,
                userId: widget.userId,
                emptyLabel: 'Nadie te debe nada',
                emptyIcon: '🎉',
              ),
              _DebtList(
                debts: iOweThem,
                userId: widget.userId,
                emptyLabel: 'No debes nada',
                emptyIcon: '😌',
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, initialDirection:
            _tabController.index == 1 ? DebtDirection.iOweThem : DebtDirection.theyOweMe),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva deuda'),
      ),
    );
  }

  void _openForm(BuildContext context, {Debt? debt, DebtDirection? initialDirection}) {
    final cubit = context.read<DebtsCubit>();
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: DebtFormPage(
          userId: widget.userId,
          debt: debt,
          initialDirection: initialDirection,
        ),
      ),
    ));
  }
}

// ── Debt list ─────────────────────────────────────────────────────────────────

class _DebtList extends StatelessWidget {
  final List<Debt> debts;
  final String userId;
  final String emptyLabel;
  final String emptyIcon;

  const _DebtList({
    required this.debts,
    required this.userId,
    required this.emptyLabel,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emptyIcon, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: AppDimensions.md),
            Text(emptyLabel,
                style: AppTextStyles.headlineSmall
                    .copyWith(color: AppColors.grey500)),
          ],
        ),
      );
    }

    final active = debts.where((d) => !d.isClosed).toList();
    final closed = debts.where((d) => d.isClosed).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding, AppDimensions.md,
          AppDimensions.pagePadding, 100),
      children: [
        // Summary row
        if (active.isNotEmpty) ...[
          _SummaryBar(debts: active),
          const SizedBox(height: AppDimensions.md),
        ],
        ...active.map((d) => _DebtCard(debt: d, userId: userId)),
        if (closed.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.md),
          Text('Cerradas',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.grey500)),
          const SizedBox(height: AppDimensions.sm),
          ...closed.map((d) => _DebtCard(debt: d, userId: userId)),
        ],
      ],
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final List<Debt> debts;
  const _SummaryBar({required this.debts});

  @override
  Widget build(BuildContext context) {
    final total = debts.fold(0.0, (s, d) => s + d.pendingAmount);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text('Total pendiente: ',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600)),
          Text(CurrencyFormatter.format(total),
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── Debt card ─────────────────────────────────────────────────────────────────

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final String userId;

  const _DebtCard({required this.debt, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isOverdue = debt.isOverdue;
    final accentColor = debt.isClosed
        ? AppColors.grey400
        : (isOverdue ? AppColors.danger : AppColors.primary);
    final progress =
        debt.currentTotal > 0 ? debt.totalPaid / debt.currentTotal : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showOptions(context),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: accentColor.withOpacity(0.12),
                    child: Text(
                      debt.personName.isNotEmpty
                          ? debt.personName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          color: accentColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(debt.personName,
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600)),
                        if (debt.description != null)
                          Text(debt.description!,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.grey500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(debt.pendingAmount),
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: accentColor, fontWeight: FontWeight.bold),
                      ),
                      if (debt.hasInterest)
                        Text(
                          '${debt.monthlyInterestRate.toStringAsFixed(1)}%/mes',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.warning, fontSize: 10),
                        ),
                    ],
                  ),
                ],
              ),
              if (!debt.isClosed) ...[
                const SizedBox(height: AppDimensions.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.grey100,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pagado: ${CurrencyFormatter.format(debt.totalPaid)}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey500, fontSize: 10),
                    ),
                    if (debt.dueDate != null)
                      Text(
                        _dueDateLabel(debt),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isOverdue ? AppColors.danger : AppColors.grey400,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
              if (debt.isClosed)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text('Cancelada',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.success, fontSize: 11)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _dueDateLabel(Debt d) {
    final days = d.daysUntilDue;
    if (days == null) return '';
    if (days < 0) return 'Vencida hace ${(-days)} días';
    if (days == 0) return 'Vence hoy';
    if (days == 1) return 'Vence mañana';
    return 'Vence en $days días';
  }

  void _showOptions(BuildContext context) {
    final cubit = context.read<DebtsCubit>();
    final nav = Navigator.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppDimensions.sm),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: AppDimensions.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.pagePadding),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      child: Text(
                        debt.personName.isNotEmpty
                            ? debt.personName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Text(debt.personName, style: AppTextStyles.headlineSmall),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              if (!debt.isClosed) ...[
                ListTile(
                  leading: const Icon(Icons.payments_outlined,
                      color: AppColors.success),
                  title: const Text('Registrar abono'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPaymentDialog(context, cubit);
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.edit_outlined, color: AppColors.primary),
                  title: const Text('Editar'),
                  onTap: () {
                    Navigator.pop(ctx);
                    nav.push(MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => BlocProvider.value(
                        value: cubit,
                        child: DebtFormPage(userId: userId, debt: debt),
                      ),
                    ));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle_outline,
                      color: AppColors.success),
                  title: const Text('Marcar como cancelada'),
                  onTap: () {
                    Navigator.pop(ctx);
                    cubit.markClosed(userId, debt.id);
                  },
                ),
              ],
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text('Eliminar'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, cubit);
                },
              ),
              const SizedBox(height: AppDimensions.sm),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context, DebtsCubit cubit) {
    final ctrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Abono a ${debt.personName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pendiente: ${CurrencyFormatter.format(debt.pendingAmount)}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
            ),
            const SizedBox(height: AppDimensions.sm),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorFormatter()],
              decoration: const InputDecoration(
                labelText: 'Monto del abono',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final amount = ThousandsSeparatorFormatter.parse(ctrl.text);
              if (amount <= 0) return;
              Navigator.pop(ctx);
              await cubit.addPayment(userId, debt.id, amount,
                  note: noteCtrl.text.trim().isEmpty
                      ? null
                      : noteCtrl.text.trim());
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DebtsCubit cubit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar deuda'),
        content:
            Text('¿Eliminar la deuda con "${debt.personName}"? No se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await cubit.delete(userId, debt.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
