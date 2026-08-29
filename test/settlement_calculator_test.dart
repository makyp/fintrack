import 'package:fintrack/features/household/domain/entities/shared_expense.dart';
import 'package:fintrack/features/household/domain/settlement_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

SharedExpense _expense({
  required double amount,
  required String paidBy,
  required Map<String, double> shares,
}) {
  return SharedExpense(
    id: 'e',
    householdId: 'h',
    description: 'Gasto',
    amount: amount,
    currency: 'COP',
    date: DateTime(2026, 8, 1),
    paidBy: paidBy,
    shares: shares,
    mode: SplitMode.equal,
    createdBy: paidBy,
    createdAt: DateTime(2026, 8, 1),
  );
}

double _netOf(List<MemberBalance> balances, String uid) =>
    balances.firstWhere((b) => b.uid == uid).net;

void main() {
  group('reparto en partes iguales', () {
    test('divide exacto cuando el monto es divisible', () {
      final shares = SharedExpense.equalShares(90, ['a', 'b', 'c'], 'a');
      expect(shares, {'a': 30.0, 'b': 30.0, 'c': 30.0});
    });

    test('los centavos sobrantes van a quien pago, y el total cuadra', () {
      final shares = SharedExpense.equalShares(100, ['a', 'b', 'c'], 'a');
      expect(shares['a'], 33.34);
      expect(shares['b'], 33.33);
      expect(shares['c'], 33.33);
      final total = shares.values.reduce((x, y) => x + y);
      expect(total, closeTo(100, 0.001));
    });

    test('sin participantes no reparte nada', () {
      expect(SharedExpense.equalShares(100, const [], 'a'), isEmpty);
    });
  });

  group('saldos', () {
    test('quien pago queda acreedor por lo que pusieron los demas', () {
      final balances = SettlementCalculator.balances(
        members: ['a', 'b'],
        expenses: [
          _expense(amount: 100, paidBy: 'a', shares: {'a': 50, 'b': 50}),
        ],
        settlements: const [],
      );
      expect(_netOf(balances, 'a'), 50);
      expect(_netOf(balances, 'b'), -50);
    });

    test('los gastos cruzados se compensan', () {
      final balances = SettlementCalculator.balances(
        members: ['a', 'b'],
        expenses: [
          _expense(amount: 100, paidBy: 'a', shares: {'a': 50, 'b': 50}),
          _expense(amount: 60, paidBy: 'b', shares: {'a': 30, 'b': 30}),
        ],
        settlements: const [],
      );
      expect(_netOf(balances, 'a'), 20);
      expect(_netOf(balances, 'b'), -20);
    });

    test('un pago entre miembros cancela la deuda', () {
      final balances = SettlementCalculator.balances(
        members: ['a', 'b'],
        expenses: [
          _expense(amount: 100, paidBy: 'a', shares: {'a': 50, 'b': 50}),
        ],
        settlements: [
          Settlement(
            id: 's',
            householdId: 'h',
            from: 'b',
            to: 'a',
            amount: 50,
            currency: 'COP',
            date: DateTime(2026, 8, 2),
            createdBy: 'b',
          ),
        ],
      );
      expect(balances.every((b) => b.isSettled), isTrue);
    });

    test('un miembro sin gastos aparece en cero', () {
      final balances = SettlementCalculator.balances(
        members: ['a', 'b', 'c'],
        expenses: [
          _expense(amount: 100, paidBy: 'a', shares: {'a': 50, 'b': 50}),
        ],
        settlements: const [],
      );
      expect(_netOf(balances, 'c'), 0);
      expect(balances, hasLength(3));
    });

    test('todo suma cero: lo que unos deben es lo que otros tienen a favor', () {
      final balances = SettlementCalculator.balances(
        members: ['a', 'b', 'c'],
        expenses: [
          _expense(amount: 100, paidBy: 'a', shares: {'a': 33.34, 'b': 33.33, 'c': 33.33}),
          _expense(amount: 45, paidBy: 'c', shares: {'a': 15, 'b': 15, 'c': 15}),
        ],
        settlements: const [],
      );
      final total = balances.fold<double>(0, (s, b) => s + b.net);
      expect(total, closeTo(0, 0.01));
    });
  });

  group('liquidacion', () {
    test('dos personas se saldan con un solo pago', () {
      final balances = SettlementCalculator.balances(
        members: ['a', 'b'],
        expenses: [
          _expense(amount: 100, paidBy: 'a', shares: {'a': 50, 'b': 50}),
        ],
        settlements: const [],
      );
      final transfers = SettlementCalculator.settlements(balances);
      expect(transfers, hasLength(1));
      expect(transfers.first.from, 'b');
      expect(transfers.first.to, 'a');
      expect(transfers.first.amount, 50);
    });

    test('con dos deudores y un acreedor bastan dos pagos', () {
      final balances = SettlementCalculator.balances(
        members: ['a', 'b', 'c'],
        expenses: [
          _expense(amount: 90, paidBy: 'a', shares: {'a': 30, 'b': 30, 'c': 30}),
        ],
        settlements: const [],
      );
      final transfers = SettlementCalculator.settlements(balances);
      expect(transfers, hasLength(2));
      expect(transfers.every((t) => t.to == 'a'), isTrue);
      expect(transfers.fold<double>(0, (s, t) => s + t.amount), 60);
    });

    test('si nadie debe nada no propone ningun pago', () {
      final balances = SettlementCalculator.balances(
        members: ['a', 'b'],
        expenses: [
          _expense(amount: 100, paidBy: 'a', shares: {'a': 100}),
        ],
        settlements: const [],
      );
      expect(SettlementCalculator.settlements(balances), isEmpty);
    });

    test('los pagos propuestos cancelan exactamente los saldos', () {
      final balances = SettlementCalculator.balances(
        members: ['a', 'b', 'c', 'd'],
        expenses: [
          _expense(amount: 200, paidBy: 'a', shares: {'a': 50, 'b': 50, 'c': 50, 'd': 50}),
          _expense(amount: 80, paidBy: 'b', shares: {'b': 40, 'c': 40}),
        ],
        settlements: const [],
      );
      final transfers = SettlementCalculator.settlements(balances);
      final after = {for (final b in balances) b.uid: b.net};
      for (final t in transfers) {
        after[t.from] = after[t.from]! + t.amount;
        after[t.to] = after[t.to]! - t.amount;
      }
      for (final entry in after.entries) {
        expect(entry.value, closeTo(0, 0.01), reason: entry.key);
      }
    });
  });
}
