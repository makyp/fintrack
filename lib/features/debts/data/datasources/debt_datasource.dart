import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/debt.dart';
import '../models/debt_model.dart';

class DebtDataSource {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  DebtDataSource(this._firestore, this._uuid);

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _firestore.collection('users').doc(userId).collection('debts');

  Stream<List<Debt>> watchDebts(String userId) {
    return _col(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => DebtModel.fromFirestore(d.data(), d.id))
            .toList());
  }

  Future<Debt> add(Debt debt) async {
    final id = _uuid.v4();
    final model = DebtModel.fromEntity(Debt(
      id: id,
      userId: debt.userId,
      personName: debt.personName,
      description: debt.description,
      originalAmount: debt.originalAmount,
      direction: debt.direction,
      startDate: debt.startDate,
      dueDate: debt.dueDate,
      hasInterest: debt.hasInterest,
      monthlyInterestRate: debt.monthlyInterestRate,
      isClosed: false,
      payments: const [],
      createdAt: DateTime.now(),
    ));
    await _col(debt.userId).doc(id).set(model.toFirestore());
    return model;
  }

  Future<Debt> update(Debt debt) async {
    final model = DebtModel.fromEntity(debt);
    await _col(debt.userId).doc(debt.id).update(model.toFirestore());
    return model;
  }

  Future<void> delete(String userId, String debtId) async {
    await _col(userId).doc(debtId).delete();
  }

  Future<Debt> addPayment(
      String userId, String debtId, double amount, {String? note}) async {
    final docRef = _col(userId).doc(debtId);
    late DebtModel updated;

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final current = DebtModel.fromFirestore(snap.data()!, snap.id);
      final payment = DebtModel.newPayment(amount, note: note);
      final newPayments = [...current.payments, payment];
      final newTotal = newPayments.fold(0.0, (s, p) => s + p.amount);
      final isClosed = newTotal >= current.currentTotal;
      updated = DebtModel.fromEntity(current.copyWith(
        payments: newPayments,
        isClosed: isClosed,
      ));
      tx.update(docRef, {
        'payments': updated.toFirestore()['payments'],
        'isClosed': isClosed,
      });
    });

    return updated;
  }

  Future<Debt> close(String userId, String debtId) async {
    await _col(userId).doc(debtId).update({'isClosed': true});
    final snap = await _col(userId).doc(debtId).get();
    return DebtModel.fromFirestore(snap.data()!, snap.id);
  }
}
