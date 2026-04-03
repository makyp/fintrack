import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
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

      // Update account balance atomically
      if (tx.type == TransactionType.expense) {
        batch.update(_accountRef(tx.userId, tx.accountId), {
          'balance': FieldValue.increment(-tx.amount),
        });
      } else if (tx.type == TransactionType.income) {
        batch.update(_accountRef(tx.userId, tx.accountId), {
          'balance': FieldValue.increment(tx.amount),
        });
      } else if (tx.type == TransactionType.transfer && tx.toAccountId != null) {
        batch.update(_accountRef(tx.userId, tx.accountId), {
          'balance': FieldValue.increment(-tx.amount),
        });
        batch.update(_accountRef(tx.userId, tx.toAccountId!), {
          'balance': FieldValue.increment(tx.amount),
        });
      }

      await batch.commit();
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

      // Reverse old balance effect
      if (old.type == TransactionType.expense) {
        batch.update(_accountRef(tx.userId, old.accountId), {'balance': FieldValue.increment(old.amount)});
      } else if (old.type == TransactionType.income) {
        batch.update(_accountRef(tx.userId, old.accountId), {'balance': FieldValue.increment(-old.amount)});
      }

      // Apply new balance effect
      if (tx.type == TransactionType.expense) {
        batch.update(_accountRef(tx.userId, tx.accountId), {'balance': FieldValue.increment(-tx.amount)});
      } else if (tx.type == TransactionType.income) {
        batch.update(_accountRef(tx.userId, tx.accountId), {'balance': FieldValue.increment(tx.amount)});
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
      final batch = _firestore.batch();
      batch.delete(_txRef(userId).doc(txId));

      if (type == TransactionType.expense) {
        batch.update(_accountRef(userId, accountId), {'balance': FieldValue.increment(amount)});
      } else if (type == TransactionType.income) {
        batch.update(_accountRef(userId, accountId), {'balance': FieldValue.increment(-amount)});
      }

      await batch.commit();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
