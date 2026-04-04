import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../domain/entities/user_streak.dart';
import '../cubit/gamification_cubit.dart';
import '../pages/badges_page.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GamificationCubit, GamificationState>(
      builder: (context, state) {
        final streak = state.streak;
        if (streak.currentStreak == 0) return const SizedBox.shrink();
        return _buildCard(context, streak, state.earned.length);
      },
    );
  }

  Widget _buildCard(BuildContext context, UserStreak streak, int earnedCount) {
    final isActive = streak.isActiveToday;
    final color = isActive ? AppColors.warning : AppColors.grey400;

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding, 0,
          AppDimensions.pagePadding, AppDimensions.md),
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md, vertical: AppDimensions.sm + 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(
            isActive ? '🔥' : '💤',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${streak.currentStreak} ${streak.currentStreak == 1 ? 'día' : 'días'} seguidos',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: color, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Récord: ${streak.longestStreak} días',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey500),
                ),
              ],
            ),
          ),
          // Badges earned chip
          if (earnedCount > 0)
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BadgesPage())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏅', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '$earnedCount',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
