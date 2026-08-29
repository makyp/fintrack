import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/utils/firestore_write.dart';
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

@LazySingleton(as: GoalRemoteDataSource)
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
    fireAndForget(
        _col(goal.userId).doc(id).set(model.toFirestore()), 'addGoal');
    AnalyticsService.logGoalCreated();
    return model;
  }

  @override
  Future<SavingsGoal> update(SavingsGoal goal) async {
    final model = SavingsGoalModel.fromEntity(goal);
    final data = model.toFirestore();
    // If targetDate was cleared, explicitly delete the field
    if (goal.targetDate == null) {
      data['targetDate'] = FieldValue.delete();
    }
    fireAndForget(_col(goal.userId).doc(goal.id).update(data), 'updateGoal');
    return model;
  }

  @override
  Future<void> delete(String userId, String goalId) async {
    fireAndForget(_col(userId).doc(goalId).delete(), 'deleteGoal');
  }

  @override
  Future<SavingsGoal> addContribution(
      String userId, String goalId, double amount) async {
    final docRef = _col(userId).doc(goalId);
    // Read-modify-write instead of runTransaction: a Firestore transaction
    // needs the server and fails offline; goals are single-user data, so the
    // cached read plus an incremental update is safe and works without a
    // connection.
    final snap = await docRef.get();
    final current = SavingsGoalModel.fromFirestore(snap.data()!, snap.id);
    final newAmount = current.currentAmount + amount;
    final isCompleted = newAmount >= current.targetAmount;
    final updated = SavingsGoalModel.fromEntity(
      current.copyWith(
        currentAmount: newAmount,
        isCompleted: isCompleted,
      ),
    );
    fireAndForget(
        docRef.update({
          'currentAmount': FieldValue.increment(amount),
          'isCompleted': isCompleted,
        }),
        'addContribution');

    return updated;
  }
}
