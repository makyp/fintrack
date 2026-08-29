import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/firestore_write.dart';
import '../../domain/entities/debt.dart';
import '../models/debt_model.dart';

@lazySingleton
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
    fireAndForget(
        _col(debt.userId).doc(id).set(model.toFirestore()), 'addDebt');
    return model;
  }

  Future<Debt> update(Debt debt) async {
    final model = DebtModel.fromEntity(debt);
    final data = model.toFirestore();
    if (debt.dueDate == null) data['dueDate'] = FieldValue.delete();
    fireAndForget(_col(debt.userId).doc(debt.id).update(data), 'updateDebt');
    return model;
  }

  Future<void> delete(String userId, String debtId) async {
    fireAndForget(_col(userId).doc(debtId).delete(), 'deleteDebt');
  }

  Future<Debt> addPayment(
      String userId, String debtId, double amount, {String? note}) async {
    final docRef = _col(userId).doc(debtId);
    // Read-modify-write instead of runTransaction: a Firestore transaction
    // needs the server and fails offline; debts are single-user data, so the
    // cached read plus an update is safe and works without a connection.
    final snap = await docRef.get();
    final current = DebtModel.fromFirestore(snap.data()!, snap.id);
    final payment = DebtModel.newPayment(amount, note: note);
    final newPayments = [...current.payments, payment];
    final newTotal = newPayments.fold(0.0, (s, p) => s + p.amount);
    final isClosed = newTotal >= current.currentTotal;
    final updated = DebtModel.fromEntity(current.copyWith(
      payments: newPayments,
      isClosed: isClosed,
    ));
    fireAndForget(
        docRef.update({
          'payments': updated.toFirestore()['payments'],
          'isClosed': isClosed,
        }),
        'addDebtPayment');

    return updated;
  }

  Future<Debt> close(String userId, String debtId) async {
    fireAndForget(
        _col(userId).doc(debtId).update({'isClosed': true}), 'closeDebt');
    // The cached read already sees the pending write (latency compensation).
    final snap = await _col(userId).doc(debtId).get();
    return DebtModel.fromFirestore(snap.data()!, snap.id);
  }
}
