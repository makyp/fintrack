import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_streak.dart';
import '../../domain/entities/app_badge.dart';

abstract class GamificationDataSource {
  Stream<UserStreak> watchStreak(String userId);
  Stream<List<AppBadge>> watchBadges(String userId);
  Stream<Set<DateTime>> watchActivityDays(String userId, int year, int month);
}

class GamificationDataSourceImpl implements GamificationDataSource {
  final FirebaseFirestore _firestore;

  GamificationDataSourceImpl(this._firestore);

  DocumentReference<Map<String, dynamic>> _userRef(String userId) =>
      _firestore.collection('users').doc(userId);

  CollectionReference<Map<String, dynamic>> _txCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('transactions');

  CollectionReference<Map<String, dynamic>> _badgesCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('badges');

  @override
  Stream<UserStreak> watchStreak(String userId) {
    return _userRef(userId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return const UserStreak.empty();
      return UserStreak(
        currentStreak: (data['currentStreak'] as int?) ?? 0,
        longestStreak: (data['longestStreak'] as int?) ?? 0,
        lastActivityDate: data['lastActivityDate'] != null
            ? (data['lastActivityDate'] as Timestamp).toDate()
            : null,
      );
    });
  }

  @override
  Stream<List<AppBadge>> watchBadges(String userId) {
    return _badgesCol(userId).snapshots().map((snap) {
      final earnedMap = <String, DateTime>{};
      for (final doc in snap.docs) {
        final ts = doc.data()['earnedAt'];
        if (ts != null) earnedMap[doc.id] = (ts as Timestamp).toDate();
      }
      return AppBadge.catalog
          .map((b) => b.withEarnedAt(earnedMap[b.id]))
          .toList();
    });
  }

  @override
  Stream<Set<DateTime>> watchActivityDays(
      String userId, int year, int month) {
    final start = Timestamp.fromDate(DateTime(year, month, 1));
    final end = Timestamp.fromDate(DateTime(year, month + 1, 1));
    return _txCol(userId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final ts = d.data()['date'] as Timestamp;
              final dt = ts.toDate();
              return DateTime(dt.year, dt.month, dt.day);
            }).toSet());
  }
}
