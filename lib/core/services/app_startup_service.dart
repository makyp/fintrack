import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:uuid/uuid.dart';
import 'package:injectable/injectable.dart';
import '../utils/firestore_write.dart';

/// Runs on every app open (after auth) to replace the paid Cloud Functions:
///   1. processRecurringTransactions  — processes overdue recurring txs
///   2. creditHighYieldInterest       — credits daily interest on highYield accounts
///   3. migrateCategoryIds            — one-time backfill of the legacy
///                                      'category' key into 'categoryId'
@lazySingleton
class AppStartupService {
  final FirebaseFirestore _db;
  final Uuid _uuid;

  AppStartupService(this._db, this._uuid);

  Future<void> run(String userId) async {
    if (userId.isEmpty) return;
    // Run the migration before crediting/recurring so any historical records
    // are normalised first; the guard flag makes it a no-op after the first run.
    await _migrateCategoryIds(userId);
    await Future.wait([
      _processRecurring(userId),
      _creditInterest(userId),
    ]);
  }

  // ── 0. One-time category key migration ──────────────────────────────────────

  /// Early auto-generated transactions (interest + recurring) were written with
  /// the key `category`, but [TransactionModel] reads/writes `categoryId`. Those
  /// records therefore deserialised as "Otro". This copies the legacy value into
  /// `categoryId` for any transaction that is missing it, then sets a guard flag
  /// on the user doc so it never scans again.
  Future<void> _migrateCategoryIds(String userId) async {
    final userRef = _db.collection('users').doc(userId);
    final userSnap = await userRef.get();
    if (userSnap.data()?['categoryIdMigrated'] == true) return;

    final txSnap = await userRef.collection('transactions').get();

    WriteBatch batch = _db.batch();
    var ops = 0;
    for (final doc in txSnap.docs) {
      final data = doc.data();
      final legacy = data['category'];
      if (data['categoryId'] == null && legacy is String && legacy.isNotEmpty) {
        batch.update(doc.reference, {'categoryId': legacy});
        ops++;
        if (ops >= 400) {
          fireAndForget(batch.commit(), 'migrateCategoryIds');
          batch = _db.batch();
          ops = 0;
        }
      }
    }

    // Mark migrated (even when nothing needed fixing) so we don't rescan.
    batch.set(userRef, {'categoryIdMigrated': true}, SetOptions(merge: true));
    fireAndForget(batch.commit(), 'migrateCategoryIds');
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
        // 'categoryId' is the key TransactionModel reads; 'category' would be
        // dropped on read and shown as "Otro".
        'categoryId': rt['category'],
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

    fireAndForget(batch.commit(), 'processRecurring');
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

    // Upper bound on a single catch-up so a stale/missing lastInterestDate can
    // never build an unbounded batch.
    const maxBackfillDays = 60;

    final batch = _db.batch();
    var hasWrites = false;

    for (final accDoc in snap.docs) {
      final acc = accDoc.data();

      final annualRate = (acc['interestRate'] as num?)?.toDouble() ?? 0;
      if (annualRate <= 0) continue;

      var balance = (acc['balance'] as num?)?.toDouble() ?? 0;
      if (balance <= 0) continue;

      final lastInterest = acc['lastInterestDate'] as Timestamp?;
      final lastDay =
          lastInterest != null ? _startOfDay(lastInterest.toDate()) : null;

      // Already credited today (or somehow in the future) → nothing to do.
      if (lastDay != null && !lastDay.isBefore(today)) continue;

      // Every day still owed interest: strictly after the last credit, up to
      // and including today. This is what makes a day the app was NEVER opened
      // still get its record — it is filled in the next time the app opens,
      // instead of being lost.
      final daysToCredit = <DateTime>[];
      if (lastDay == null) {
        // First credit ever: only today (we don't fabricate unknown history).
        daysToCredit.add(today);
      } else {
        var d = _startOfDay(lastDay.add(const Duration(days: 1)));
        while (!d.isAfter(today) && daysToCredit.length < maxBackfillDays) {
          daysToCredit.add(d);
          d = _startOfDay(d.add(const Duration(days: 1)));
        }
      }

      double creditedTotal = 0;
      for (final day in daysToCredit) {
        final dailyInterest = (balance * (annualRate / 365)).roundToDouble();
        if (dailyInterest < 1) break; // negligible — stop crediting

        final txRef = _db
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .doc(_uuid.v4());

        batch.set(txRef, {
          'userId': userId,
          'amount': dailyInterest,
          'type': 'income',
          // Must be 'categoryId' (the key TransactionModel reads/writes), not
          // 'category' — otherwise it deserialises as "Otro" instead of
          // "Inversiones".
          'categoryId': 'investment',
          'accountId': accDoc.id,
          'description': 'Interés diario 🏆 ${acc['name']}',
          'date': Timestamp.fromDate(day),
          'isRecurring': false,
          'tags': ['interes', 'alto-rendimiento'],
          'createdAt': Timestamp.now(),
        });

        balance += dailyInterest; // compound for the following day
        creditedTotal += dailyInterest;
        hasWrites = true;
      }

      if (creditedTotal > 0) {
        batch.update(accDoc.reference, {
          'balance': FieldValue.increment(creditedTotal),
          'lastInterestDate': todayTs,
        });
      }
    }

    if (hasWrites) fireAndForget(batch.commit(), 'creditInterest');
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
}
