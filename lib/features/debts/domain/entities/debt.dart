import 'dart:math' as math;
import 'package:equatable/equatable.dart';

enum DebtDirection {
  theyOweMe,  // alguien me debe
  iOweThem,   // yo le debo a alguien
}

class DebtPayment extends Equatable {
  final String id;
  final double amount;
  final DateTime date;
  final String? note;

  const DebtPayment({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
  });

  @override
  List<Object?> get props => [id, amount, date, note];
}

class Debt extends Equatable {
  final String id;
  final String userId;
  final String personName;
  final String? description;
  final double originalAmount;
  final DebtDirection direction;
  final DateTime startDate;
  final DateTime? dueDate;
  final bool hasInterest;
  final double monthlyInterestRate; // percentage, e.g. 2.0 = 2%/month
  final bool isClosed;
  final List<DebtPayment> payments;
  final DateTime createdAt;

  const Debt({
    required this.id,
    required this.userId,
    required this.personName,
    this.description,
    required this.originalAmount,
    required this.direction,
    required this.startDate,
    this.dueDate,
    this.hasInterest = false,
    this.monthlyInterestRate = 0,
    this.isClosed = false,
    this.payments = const [],
    required this.createdAt,
  });

  double get totalPaid =>
      payments.fold(0, (sum, p) => sum + p.amount);

  /// Accrued amount with compound monthly interest from startDate to now.
  double get currentTotal {
    if (!hasInterest || monthlyInterestRate <= 0) return originalAmount;
    final months = DateTime.now().difference(startDate).inDays / 30.0;
    return originalAmount * math.pow(1 + monthlyInterestRate / 100, months).toDouble();
  }

  double get pendingAmount => (currentTotal - totalPaid).clamp(0, double.infinity);

  bool get isOverdue {
    if (isClosed || dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  int? get daysUntilDue {
    if (dueDate == null) return null;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  Debt copyWith({
    String? personName,
    String? description,
    double? originalAmount,
    DebtDirection? direction,
    DateTime? startDate,
    DateTime? dueDate,
    bool? hasInterest,
    double? monthlyInterestRate,
    bool? isClosed,
    List<DebtPayment>? payments,
    bool clearDueDate = false,
  }) {
    return Debt(
      id: id,
      userId: userId,
      personName: personName ?? this.personName,
      description: description ?? this.description,
      originalAmount: originalAmount ?? this.originalAmount,
      direction: direction ?? this.direction,
      startDate: startDate ?? this.startDate,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      hasInterest: hasInterest ?? this.hasInterest,
      monthlyInterestRate: monthlyInterestRate ?? this.monthlyInterestRate,
      isClosed: isClosed ?? this.isClosed,
      payments: payments ?? this.payments,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        personName,
        description,
        originalAmount,
        direction,
        startDate,
        dueDate,
        hasInterest,
        monthlyInterestRate,
        isClosed,
        payments,
        createdAt,
      ];
}
