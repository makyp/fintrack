import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/recurring_transaction_model.dart';
import '../../domain/entities/recurring_transaction.dart';

abstract class RecurringTransactionDataSource {
  Stream<List<RecurringTransactionModel>> watchAll(String userId);
  Future<RecurringTransactionModel> add(RecurringTransaction rt);
  Future<RecurringTransactionModel> update(RecurringTransaction rt);
  Future<void> deactivate(String userId, String id);
}

@LazySingleton(as: RecurringTransactionDataSource)
class RecurringTransactionDataSourceImpl
    implements RecurringTransactionDataSource {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  RecurringTransactionDataSourceImpl(this._firestore, this._uuid);

  CollectionReference<Map<String, dynamic>> _col(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('recurring_transactions');

  @override
  Stream<List<RecurringTransactionModel>> watchAll(String userId) {
    return _col(userId)
        .where('isActive', isEqualTo: true)
        .orderBy('nextDueDate')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RecurringTransactionModel.fromFirestore(d.data(), d.id))
            .toList());
  }

  @override
  Future<RecurringTransactionModel> add(RecurringTransaction rt) async {
    try {
      final id = rt.id.isEmpty ? _uuid.v4() : rt.id;
      final model = RecurringTransactionModel(
        id: id,
        userId: rt.userId,
        amount: rt.amount,
        type: rt.type,
        category: rt.category,
        accountId: rt.accountId,
        toAccountId: rt.toAccountId,
        description: rt.description,
        frequency: rt.frequency,
        startDate: rt.startDate,
        endDate: rt.endDate,
        nextDueDate: rt.nextDueDate,
        isActive: rt.isActive,
        createdAt: rt.createdAt,
      );
      await _col(rt.userId).doc(id).set(model.toFirestore());
      return model;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<RecurringTransactionModel> update(RecurringTransaction rt) async {
    try {
      final model = RecurringTransactionModel(
        id: rt.id,
        userId: rt.userId,
        amount: rt.amount,
        type: rt.type,
        category: rt.category,
        accountId: rt.accountId,
        toAccountId: rt.toAccountId,
        description: rt.description,
        frequency: rt.frequency,
        startDate: rt.startDate,
        endDate: rt.endDate,
        nextDueDate: rt.nextDueDate,
        isActive: rt.isActive,
        createdAt: rt.createdAt,
      );
      await _col(rt.userId).doc(rt.id).update(model.toFirestore());
      return model;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deactivate(String userId, String id) async {
    try {
      await _col(userId).doc(id).update({'isActive': false});
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
