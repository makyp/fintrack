import '../../domain/entities/user_streak.dart';
import '../../domain/entities/app_badge.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../datasources/gamification_datasource.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  final GamificationDataSource _ds;
  GamificationRepositoryImpl(this._ds);

  @override
  Stream<UserStreak> watchStreak(String userId) => _ds.watchStreak(userId);

  @override
  Stream<List<AppBadge>> watchBadges(String userId) =>
      _ds.watchBadges(userId);

  @override
  Stream<Set<DateTime>> watchActivityDays(
          String userId, int year, int month) =>
      _ds.watchActivityDays(userId, year, month);
}
