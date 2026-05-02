import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:uuid/uuid.dart';

/// Runs on every app open (after auth) to replace the paid Cloud Functions:
///   1. processRecurringTransactions  — processes overdue recurring txs
///   2. creditHighYieldInterest       — credits daily interest on highYield accounts
class AppStartupService {
  final FirebaseFirestore _db;
  final Uuid _uuid;

  AppStartupService(this._db, this._uuid);

  Future<void> run(String userId) async {
    if (userId.isEmpty) return;
    await Future.wait([
      _processRecurring(userId),
      _creditInterest(userId),
    ]);
  }

  // ── 1. Recurring transactions ──────────────────────────────────────────────

  Future<void> _processRecurring(String userId) async {
    final today = _startOfDay(DateTime.now());
    final todayTs = Timestamp.fromDate(today);

    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('recurring_transactions')
        .where('isActive', isEqualTo: true)
        .where('nextDueDate', isLessThanOrEqualTo: todayTs)
        .get();

    if (snap.docs.isEmpty) return;

    final batch = _db.batch();

    for (final rtDoc in snap.docs) {
      final rt = rtDoc.data();

      // Avoid duplicate: check if a recurring tx was already created today
      final existing = await _db
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('isRecurring', isEqualTo: true)
          .where('accountId', isEqualTo: rt['accountId'])
          .where('description', isEqualTo: rt['description'])
          .where('date', isEqualTo: todayTs)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) continue;

      // Create transaction
      final txId = _uuid.v4();
      final txRef = _db
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(txId);

      final tx = {
        'userId': userId,
        'amount': rt['amount'],
        'type': rt['type'],
        'category': rt['category'],
        'accountId': rt['accountId'],
        'description': rt['description'],
        'date': todayTs,
        'isRecurring': true,
        'tags': <String>[],
        'createdAt': Timestamp.now(),
        if (rt['toAccountId'] != null) 'toAccountId': rt['toAccountId'],
      };
      batch.set(txRef, tx);

      // Update account balance
      final accountRef = _db
          .collection('users')
          .doc(userId)
          .collection('accounts')
          .doc(rt['accountId'] as String);

      final type = rt['type'] as String;
      final amount = (rt['amount'] as num).toDouble();
      final delta = type == 'income' ? amount : -amount;
      batch.update(accountRef, {
        'balance': FieldValue.increment(delta),
      });

      // If transfer, credit destination account
      if (type == 'transfer' && rt['toAccountId'] != null) {
        final toRef = _db
            .collection('users')
            .doc(userId)
            .collection('accounts')
            .doc(rt['toAccountId'] as String);
        batch.update(toRef, {'balance': FieldValue.increment(amount)});
      }

      // Advance nextDueDate
      final nextDue = _nextDueDate(
        (rt['nextDueDate'] as Timestamp).toDate(),
        rt['frequency'] as String,
      );
      final endDate = rt['endDate'] as Timestamp?;
      final shouldDeactivate =
          endDate != null && nextDue.isAfter(endDate.toDate());

      batch.update(rtDoc.reference, {
        'nextDueDate': Timestamp.fromDate(nextDue),
        'isActive': !shouldDeactivate,
      });
    }

    await batch.commit();
  }

  DateTime _nextDueDate(DateTime from, String frequency) {
    switch (frequency) {
      case 'daily':
        return from.add(const Duration(days: 1));
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'biweekly':
        return from.add(const Duration(days: 14));
      case 'monthly':
        final m = from.month + 1;
        final y = from.year + (m > 12 ? 1 : 0);
        return DateTime(y, m > 12 ? m - 12 : m, from.day);
      case 'yearly':
        return DateTime(from.year + 1, from.month, from.day);
      default:
        return from.add(const Duration(days: 30));
    }
  }

  // ── 2. High-yield daily interest ───────────────────────────────────────────

  Future<void> _creditInterest(String userId) async {
    final today = _startOfDay(DateTime.now());
    final todayTs = Timestamp.fromDate(today);

    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .where('type', isEqualTo: 'highYield')
        .where('isArchived', isEqualTo: false)
        .get();

    if (snap.docs.isEmpty) return;

    final batch = _db.batch();

    for (final accDoc in snap.docs) {
      final acc = accDoc.data();

      // Skip if already credited today
      final lastInterest = acc['lastInterestDate'] as Timestamp?;
      if (lastInterest != null &&
          _startOfDay(lastInterest.toDate()) == today) continue;

      final annualRate = (acc['interestRate'] as num?)?.toDouble() ?? 0;
      if (annualRate <= 0) continue;

      final balance = (acc['balance'] as num?)?.toDouble() ?? 0;
      if (balance <= 0) continue;

      final dailyInterest = (balance * (annualRate / 365)).roundToDouble();
      if (dailyInterest < 1) continue;

      // Create income transaction
      final txId = _uuid.v4();
      final txRef = _db
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(txId);

      batch.set(txRef, {
        'userId': userId,
        'amount': dailyInterest,
        'type': 'income',
        'category': 'investment',
        'accountId': accDoc.id,
        'description': 'Interés diario 🏆 ${acc['name']}',
        'date': todayTs,
        'isRecurring': false,
        'tags': ['interes', 'alto-rendimiento'],
        'createdAt': Timestamp.now(),
      });

      // Update balance + mark today as credited
      batch.update(accDoc.reference, {
        'balance': FieldValue.increment(dailyInterest),
        'lastInterestDate': todayTs,
      });
    }

    await batch.commit();
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
}
