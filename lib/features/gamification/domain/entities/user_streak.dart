import 'package:equatable/equatable.dart';

class UserStreak extends Equatable {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;

  const UserStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastActivityDate,
  });

  const UserStreak.empty()
      : currentStreak = 0,
        longestStreak = 0,
        lastActivityDate = null;

  bool get isActiveToday {
    if (lastActivityDate == null) return false;
    final now = DateTime.now();
    final last = lastActivityDate!;
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  @override
  List<Object?> get props => [currentStreak, longestStreak, lastActivityDate];
}
