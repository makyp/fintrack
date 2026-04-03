import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/widgets/account_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../transactions/presentation/bloc/transactions_bloc.dart';
import '../../../transactions/presentation/bloc/transactions_event.dart';
import '../../../transactions/presentation/bloc/transactions_state.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/presentation/pages/transaction_form_page.dart';
import '../../../../core/utils/currency_formatter.dart' as cf;
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<DashboardCubit>()),
        BlocProvider(create: (_) => getIt<AccountsCubit>()),
        BlocProvider(create: (_) => getIt<TransactionsBloc>()),
      ],
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState.user != null) {
        final uid = authState.user!.uid;
        context.read<DashboardCubit>().load(uid);
        context.read<AccountsCubit>().watchAccounts(uid);
        context.read<TransactionsBloc>().add(TransactionsWatchStarted(uid));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, state),
              if (state.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _buildBalanceCard(context, state),
                _buildAccountsSection(context, state),
                _buildQuickActions(context),
                _buildRecentTransactions(context),
              ],
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/transactions/new'),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            icon: const Icon(Icons.add),
            label: const Text('Nuevo'),
          ),
        );
      },
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, DashboardState state) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final name = authState.user?.displayName.split(' ').first ?? 'Usuario';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
              ),
              Text(name, style: AppTextStyles.headlineSmall),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(
                  (authState.user?.displayName.isNotEmpty == true)
                      ? authState.user!.displayName[0].toUpperCase()
                      : 'U',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, DashboardState state) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding,
          AppDimensions.sm,
          AppDimensions.pagePadding,
          AppDimensions.lg,
        ),
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFF2A5298)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patrimonio neto',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              CurrencyFormatter.format(state.totalBalance),
              style: AppTextStyles.displayMedium.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: AppDimensions.lg),
            Row(
              children: [
                _buildBalanceStat(
                  label: 'Activos',
                  amount: state.accounts
                      .where((a) => !a.type.isLiability)
                      .fold(0.0, (s, a) => s + a.balance),
                  icon: Icons.trending_up,
                  color: const Color(0xFF6EE7B7),
                ),
                const SizedBox(width: AppDimensions.lg),
                _buildBalanceStat(
                  label: 'Deudas',
                  amount: state.accounts
                      .where((a) => a.type.isLiability)
                      .fold(0.0, (s, a) => s + a.balance),
                  icon: Icons.trending_down,
                  color: const Color(0xFFFCA5A5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceStat({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.white.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
              Text(
                CurrencyFormatter.format(amount, compact: true),
                style: AppTextStyles.monoSmall.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsSection(BuildContext context, DashboardState state) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.uid ?? '';

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding),
            child: Row(
              children: [
                Text('Mis cuentas', style: AppTextStyles.headlineSmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.push('/accounts/new', extra: userId),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Agregar'),
                ),
              ],
            ),
          ),
          if (state.accounts.isEmpty)
            _buildEmptyAccounts(context, userId)
          else
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePadding,
                ),
                itemCount: state.accounts.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppDimensions.sm),
                itemBuilder: (_, i) => AccountCard(
                  account: state.accounts[i],
                  compact: true,
                  onTap: () => context.push(
                    '/accounts/${state.accounts[i].id}/edit',
                    extra: {'account': state.accounts[i], 'userId': userId},
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppDimensions.lg),
        ],
      ),
    );
  }

  Widget _buildEmptyAccounts(BuildContext context, String userId) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      child: GestureDetector(
        onTap: () => context.push('/accounts/new', extra: userId),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.lg),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_outlined,
                  color: AppColors.primary, size: 32),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Agrega tu primera cuenta',
                        style: AppTextStyles.labelLarge),
                    Text(
                      'Registra tus cuentas para ver tu patrimonio',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Acciones rápidas', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppDimensions.md),
            Row(
              children: [
                _buildQuickActionBtn(
                  context,
                  icon: Icons.remove_circle_outline,
                  label: 'Gasto',
                  color: AppColors.danger,
                  onTap: () => context.push('/transactions/new?type=expense'),
                ),
                const SizedBox(width: AppDimensions.sm),
                _buildQuickActionBtn(
                  context,
                  icon: Icons.add_circle_outline,
                  label: 'Ingreso',
                  color: AppColors.success,
                  onTap: () => context.push('/transactions/new?type=income'),
                ),
                const SizedBox(width: AppDimensions.sm),
                _buildQuickActionBtn(
                  context,
                  icon: Icons.swap_horiz,
                  label: 'Transferir',
                  color: AppColors.secondary,
                  onTap: () => context.push('/transactions/new?type=transfer'),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Últimas transacciones', style: AppTextStyles.headlineSmall),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/transactions'),
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            BlocBuilder<TransactionsBloc, TransactionsState>(
              builder: (context, txState) {
                if (txState.transactions.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.grey400),
                        const SizedBox(height: AppDimensions.sm),
                        Text('Sin transacciones aún',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500)),
                        Text('Registra tu primer gasto o ingreso',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey400)),
                      ],
                    ),
                  );
                }
                final userId = context.read<AuthBloc>().state.user?.uid ?? '';
                final recent = txState.transactions.take(5).toList();
                return Card(
                  child: Column(
                    children: recent.map((tx) {
                      final isExpense = tx.type == TransactionType.expense;
                      final color = isExpense ? AppColors.danger : AppColors.success;
                      final sign = isExpense ? '-' : '+';
                      return ListTile(
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text(tx.category.icon, style: const TextStyle(fontSize: 18))),
                        ),
                        title: Text(
                          tx.description.isNotEmpty ? tx.description : tx.category.label,
                          style: AppTextStyles.bodyMedium,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(tx.category.label,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
                        trailing: Text(
                          '$sign${cf.CurrencyFormatter.format(tx.amount)}',
                          style: AppTextStyles.monoSmall.copyWith(color: color, fontWeight: FontWeight.w600),
                        ),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => BlocProvider.value(
                              value: context.read<TransactionsBloc>(),
                              child: TransactionFormPage(userId: userId, transaction: tx),
                            ),
                          ));
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días,';
    if (hour < 18) return 'Buenas tardes,';
    return 'Buenas noches,';
  }
}
