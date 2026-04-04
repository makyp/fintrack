import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../domain/entities/savings_goal.dart';
import '../models/savings_goal_model.dart';

abstract class GoalRemoteDataSource {
  Stream<List<SavingsGoal>> watchGoals(String userId);
  Future<SavingsGoal> add(SavingsGoal goal);
  Future<SavingsGoal> update(SavingsGoal goal);
  Future<void> delete(String userId, String goalId);
  Future<SavingsGoal> addContribution(
      String userId, String goalId, double amount);
}

class GoalRemoteDataSourceImpl implements GoalRemoteDataSource {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  GoalRemoteDataSourceImpl(this._firestore, this._uuid);

  CollectionReference<Map<String, dynamic>> _col(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('goals');

  @override
  Stream<List<SavingsGoal>> watchGoals(String userId) {
    return _col(userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SavingsGoalModel.fromFirestore(d.data(), d.id))
            .toList());
  }

  @override
  Future<SavingsGoal> add(SavingsGoal goal) async {
    final id = _uuid.v4();
    final model = SavingsGoalModel.fromEntity(
      SavingsGoal(
        id: id,
        userId: goal.userId,
        name: goal.name,
        icon: goal.icon,
        targetAmount: goal.targetAmount,
        currentAmount: goal.currentAmount,
        targetDate: goal.targetDate,
        linkedAccountId: goal.linkedAccountId,
        isCompleted: false,
        createdAt: DateTime.now(),
      ),
    );
    await _col(goal.userId).doc(id).set(model.toFirestore());
    AnalyticsService.logGoalCreated();
    return model;
  }

  @override
  Future<SavingsGoal> update(SavingsGoal goal) async {
    final model = SavingsGoalModel.fromEntity(goal);
    await _col(goal.userId).doc(goal.id).update(model.toFirestore());
    return model;
  }

  @override
  Future<void> delete(String userId, String goalId) async {
    await _col(userId).doc(goalId).delete();
  }

  @override
  Future<SavingsGoal> addContribution(
      String userId, String goalId, double amount) async {
    final docRef = _col(userId).doc(goalId);
    late SavingsGoalModel updated;

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final current = SavingsGoalModel.fromFirestore(snap.data()!, snap.id);
      final newAmount = current.currentAmount + amount;
      final isCompleted = newAmount >= current.targetAmount;
      updated = SavingsGoalModel.fromEntity(
        current.copyWith(
          currentAmount: newAmount,
          isCompleted: isCompleted,
        ),
      );
      tx.update(docRef, {
        'currentAmount': newAmount,
        'isCompleted': isCompleted,
      });
    });

    return updated;
  }
}
