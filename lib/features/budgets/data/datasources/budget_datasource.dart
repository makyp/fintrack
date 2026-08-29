import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/firestore_write.dart';
import '../models/budget_model.dart';

abstract class BudgetDataSource {
  Stream<List<BudgetModel>> watchBudgets(String userId);
  Future<List<BudgetModel>> getBudgets(String userId);
  Future<void> saveBudget(String userId, BudgetModel budget);

  /// Removing a cap deletes it — a zero would still count as "configured".
  Future<void> deleteBudget(String userId, String categoryId);
}

@LazySingleton(as: BudgetDataSource)
class BudgetDataSourceImpl implements BudgetDataSource {
  final FirebaseFirestore _firestore;

  BudgetDataSourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> _ref(String userId) =>
      _firestore.collection('users').doc(userId).collection('budgets');

  @override
  Stream<List<BudgetModel>> watchBudgets(String userId) {
    return _ref(userId).snapshots().map((snap) => snap.docs
        .map((doc) => BudgetModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  @override
  Future<List<BudgetModel>> getBudgets(String userId) async {
    try {
      final snap = await _ref(userId).get();
      return snap.docs
          .map((doc) => BudgetModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> saveBudget(String userId, BudgetModel budget) async {
    try {
      fireAndForget(
          _ref(userId)
              .doc(budget.categoryId)
              .set(budget.toFirestore(), SetOptions(merge: true)),
          'saveBudget');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteBudget(String userId, String categoryId) async {
    try {
      fireAndForget(_ref(userId).doc(categoryId).delete(), 'deleteBudget');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
