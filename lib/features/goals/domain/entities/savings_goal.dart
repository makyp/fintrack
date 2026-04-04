import 'package:equatable/equatable.dart';

class SavingsGoal extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String? linkedAccountId;
  final bool isCompleted;
  final DateTime createdAt;

  const SavingsGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    this.linkedAccountId,
    this.isCompleted = false,
    required this.createdAt,
  });

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get remaining =>
      (targetAmount - currentAmount).clamp(0.0, double.infinity);

  bool get isReached => currentAmount >= targetAmount;

  int? get daysLeft {
    if (targetDate == null) return null;
    return targetDate!.difference(DateTime.now()).inDays;
  }

  SavingsGoal copyWith({
    String? name,
    String? icon,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? linkedAccountId,
    bool? isCompleted,
    bool clearTargetDate = false,
    bool clearLinkedAccount = false,
  }) {
    return SavingsGoal(
      id: id,
      userId: userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      linkedAccountId: clearLinkedAccount
          ? null
          : (linkedAccountId ?? this.linkedAccountId),
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        icon,
        targetAmount,
        currentAmount,
        targetDate,
        linkedAccountId,
        isCompleted,
        createdAt,
      ];
}
