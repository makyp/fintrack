import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/budget.dart';

class BudgetModel extends Budget {
  const BudgetModel({
    required super.categoryId,
    required super.amount,
    required super.updatedAt,
  });

  factory BudgetModel.fromFirestore(Map<String, dynamic> map, String id) {
    return BudgetModel(
      categoryId: id,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'amount': amount,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  static BudgetModel fromEntity(Budget b) => BudgetModel(
        categoryId: b.categoryId,
        amount: b.amount,
        updatedAt: b.updatedAt,
      );
}
