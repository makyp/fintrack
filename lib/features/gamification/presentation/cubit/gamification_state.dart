part of 'gamification_cubit.dart';

enum GamificationStatus { initial, loaded }

class GamificationState extends Equatable {
  final GamificationStatus status;
  final UserStreak streak;
  final List<AppBadge> badges;
  final Set<DateTime> activityDays;

  const GamificationState._({
    required this.status,
    required this.streak,
    required this.badges,
    required this.activityDays,
  });

  const GamificationState.initial()
      : this._(
          status: GamificationStatus.initial,
          streak: const UserStreak.empty(),
          badges: AppBadge.catalog,
          activityDays: const {},
        );

  const GamificationState.loaded({
    required UserStreak streak,
    required List<AppBadge> badges,
    required Set<DateTime> activityDays,
  }) : this._(
          status: GamificationStatus.loaded,
          streak: streak,
          badges: badges,
          activityDays: activityDays,
        );

  List<AppBadge> get earned => badges.where((b) => b.isEarned).toList();

  @override
  List<Object?> get props => [status, streak, badges, activityDays];
}
