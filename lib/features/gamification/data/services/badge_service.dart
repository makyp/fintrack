import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Evaluates and updates streak + badges after a transaction is added.
/// Called from the transaction datasource and goal/recurring handlers.
class BadgeService {
  final FirebaseFirestore _firestore;

  const BadgeService(this._firestore);

  DocumentReference<Map<String, dynamic>> _userRef(String userId) =>
      _firestore.collection('users').doc(userId);

  CollectionReference<Map<String, dynamic>> _txCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('transactions');

  CollectionReference<Map<String, dynamic>> _badgesCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('badges');

  CollectionReference<Map<String, dynamic>> _goalsCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('goals');

  Future<void> onTransactionAdded(String userId) async {
    try {
      await _updateStreak(userId);
      await _checkBadges(userId);
    } catch (_) {}
  }

  Future<void> onGoalCreated(String userId) async {
    try {
      await _checkBadges(userId);
    } catch (_) {}
  }

  Future<void> onGoalCompleted(String userId) async {
    try {
      await _checkBadges(userId);
    } catch (_) {}
  }

  Future<void> onRecurringCreated(String userId) async {
    try {
      await _checkBadges(userId);
    } catch (_) {}
  }

  // ── Streak ────────────────────────────────────────────────────────────────

  /// Recalculates streak from the full transaction history (reliable).
  Future<void> _updateStreak(String userId) async {
    final txSnap = await _txCol(userId).get();

    // Collect unique calendar days that have at least one transaction
    final days = <DateTime>{};
    for (final doc in txSnap.docs) {
      final ts = doc.data()['date'];
      if (ts is Timestamp) {
        final d = ts.toDate();
        days.add(DateTime(d.year, d.month, d.day));
      }
    }
    if (days.isEmpty) return;

    final sorted = days.toList()..sort();
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    // Current streak: consecutive days ending today or yesterday
    int current = 0;
    for (final anchor in [todayNorm, todayNorm.subtract(const Duration(days: 1))]) {
      DateTime check = anchor;
      int run = 0;
      for (int i = sorted.length - 1; i >= 0; i--) {
        if (sorted[i] == check) {
          run++;
          check = check.subtract(const Duration(days: 1));
        } else if (sorted[i].isBefore(check)) {
          break;
        }
      }
      if (run > 0) { current = run; break; }
    }

    // Longest streak ever
    int longest = 1;
    int run = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        run++;
      } else {
        longest = math.max(longest, run);
        run = 1;
      }
    }
    longest = math.max(longest, run);
    longest = math.max(longest, current);

    await _userRef(userId).set({
      'currentStreak': current,
      'longestStreak': longest,
      'lastActivityDate': Timestamp.fromDate(sorted.last),
    }, SetOptions(merge: true));
  }

  // ── Badge evaluation ──────────────────────────────────────────────────────

  Future<void> _checkBadges(String userId) async {
    final userSnap = await _userRef(userId).get();
    final userData = userSnap.data() ?? {};
    final currentStreak = (userData['currentStreak'] as int?) ?? 0;
    final longestStreak = (userData['longestStreak'] as int?) ?? 0;

    // Transaction data
    final txSnap = await _txCol(userId).get();
    final txCount = txSnap.docs.length;
    final txDocs = txSnap.docs.map((d) => d.data()).toList();

    // Use the PREVIOUS complete month for savings-rate badges.
    // Current month data is partial and would give misleading results
    // (e.g. 5 days of income looks like 100% savings rate).
    final now = DateTime.now();
    final prevMonth = DateTime(now.year, now.month - 1);

    final thisMonthIncome = txDocs.where((d) {
      final ts = d['date'];
      if (ts is! Timestamp) return false;
      final dt = ts.toDate();
      return dt.year == prevMonth.year && dt.month == prevMonth.month && d['type'] == 'income';
    }).fold(0.0, (s, d) => s + ((d['amount'] as num?)?.toDouble() ?? 0));

    final thisMonthExpenses = txDocs.where((d) {
      final ts = d['date'];
      if (ts is! Timestamp) return false;
      final dt = ts.toDate();
      return dt.year == prevMonth.year && dt.month == prevMonth.month && d['type'] == 'expense';
    }).fold(0.0, (s, d) => s + ((d['amount'] as num?)?.toDouble() ?? 0));

    // Total income ever
    final totalIncome = txDocs
        .where((d) => d['type'] == 'income')
        .fold(0.0, (s, d) => s + ((d['amount'] as num?)?.toDouble() ?? 0));

    // Unique categories used
    final categories = txDocs.map((d) => d['category'] as String? ?? '').toSet();

    // Night owl / early bird
    bool hasNightTx = false;
    bool hasEarlyTx = false;
    for (final d in txDocs) {
      final ts = d['date'];
      if (ts is Timestamp) {
        final h = ts.toDate().hour;
        if (h >= 23 || h == 0) hasNightTx = true;
        if (h >= 4 && h < 7) hasEarlyTx = true;
      }
    }

    // Max single expense
    final maxExpense = txDocs
        .where((d) => d['type'] == 'expense')
        .fold(0.0, (s, d) => math.max(s, (d['amount'] as num?)?.toDouble() ?? 0));

    // Goals
    final goalsSnap = await _goalsCol(userId).get();
    final allGoals = goalsSnap.docs.map((d) => d.data()).toList();
    final totalGoals = allGoals.length;
    final completedGoals = allGoals.where((d) => d['isCompleted'] == true).length;

    // Recurring transactions (top-level collection or subcollection)
    final recurringSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('recurring_transactions')
        .get();
    final recurringCount = recurringSnap.docs.length;

    // Already earned badges
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

    // ── Transacciones ──────────────────────────────────────────────────────
    if (txCount >= 1)    award('first_tx');
    if (txCount >= 5)    award('tx_5');
    if (txCount >= 10)   award('tx_10');
    if (txCount >= 25)   award('tx_25');
    if (txCount >= 50)   award('tx_50');
    if (txCount >= 100)  award('tx_100');
    if (txCount >= 250)  award('tx_250');
    if (txCount >= 500)  award('tx_500');

    // ── Racha ──────────────────────────────────────────────────────────────
    if (currentStreak >= 2)   award('streak_2');
    if (currentStreak >= 3)   award('streak_3');
    if (currentStreak >= 5)   award('streak_5');
    if (currentStreak >= 7)   award('streak_7');
    if (currentStreak >= 14)  award('streak_14');
    if (currentStreak >= 30)  award('streak_30');
    if (currentStreak >= 60)  award('streak_60');
    if (longestStreak >= 90)  award('streak_90');

    // ── Ingresos ───────────────────────────────────────────────────────────
    final hasIncomeTx = txDocs.any((d) => d['type'] == 'income');
    if (hasIncomeTx) award('first_income');
    if (totalIncome >= 1000000)   award('income_1m_total');
    if (totalIncome >= 10000000)  award('income_10m_total');
    if (thisMonthIncome >= 1000000)  award('income_1m_month');
    if (thisMonthIncome >= 5000000)  award('income_5m_month');

    // ── Ahorro ─────────────────────────────────────────────────────────────
    if (thisMonthIncome > 0) {
      final savingsRate = (thisMonthIncome - thisMonthExpenses) / thisMonthIncome;
      if (savingsRate >= 0.10) award('saver_10');
      if (savingsRate >= 0.20) award('saver_20');
      if (savingsRate >= 0.30) award('saver_30');
      if (savingsRate >= 0.50) award('saver_50');
    }

    // ── Gastos ─────────────────────────────────────────────────────────────
    final hasExpenseTx = txDocs.any((d) => d['type'] == 'expense');
    if (hasExpenseTx) award('first_expense');
    if (maxExpense >= 500000)   award('big_spender_500k');
    if (maxExpense >= 2000000)  award('big_spender_2m');
    if (maxExpense >= 5000000)  award('big_spender_5m');

    // ── Diversificación ────────────────────────────────────────────────────
    if (categories.length >= 3)  award('diversified_3');
    if (categories.length >= 5)  award('diversified_5');
    if (categories.length >= 8)  award('diversified_8');

    // ── Noturno / madrugador ───────────────────────────────────────────────
    if (hasNightTx)  award('night_owl');
    if (hasEarlyTx)  award('early_bird');

    // ── Metas ──────────────────────────────────────────────────────────────
    if (totalGoals >= 1)    award('first_goal');
    if (totalGoals >= 3)    award('goals_3');
    if (totalGoals >= 5)    award('goals_5');
    if (totalGoals >= 10)   award('goals_10');
    if (completedGoals >= 1)  award('goal_completed');
    if (completedGoals >= 3)  award('goals_3_completed');
    if (completedGoals >= 5)  award('goals_5_completed');

    // ── Big goal ───────────────────────────────────────────────────────────
    final hasBigGoal = allGoals.any(
        (d) => ((d['targetAmount'] as num?)?.toDouble() ?? 0) >= 5000000);
    if (hasBigGoal) award('big_goal');

    // ── Recurrentes ────────────────────────────────────────────────────────
    if (recurringCount >= 1) award('first_recurring');
    if (recurringCount >= 3) award('recurring_3');
    if (recurringCount >= 5) award('recurring_5');

    if (anyNew) await batch.commit();
  }
}
