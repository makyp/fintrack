import 'package:cloud_firestore/cloud_firestore.dart';

/// Evaluates and updates streak + badges after a transaction is added.
/// Called from the transaction datasource after every successful add.
class BadgeService {
  final FirebaseFirestore _firestore;

  const BadgeService(this._firestore);

  DocumentReference<Map<String, dynamic>> _userRef(String userId) =>
      _firestore.collection('users').doc(userId);

  CollectionReference<Map<String, dynamic>> _txCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('transactions');

  CollectionReference<Map<String, dynamic>> _badgesCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('badges');

  Future<void> onTransactionAdded(String userId) async {
    try {
      await _updateStreak(userId);
      await _checkBadges(userId);
    } catch (_) {
      // Never throw — badge logic must not break transaction flow
    }
  }

  Future<void> _updateStreak(String userId) async {
    final userSnap = await _userRef(userId).get();
    final data = userSnap.data() ?? {};

    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    final lastTs = data['lastActivityDate'];
    final lastDate = lastTs != null
        ? (lastTs as Timestamp).toDate()
        : null;
    final lastNorm = lastDate != null
        ? DateTime(lastDate.year, lastDate.month, lastDate.day)
        : null;

    // Already counted today
    if (lastNorm != null && lastNorm == todayNorm) return;

    final current = (data['currentStreak'] as int?) ?? 0;
    final longest = (data['longestStreak'] as int?) ?? 0;

    final isConsecutive = lastNorm != null &&
        todayNorm.difference(lastNorm).inDays == 1;

    final newCurrent = isConsecutive ? current + 1 : 1;
    final newLongest = newCurrent > longest ? newCurrent : longest;

    await _userRef(userId).update({
      'currentStreak': newCurrent,
      'longestStreak': newLongest,
      'lastActivityDate': Timestamp.fromDate(todayNorm),
    });
  }

  Future<void> _checkBadges(String userId) async {
    final userSnap = await _userRef(userId).get();
    final data = userSnap.data() ?? {};

    final currentStreak = (data['currentStreak'] as int?) ?? 0;

    // Count total transactions
    final txSnap = await _txCol(userId).count().get();
    final txCount = txSnap.count ?? 0;

    // Fetch already earned badges
    final badgesSnap = await _badgesCol(userId).get();
    final earned = badgesSnap.docs.map((d) => d.id).toSet();

    final batch = _firestore.batch();
    bool anyNew = false;

    void award(String id) {
      if (!earned.contains(id)) {
        batch.set(_badgesCol(userId).doc(id), {
          'earnedAt': FieldValue.serverTimestamp(),
        });
        anyNew = true;
      }
    }

    // Transaction count badges
    if (txCount >= 1) award('first_tx');
    if (txCount >= 10) award('tx_10');
    if (txCount >= 50) award('tx_50');
    if (txCount >= 100) award('tx_100');

    // Streak badges
    if (currentStreak >= 3) award('streak_3');
    if (currentStreak >= 7) award('streak_7');
    if (currentStreak >= 30) award('streak_30');

    if (anyNew) await batch.commit();
  }

  /// Call after a goal is created
  Future<void> onGoalCreated(String userId) async {
    try {
      final badgesSnap = await _badgesCol(userId).get();
      final earned = badgesSnap.docs.map((d) => d.id).toSet();
      if (!earned.contains('first_goal')) {
        await _badgesCol(userId).doc('first_goal').set({
          'earnedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  /// Call after a goal is completed
  Future<void> onGoalCompleted(String userId) async {
    try {
      final badgesSnap = await _badgesCol(userId).get();
      final earned = badgesSnap.docs.map((d) => d.id).toSet();
      if (!earned.contains('goal_completed')) {
        await _badgesCol(userId).doc('goal_completed').set({
          'earnedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  /// Call after a recurring transaction is created
  Future<void> onRecurringCreated(String userId) async {
    try {
      final badgesSnap = await _badgesCol(userId).get();
      final earned = badgesSnap.docs.map((d) => d.id).toSet();
      if (!earned.contains('first_recurring')) {
        await _badgesCol(userId).doc('first_recurring').set({
          'earnedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }
}
