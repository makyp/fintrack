import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/entities/household.dart';
import '../cubit/household_cubit.dart';
import 'household_setup_page.dart';

class HouseholdPage extends StatelessWidget {
  const HouseholdPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    return BlocProvider(
      create: (_) => getIt<HouseholdCubit>()..watch(user?.householdId),
      child: _HouseholdView(userId: user?.uid ?? ''),
    );
  }
}

class _HouseholdView extends StatelessWidget {
  final String userId;
  const _HouseholdView({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Hogar')),
      body: BlocConsumer<HouseholdCubit, HouseholdState>(
        listener: (context, state) {
          if (state.status == HouseholdStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Error'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          // Sync householdId into AuthBloc so transaction form and reports react immediately
          if (state.status == HouseholdStatus.loaded) {
            context.read<AuthBloc>().add(
                  AuthHouseholdIdUpdated(state.household?.id),
                );
          }
        },
        builder: (context, state) {
          if (state.isLoading || state.status == HouseholdStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!state.hasHousehold) {
            return _NoHouseholdView(userId: userId);
          }

          return _HouseholdContent(
            household: state.household!,
            userId: userId,
          );
        },
      ),
    );
  }
}

class _NoHouseholdView extends StatelessWidget {
  final String userId;
  const _NoHouseholdView({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_outlined, size: 72, color: AppColors.grey300),
            const SizedBox(height: AppDimensions.lg),
            Text('Sin hogar configurado', style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'Crea un hogar para compartir gastos con tu familia o pareja, o únete a uno existente.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.xl),
            ElevatedButton.icon(
              onPressed: () => _openSetup(context),
              icon: const Icon(Icons.add),
              label: const Text('Crear o unirse a un hogar'),
            ),
          ],
        ),
      ),
    );
  }

  void _openSetup(BuildContext context) {
    final cubit = context.read<HouseholdCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const HouseholdSetupPage(),
        ),
      ),
    );
  }
}

class _HouseholdContent extends StatelessWidget {
  final Household household;
  final String userId;
  const _HouseholdContent({required this.household, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isAdmin = household.members
        .any((m) => m.uid == userId && m.isAdmin);

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      children: [
        // ── Header card ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.home, color: AppColors.white, size: 28),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(household.name, style: AppTextStyles.headlineMedium),
                    Text(
                      '${household.members.length} ${household.members.length == 1 ? 'miembro' : 'miembros'}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.lg),

        // ── Invite code ───────────────────────────────────────────────
        if (isAdmin) ...[
          Text('Código de invitación', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.sm),
          InkWell(
            onTap: () {
              Clipboard.setData(
                  ClipboardData(text: household.inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Código copiado')),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md, vertical: AppDimensions.sm + 4),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    household.inviteCode,
                    style: AppTextStyles.monoSmall.copyWith(
                      fontSize: 22,
                      letterSpacing: 6,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Icon(Icons.copy_outlined, color: AppColors.grey500),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Comparte este código para que otros se unan.',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.grey400),
          ),
          const SizedBox(height: AppDimensions.lg),
        ],

        // ── Spending this month ───────────────────────────────────────
        Text('Gastos del mes por miembro', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppDimensions.sm),
        _MemberSpendingSection(members: household.members),
        const SizedBox(height: AppDimensions.lg),

        // ── Members ───────────────────────────────────────────────────
        Text('Miembros', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppDimensions.sm),
        ...household.members.map((m) => _MemberTile(member: m)),

        const SizedBox(height: AppDimensions.xl),

        // ── Leave button ──────────────────────────────────────────────
        OutlinedButton.icon(
          onPressed: () => _confirmLeave(context),
          icon: const Icon(Icons.exit_to_app, color: AppColors.danger),
          label: const Text('Salir del hogar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
          ),
        ),
      ],
    );
  }

  void _confirmLeave(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Salir del hogar'),
        content: const Text(
            '¿Seguro que quieres salir? Ya no podrás ver los gastos compartidos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<HouseholdCubit>()
                  .leave(userId, household.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}

// ── Member spending this month ─────────────────────────────────────────────────

class _MemberSpendingSection extends StatefulWidget {
  final List<HouseholdMember> members;
  const _MemberSpendingSection({required this.members});

  @override
  State<_MemberSpendingSection> createState() => _MemberSpendingSectionState();
}

class _MemberSpendingSectionState extends State<_MemberSpendingSection> {
  late Future<Map<String, double>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchSpending();
  }

  Future<Map<String, double>> _fetchSpending() async {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    final start = Timestamp.fromDate(DateTime(now.year, now.month, 1));
    final end   = Timestamp.fromDate(DateTime(now.year, now.month + 1, 1));

    final result = <String, double>{};
    await Future.wait(widget.members.map((m) async {
      final snap = await db
          .collection('users').doc(m.uid)
          .collection('transactions')
          .where('type', isEqualTo: 'expense')
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThan: end)
          .get();
      result[m.uid] = snap.docs.fold(
        0.0, (s, d) => s + ((d.data()['amount'] as num?)?.toDouble() ?? 0));
    }));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final spending = snap.data ?? {};
        final total = spending.values.fold(0.0, (a, b) => a + b);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey200),
          ),
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            children: [
              ...widget.members.map((m) {
                final amount = spending[m.uid] ?? 0;
                final pct = total > 0 ? amount / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primary.withOpacity(0.15),
                            child: Text(
                              m.displayName.isNotEmpty ? m.displayName[0].toUpperCase() : '?',
                              style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.primary, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(m.displayName, style: AppTextStyles.bodySmall),
                          ),
                          Text(
                            CurrencyFormatter.format(amount),
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.expense,
                            ),
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
                          value: pct.toDouble(),
                          minHeight: 5,
                          backgroundColor: AppColors.grey200,
                          valueColor: const AlwaysStoppedAnimation(AppColors.expense),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (total > 0) ...[
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total del hogar',
                        style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600)),
                    Text(CurrencyFormatter.format(total),
                        style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.expense)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Member tile ────────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  final HouseholdMember member;
  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.15),
        child: Text(
          member.displayName.isNotEmpty
              ? member.displayName[0].toUpperCase()
              : '?',
          style: AppTextStyles.labelMedium
              .copyWith(color: AppColors.primary),
        ),
      ),
      title: Text(member.displayName, style: AppTextStyles.bodyMedium),
      subtitle: Text(member.email,
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.grey500)),
      trailing: member.isAdmin
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Admin',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.primary, fontSize: 11)),
            )
          : null,
    );
  }
}
