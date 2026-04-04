import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_streak.dart';
import '../../domain/entities/app_badge.dart';
import '../../domain/repositories/gamification_repository.dart';

part 'gamification_state.dart';

class GamificationCubit extends Cubit<GamificationState> {
  final GamificationRepository _repo;

  StreamSubscription<UserStreak>? _streakSub;
  StreamSubscription<List<AppBadge>>? _badgesSub;
  StreamSubscription<Set<DateTime>>? _calendarSub;

  UserStreak _streak = const UserStreak.empty();
  List<AppBadge> _badges = List.from(AppBadge.catalog);
  Set<DateTime> _activityDays = {};

  GamificationCubit(this._repo) : super(const GamificationState.initial());

  void watch(String userId) {
    emit(const GamificationState.initial());

    _streakSub?.cancel();
    _streakSub = _repo.watchStreak(userId).listen(
      (streak) {
        _streak = streak;
        _emit();
      },
      onError: (_) {},
    );

    _badgesSub?.cancel();
    _badgesSub = _repo.watchBadges(userId).listen(
      (badges) {
        _badges = badges;
        _emit();
      },
      onError: (_) {},
    );

    final now = DateTime.now();
    _loadMonth(userId, now.year, now.month);
  }

  void changeMonth(String userId, int year, int month) {
    _loadMonth(userId, year, month);
  }

  void _loadMonth(String userId, int year, int month) {
    _calendarSub?.cancel();
    _calendarSub = _repo.watchActivityDays(userId, year, month).listen(
      (days) {
        _activityDays = days;
        _emit();
      },
      onError: (_) {},
    );
  }

  void _emit() {
    emit(GamificationState.loaded(
      streak: _streak,
      badges: _badges,
      activityDays: _activityDays,
    ));
  }

  @override
  Future<void> close() {
    _streakSub?.cancel();
    _badgesSub?.cancel();
    _calendarSub?.cancel();
    return super.close();
  }
}
