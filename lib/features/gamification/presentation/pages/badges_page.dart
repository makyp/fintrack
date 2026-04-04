import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/app_badge.dart';
import '../cubit/gamification_cubit.dart';

class BadgesPage extends StatelessWidget {
  const BadgesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthBloc>().state.user?.uid ?? '';
    return BlocProvider(
      create: (_) {
        final cubit = GamificationCubit(getIt());
        cubit.watch(userId);
        return cubit;
      },
      child: const _BadgesView(),
    );
  }
}

class _BadgesView extends StatelessWidget {
  const _BadgesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logros')),
      body: BlocBuilder<GamificationCubit, GamificationState>(
        builder: (context, state) {
          final badges = state.badges;
          final earned = badges.where((b) => b.isEarned).toList();
          final locked = badges.where((b) => !b.isEarned).toList();

          return CustomScrollView(
            slivers: [
              // Summary banner
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(AppDimensions.pagePadding),
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF2A5298)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatPill(
                        label: 'Ganados',
                        value: '${earned.length}',
                        icon: '🏅',
                      ),
                      Container(
                          height: 40, width: 1,
                          color: AppColors.white.withOpacity(0.3)),
                      _StatPill(
                        label: 'Total',
                        value: '${badges.length}',
                        icon: '🎖️',
                      ),
                      Container(
                          height: 40, width: 1,
                          color: AppColors.white.withOpacity(0.3)),
                      _StatPill(
                        label: 'Progreso',
                        value: badges.isEmpty
                            ? '0%'
                            : '${(earned.length / badges.length * 100).round()}%',
                        icon: '📈',
                      ),
                    ],
                  ),
                ),
              ),

              if (earned.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimensions.pagePadding, 0,
                      AppDimensions.pagePadding, AppDimensions.sm),
                  sliver: SliverToBoxAdapter(
                    child: Text('Ganados',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.grey500)),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.pagePadding),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppDimensions.sm,
                      crossAxisSpacing: AppDimensions.sm,
                      childAspectRatio: 1.4,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _BadgeTile(badge: earned[i]),
                      childCount: earned.length,
                    ),
                  ),
                ),
              ],

              if (locked.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimensions.pagePadding, AppDimensions.lg,
                      AppDimensions.pagePadding, AppDimensions.sm),
                  sliver: SliverToBoxAdapter(
                    child: Text('Por ganar',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.grey500)),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.pagePadding),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppDimensions.sm,
                      crossAxisSpacing: AppDimensions.sm,
                      childAspectRatio: 1.4,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _BadgeTile(badge: locked[i], locked: true),
                      childCount: locked.length,
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(
                  child: SizedBox(height: AppDimensions.xl)),
            ],
          );
        },
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  const _StatPill(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.headlineSmall
                .copyWith(color: AppColors.white)),
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.white.withOpacity(0.7))),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final AppBadge badge;
  final bool locked;

  const _BadgeTile({required this.badge, this.locked = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColorFiltered(
              colorFilter: locked
                  ? const ColorFilter.matrix([
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0,      0,      0,      1, 0,
                    ])
                  : const ColorFilter.mode(
                      Colors.transparent, BlendMode.dst),
              child: Text(
                badge.icon,
                style: TextStyle(fontSize: locked ? 24 : 28),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.name,
              style: AppTextStyles.labelMedium.copyWith(
                color: locked ? AppColors.grey400 : AppColors.grey800,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              locked ? badge.description : _earnedLabel(badge.earnedAt),
              style: AppTextStyles.bodySmall.copyWith(
                  color: locked ? AppColors.grey400 : AppColors.grey500,
                  fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _earnedLabel(DateTime? dt) {
    if (dt == null) return '';
    return 'Ganado ${dt.day}/${dt.month}/${dt.year}';
  }
}
