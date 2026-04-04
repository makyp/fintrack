import '../entities/user_streak.dart';
import '../entities/app_badge.dart';

abstract class GamificationRepository {
  Stream<UserStreak> watchStreak(String userId);
  Stream<List<AppBadge>> watchBadges(String userId);
  Stream<Set<DateTime>> watchActivityDays(String userId, int year, int month);
}
