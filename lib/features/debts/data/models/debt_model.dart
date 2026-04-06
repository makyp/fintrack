import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/debt.dart';

class DebtPaymentModel extends DebtPayment {
  const DebtPaymentModel({
    required super.id,
    required super.amount,
    required super.date,
    super.note,
  });

  factory DebtPaymentModel.fromMap(Map<String, dynamic> data) {
    return DebtPaymentModel(
      id: data['id'] as String,
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        if (note != null) 'note': note,
      };
}

class DebtModel extends Debt {
  const DebtModel({
    required super.id,
    required super.userId,
    required super.personName,
    super.description,
    required super.originalAmount,
    required super.direction,
    required super.startDate,
    super.dueDate,
    super.hasInterest,
    super.monthlyInterestRate,
    super.isClosed,
    super.payments,
    required super.createdAt,
  });

  factory DebtModel.fromFirestore(Map<String, dynamic> data, String id) {
    final paymentsData = data['payments'] as List<dynamic>? ?? [];
    final payments = paymentsData
        .map((p) => DebtPaymentModel.fromMap(p as Map<String, dynamic>))
        .toList();
    return DebtModel(
      id: id,
      userId: data['userId'] as String,
      personName: data['personName'] as String,
      description: data['description'] as String?,
      originalAmount: (data['originalAmount'] as num).toDouble(),
      direction: data['direction'] == 'theyOweMe'
          ? DebtDirection.theyOweMe
          : DebtDirection.iOweThem,
      startDate: (data['startDate'] as Timestamp).toDate(),
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      hasInterest: data['hasInterest'] as bool? ?? false,
      monthlyInterestRate:
          (data['monthlyInterestRate'] as num? ?? 0).toDouble(),
      isClosed: data['isClosed'] as bool? ?? false,
      payments: payments,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'personName': personName,
        if (description != null) 'description': description,
        'originalAmount': originalAmount,
        'direction': direction == DebtDirection.theyOweMe
            ? 'theyOweMe'
            : 'iOweThem',
        'startDate': Timestamp.fromDate(startDate),
        'dueDate': dueDate != null
            ? Timestamp.fromDate(dueDate!)
            : FieldValue.delete(),
        'hasInterest': hasInterest,
        'monthlyInterestRate': monthlyInterestRate,
        'isClosed': isClosed,
        'payments': payments
            .map((p) => {
                  'id': p.id,
                  'amount': p.amount,
                  'date': Timestamp.fromDate(p.date),
                  if (p.note != null) 'note': p.note,
                })
            .toList(),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory DebtModel.fromEntity(Debt debt) {
    return DebtModel(
      id: debt.id,
      userId: debt.userId,
      personName: debt.personName,
      description: debt.description,
      originalAmount: debt.originalAmount,
      direction: debt.direction,
      startDate: debt.startDate,
      dueDate: debt.dueDate,
      hasInterest: debt.hasInterest,
      monthlyInterestRate: debt.monthlyInterestRate,
      isClosed: debt.isClosed,
      payments: debt.payments,
      createdAt: debt.createdAt,
    );
  }

  static DebtPayment newPayment(double amount, {String? note}) {
    return DebtPayment(
      id: const Uuid().v4(),
      amount: amount,
      date: DateTime.now(),
      note: note,
    );
  }
}
