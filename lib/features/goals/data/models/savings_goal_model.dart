import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/savings_goal.dart';

class SavingsGoalModel extends SavingsGoal {
  const SavingsGoalModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.icon,
    required super.targetAmount,
    required super.currentAmount,
    super.targetDate,
    super.linkedAccountId,
    super.isCompleted = false,
    required super.createdAt,
  });

  factory SavingsGoalModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SavingsGoalModel(
      id: id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      icon: data['icon'] as String? ?? '🎯',
      targetAmount: (data['targetAmount'] as num).toDouble(),
      currentAmount: (data['currentAmount'] as num? ?? 0).toDouble(),
      targetDate: data['targetDate'] != null
          ? (data['targetDate'] as Timestamp).toDate()
          : null,
      linkedAccountId: data['linkedAccountId'] as String?,
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'icon': icon,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        if (targetDate != null) 'targetDate': Timestamp.fromDate(targetDate!),
        if (linkedAccountId != null) 'linkedAccountId': linkedAccountId,
        'isCompleted': isCompleted,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory SavingsGoalModel.fromEntity(SavingsGoal goal) {
    return SavingsGoalModel(
      id: goal.id,
      userId: goal.userId,
      name: goal.name,
      icon: goal.icon,
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount,
      targetDate: goal.targetDate,
      linkedAccountId: goal.linkedAccountId,
      isCompleted: goal.isCompleted,
      createdAt: goal.createdAt,
    );
  }
}
