import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/transaction_model.dart';
import '../../domain/entities/transaction.dart';

abstract class TransactionRemoteDataSource {
  Stream<List<TransactionModel>> watchTransactions(String userId, {int limit = 50});
  Future<List<TransactionModel>> getTransactions(String userId, {
    DateTime? from, DateTime? to,
    TransactionType? type, TransactionCategory? category,
    String? accountId, String? searchQuery,
    int limit = 50, String? lastDocId,
  });
  Future<TransactionModel> addTransaction(TransactionModel tx);
  Future<TransactionModel> updateTransaction(TransactionModel tx);
  Future<void> deleteTransaction(String userId, String txId, {
    required String accountId, required double amount, required TransactionType type,
  });
}

@LazySingleton(as: TransactionRemoteDataSource)
class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  TransactionRemoteDataSourceImpl(this._firestore, this._uuid);

  CollectionReference<Map<String, dynamic>> _txRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('transactions');

  DocumentReference<Map<String, dynamic>> _accountRef(String userId, String accountId) =>
      _firestore.collection('users').doc(userId).collection('accounts').doc(accountId);

  @override
  Stream<List<TransactionModel>> watchTransactions(String userId, {int limit = 50}) {
    return _txRef(userId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TransactionModel.fromFirestore(d.data(), d.id))
            .toList());
  }

  @override
  Future<List<TransactionModel>> getTransactions(String userId, {
    DateTime? from, DateTime? to,
    TransactionType? type, TransactionCategory? category,
    String? accountId, String? searchQuery,
    int limit = 50, String? lastDocId,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _txRef(userId).orderBy('date', descending: true);
      if (from != null) query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
      if (to != null) query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
      if (type != null) query = query.where('type', isEqualTo: type.name);
      if (category != null) query = query.where('categoryId', isEqualTo: category.name);
      if (accountId != null) query = query.where('accountId', isEqualTo: accountId);
      if (lastDocId != null) {
        final lastDoc = await _txRef(userId).doc(lastDocId).get();
        query = query.startAfterDocument(lastDoc);
      }
      query = query.limit(limit);
      final snap = await query.get();
      var results = snap.docs.map((d) => TransactionModel.fromFirestore(d.data(), d.id)).toList();
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        results = results.where((t) => t.description.toLowerCase().contains(q)).toList();
      }
      return results;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<TransactionModel> addTransaction(TransactionModel tx) async {
    try {
      final id = tx.id.isEmpty ? _uuid.v4() : tx.id;
      final model = TransactionModel(
        id: id, userId: tx.userId, amount: tx.amount, type: tx.type,
        category: tx.category, accountId: tx.accountId, toAccountId: tx.toAccountId,
        description: tx.description, date: tx.date, isRecurring: tx.isRecurring,
        householdId: tx.householdId, receiptUrl: tx.receiptUrl, tags: tx.tags,
        createdAt: tx.createdAt,
      );

      final batch = _firestore.batch();
      batch.set(_txRef(tx.userId).doc(id), model.toFirestore());

      // Mirror to household collection if shared
      if (model.householdId != null && model.householdId!.isNotEmpty) {
        batch.set(
          _firestore
              .collection('households')
              .doc(model.householdId)
              .collection('transactions')
              .doc(id),
          model.toFirestore(),
        );
      }

      // Update account balance atomically
      // Credit cards store balance as outstanding debt (positive = owe money).
      // Expense on credit → increases debt → +amount
      // Income on credit  → decreases debt → -amount  (e.g. cashback or reversal)
      // Regular accounts are the opposite.
      final accSnap = await _accountRef(tx.userId, tx.accountId).get();
      final accType = accSnap.data()?['type'] as String? ?? 'cash';
      final isCredit = accType == 'credit';

      if (tx.type == TransactionType.expense) {
        batch.update(_accountRef(tx.userId, tx.accountId), {
          'balance': FieldValue.increment(isCredit ? tx.amount : -tx.amount),
        });
      } else if (tx.type == TransactionType.income) {
        batch.update(_accountRef(tx.userId, tx.accountId), {
          'balance': FieldValue.increment(isCredit ? -tx.amount : tx.amount),
        });
      } else if (tx.type == TransactionType.transfer && tx.toAccountId != null) {
        // Fetch destination account type to determine correct balance delta.
        // Liability accounts (credit cards): payment reduces debt → delta = -amount
        // Asset accounts: receiving money increases balance → delta = +amount
        final toAccSnap = await _accountRef(tx.userId, tx.toAccountId!).get();
        final toAccType = toAccSnap.data()?['type'] as String? ?? 'cash';
        final isLiability = toAccType == 'credit';
        final toDelta = isLiability ? -tx.amount : tx.amount;

        batch.update(_accountRef(tx.userId, tx.accountId), {
          'balance': FieldValue.increment(-tx.amount),
        });
        batch.update(_accountRef(tx.userId, tx.toAccountId!), {
          'balance': FieldValue.increment(toDelta),
        });
      }

      await batch.commit();
      AnalyticsService.logTransactionCreated(model.type.name, model.amount, 'COP');
      return model;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<TransactionModel> updateTransaction(TransactionModel tx) async {
    try {
      // Get old transaction to reverse balance change
      final oldDoc = await _txRef(tx.userId).doc(tx.id).get();
      if (!oldDoc.exists) throw const ServerException('Transacción no encontrada');
      final old = TransactionModel.fromFirestore(oldDoc.data()!, oldDoc.id);

      final batch = _firestore.batch();
      batch.update(_txRef(tx.userId).doc(tx.id), tx.toFirestore());

      // Mirror household doc: update if now shared, delete if no longer shared
      final householdRef = (hId) => _firestore
          .collection('households')
          .doc(hId)
          .collection('transactions')
          .doc(tx.id);
      if (tx.householdId != null && tx.householdId!.isNotEmpty) {
        batch.set(householdRef(tx.householdId), tx.toFirestore());
      } else if (old.householdId != null && old.householdId!.isNotEmpty) {
        batch.delete(householdRef(old.householdId));
      }

      // Reverse old balance effect (respecting credit card logic)
      final oldAccSnap = await _accountRef(tx.userId, old.accountId).get();
      final oldAccType = oldAccSnap.data()?['type'] as String? ?? 'cash';
      final oldIsCredit = oldAccType == 'credit';

      if (old.type == TransactionType.expense) {
        batch.update(_accountRef(tx.userId, old.accountId), {
          'balance': FieldValue.increment(oldIsCredit ? -old.amount : old.amount),
        });
      } else if (old.type == TransactionType.income) {
        batch.update(_accountRef(tx.userId, old.accountId), {
          'balance': FieldValue.increment(oldIsCredit ? old.amount : -old.amount),
        });
      } else if (old.type == TransactionType.transfer && old.toAccountId != null) {
        // Restore source account
        batch.update(_accountRef(tx.userId, old.accountId), {'balance': FieldValue.increment(old.amount)});
        // Restore destination account (reverse the payment that was applied)
        final oldToSnap = await _accountRef(tx.userId, old.toAccountId!).get();
        final oldToType = oldToSnap.data()?['type'] as String? ?? 'cash';
        final oldIsLiability = oldToType == 'credit';
        final oldToDelta = oldIsLiability ? old.amount : -old.amount;
        batch.update(_accountRef(tx.userId, old.toAccountId!), {'balance': FieldValue.increment(oldToDelta)});
      }

      // Apply new balance effect (respecting credit card logic)
      final newAccSnap = await _accountRef(tx.userId, tx.accountId).get();
      final newAccType = newAccSnap.data()?['type'] as String? ?? 'cash';
      final newIsCredit = newAccType == 'credit';

      if (tx.type == TransactionType.expense) {
        batch.update(_accountRef(tx.userId, tx.accountId), {
          'balance': FieldValue.increment(newIsCredit ? tx.amount : -tx.amount),
        });
      } else if (tx.type == TransactionType.income) {
        batch.update(_accountRef(tx.userId, tx.accountId), {
          'balance': FieldValue.increment(newIsCredit ? -tx.amount : tx.amount),
        });
      } else if (tx.type == TransactionType.transfer && tx.toAccountId != null) {
        final toSnap = await _accountRef(tx.userId, tx.toAccountId!).get();
        final toType = toSnap.data()?['type'] as String? ?? 'cash';
        final isLiability = toType == 'credit';
        final toDelta = isLiability ? -tx.amount : tx.amount;
        batch.update(_accountRef(tx.userId, tx.accountId), {'balance': FieldValue.increment(-tx.amount)});
        batch.update(_accountRef(tx.userId, tx.toAccountId!), {'balance': FieldValue.increment(toDelta)});
      }

      await batch.commit();
      return tx;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteTransaction(String userId, String txId, {
    required String accountId, required double amount, required TransactionType type,
  }) async {
    try {
      // Check if this tx belongs to a household to clean up mirror
      final txDoc = await _txRef(userId).doc(txId).get();
      final householdId = txDoc.data()?['householdId'] as String?;

      final batch = _firestore.batch();
      batch.delete(_txRef(userId).doc(txId));

      if (householdId != null && householdId.isNotEmpty) {
        batch.delete(_firestore
            .collection('households')
            .doc(householdId)
            .collection('transactions')
            .doc(txId));
      }

      final accSnap = await _accountRef(userId, accountId).get();
      final accType = accSnap.data()?['type'] as String? ?? 'cash';
      final isCredit = accType == 'credit';

      // Reverse the balance change applied when the transaction was created.
      // Credit card: expense increased debt (+amount), so reversal is -amount.
      // Regular account: expense decreased balance (-amount), so reversal is +amount.
      if (type == TransactionType.expense) {
        batch.update(_accountRef(userId, accountId),
            {'balance': FieldValue.increment(isCredit ? -amount : amount)});
      } else if (type == TransactionType.income) {
        batch.update(_accountRef(userId, accountId),
            {'balance': FieldValue.increment(isCredit ? amount : -amount)});
      }

      await batch.commit();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
