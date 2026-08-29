import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/cubit/theme_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/expandable_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/widgets/account_card.dart';
import '../../../capture/domain/entities/transaction_draft.dart';
import '../../../capture/presentation/pages/capture_options_sheet.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../transactions/presentation/bloc/transactions_bloc.dart';
import '../../../transactions/presentation/bloc/transactions_event.dart';
import '../../../transactions/presentation/bloc/transactions_state.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/presentation/pages/transaction_form_page.dart';
import '../../../../core/utils/currency_formatter.dart' as cf;
import '../../../gamification/presentation/cubit/gamification_cubit.dart';
import '../../../gamification/presentation/widgets/streak_card.dart';
import '../../../gamification/presentation/widgets/activity_calendar.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../insights/presentation/widgets/tips_section.dart';
import '../../../../core/services/app_startup_service.dart';
import '../../../../core/di/injection.dart' show getIt;
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
        BlocProvider(create: (_) => getIt<GamificationCubit>()),
        BlocProvider(create: (_) => getIt<NotificationsCubit>()),
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
        context.read<GamificationCubit>().watch(uid);
        context.read<NotificationsCubit>().watch(uid);
        getIt<AppStartupService>().run(uid);
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
              if (state.status == DashboardStatus.loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.status == DashboardStatus.error)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.grey400),
                        const SizedBox(height: 12),
                        Text('No se pudo cargar la información',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            final uid = context.read<AuthBloc>().state.user?.uid ?? '';
                            if (uid.isNotEmpty) context.read<DashboardCubit>().load(uid);
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                _buildBalanceCard(context, state),
                const SliverToBoxAdapter(child: StreakCard()),
                _buildTipsSection(context),
                _buildAccountsSection(context, state),
                _buildQuickActions(context),
                _buildActivityCalendar(context),
                _buildRecentTransactions(context),
              ],
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _startCapture(context),
            backgroundColor: Theme.of(context).colorScheme.primary,
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
        BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, notifState) {
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push('/notifications'),
                ),
                if (notifState.unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        notifState.unreadCount > 9
                            ? '9+'
                            : '${notifState.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final user = authState.user;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => context.go('/profile'),
                child: AppAvatar(
                  photoUrl: user?.photoUrl,
                  displayName: user?.displayName,
                  radius: 18,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, DashboardState state) {
    final palette = AppColorPalette.fromType(context.read<ThemeCubit>().state);
    // Both totals go through the exchange rates, so an account in USD is
    // counted in the base currency instead of being added as if it were pesos.
    final assets = state.accounts.consolidatedAssets.amount;
    final debts = state.accounts.consolidatedLiabilities.amount;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding, AppDimensions.sm,
          AppDimensions.pagePadding, AppDimensions.lg,
        ),
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
        decoration: BoxDecoration(
          gradient: palette.gradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label row
            Row(
              children: [
                Text(
                  'Tu portafolio',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white70,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Mes a la fecha',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white, fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Total balance
            Text(
              'Balance total:',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(state.totalBalance),
              style: AppTextStyles.displayMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 34,
              ),
            ),
            if (state.missingRates.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 13, color: Colors.white70),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Sin ${state.missingRates.join(', ')} — falta su tasa '
                      'de cambio en Preferencias',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppDimensions.lg),
            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.13),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildBalanceStat(
                    label: 'Activos',
                    amount: assets,
                    icon: Icons.trending_up_rounded,
                    color: palette.income,
                  ),
                  Container(
                    width: 1, height: 36,
                    color: Colors.white24,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  _buildBalanceStat(
                    label: 'Deudas',
                    amount: debts,
                    icon: Icons.trending_down_rounded,
                    color: palette.expense,
                  ),
                ],
              ),
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

  Widget _buildTipsSection(BuildContext context) {
    final userId = context.read<AuthBloc>().state.user?.uid ?? '';
    if (userId.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(child: TipsSection(userId: userId));
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
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      child: GestureDetector(
        onTap: () => context.push('/accounts/new', extra: userId),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.lg),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primary.withOpacity(0.2),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.account_balance_outlined,
                  color: primary, size: 32),
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

  void _openTransactionForm(
    BuildContext context, {
    TransactionType? type,
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
            initialType: type,
            draft: draft,
          ),
        ),
      ),
    );
  }

  /// Asks how the user wants to register (voice, receipt photo or by hand)
  /// and opens the form prefilled with whatever was captured.
  Future<void> _startCapture(BuildContext context) async {
    final draft = await showCaptureFlow(context);
    if (draft == null || !context.mounted) return;
    _openTransactionForm(context, draft: draft);
  }

  Widget _buildQuickActions(BuildContext context) {
    final palette = AppColorPalette.fromType(context.read<ThemeCubit>().state);
    final primary = Theme.of(context).colorScheme.primary;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDimensions.pagePadding, 0,
            AppDimensions.pagePadding, AppDimensions.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickActionBtn(
              context,
              icon: Icons.arrow_downward_rounded,
              label: 'Gasto',
              bgColor: palette.expense.withOpacity(0.15),
              iconColor: palette.expense,
              onTap: () => _openTransactionForm(context, type: TransactionType.expense),
            ),
            _buildQuickActionBtn(
              context,
              icon: Icons.arrow_upward_rounded,
              label: 'Ingreso',
              bgColor: palette.income.withOpacity(0.15),
              iconColor: palette.income,
              onTap: () => _openTransactionForm(context, type: TransactionType.income),
            ),
            _buildQuickActionBtn(
              context,
              icon: Icons.swap_horiz_rounded,
              label: 'Transferir',
              bgColor: primary.withOpacity(0.1),
              iconColor: primary,
              onTap: () => _openTransactionForm(context, type: TransactionType.transfer),
            ),
            _buildQuickActionBtn(
              context,
              icon: Icons.bar_chart_rounded,
              label: 'Reportes',
              bgColor: AppColors.warning.withOpacity(0.1),
              iconColor: AppColors.warning,
              onTap: () => context.go('/reports'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCalendar(BuildContext context) {
    final userId = context.read<AuthBloc>().state.user?.uid ?? '';
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDimensions.pagePadding, 0,
            AppDimensions.pagePadding, AppDimensions.lg),
        child: ActivityCalendar(userId: userId),
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
                      final txPalette = AppColorPalette.fromType(context.read<ThemeCubit>().state);
                      final color = isExpense ? txPalette.expense : txPalette.income;
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
                        title: ExpandableText(
                          text: tx.description.isNotEmpty
                              ? tx.description
                              : tx.category.label,
                          style: AppTextStyles.bodyMedium,
                        ),
                        subtitle: Text(tx.category.label,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
                        trailing: Text(
                          '$sign${cf.CurrencyFormatter.format(tx.amount, code: tx.currency)}',
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
