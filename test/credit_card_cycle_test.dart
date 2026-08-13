import 'package:flutter_test/flutter_test.dart';

import 'package:fintrack/features/accounts/domain/entities/account.dart';
import 'package:fintrack/features/transactions/domain/entities/transaction.dart';
import 'package:fintrack/features/categories/domain/category_registry.dart';

Account card({int? statementDay, int? paymentDay, AccountType type = AccountType.credit}) {
  return Account(
    id: 'c1',
    userId: 'u1',
    name: 'Visa',
    type: type,
    balance: 500000,
    colorValue: 0xFF2563EB,
    icon: '💳',
    createdAt: DateTime(2026, 1, 1),
    statementDay: statementDay,
    paymentDay: paymentDay,
  );
}

Transaction purchase({int? installments, double amount = 1200000}) {
  return Transaction(
    id: 't1',
    userId: 'u1',
    amount: amount,
    type: TransactionType.expense,
    category: CategoryRegistry.byId('shopping'),
    accountId: 'c1',
    description: 'Nevera',
    date: DateTime(2026, 8, 11),
    createdAt: DateTime(2026, 8, 11),
    installments: installments,
  );
}

void main() {
  group('billing cycle', () {
    test('is only configured when both dates are present on a credit card', () {
      expect(card(statementDay: 15, paymentDay: 5).hasBillingCycle, isTrue);
      expect(card(statementDay: 15).hasBillingCycle, isFalse);
      expect(card(paymentDay: 5).hasBillingCycle, isFalse);
      expect(
        card(statementDay: 15, paymentDay: 5, type: AccountType.savings)
            .hasBillingCycle,
        isFalse,
        reason: 'only credit cards have a statement',
      );
    });

    test('a day still ahead this month resolves within this month', () {
      final a = card(statementDay: 20, paymentDay: 28);
      final from = DateTime(2026, 8, 11);

      expect(a.nextStatementDate(from: from), DateTime(2026, 8, 20));
      expect(a.nextPaymentDate(from: from), DateTime(2026, 8, 28));
    });

    test('today counts as the occurrence, it is not skipped to next month', () {
      final a = card(statementDay: 11, paymentDay: 11);
      final from = DateTime(2026, 8, 11);

      expect(a.nextStatementDate(from: from), DateTime(2026, 8, 11));
    });

    test('a day already past rolls into next month', () {
      final a = card(statementDay: 5, paymentDay: 2);
      final from = DateTime(2026, 8, 11);

      expect(a.nextStatementDate(from: from), DateTime(2026, 9, 5));
      expect(a.nextPaymentDate(from: from), DateTime(2026, 9, 2));
    });

    test('December rolls over into the next year', () {
      final a = card(statementDay: 3, paymentDay: 10);
      final from = DateTime(2026, 12, 20);

      expect(a.nextStatementDate(from: from), DateTime(2027, 1, 3));
      expect(a.nextPaymentDate(from: from), DateTime(2027, 1, 10));
    });

    test('day 31 clamps to the last day of a shorter month', () {
      final a = card(statementDay: 31, paymentDay: 30);

      // February 2026 has 28 days.
      expect(a.nextStatementDate(from: DateTime(2026, 2, 1)),
          DateTime(2026, 2, 28));
      expect(
          a.nextPaymentDate(from: DateTime(2026, 2, 1)), DateTime(2026, 2, 28));
      // April has 30.
      expect(a.nextStatementDate(from: DateTime(2026, 4, 1)),
          DateTime(2026, 4, 30));
    });

    test('day 29 lands on Feb 29 in a leap year', () {
      final a = card(statementDay: 29, paymentDay: 29);
      expect(a.nextStatementDate(from: DateTime(2028, 2, 1)),
          DateTime(2028, 2, 29));
    });

    test('a card without dates reports no upcoming dates', () {
      final a = card();
      expect(a.nextStatementDate(from: DateTime(2026, 8, 11)), isNull);
      expect(a.nextPaymentDate(from: DateTime(2026, 8, 11)), isNull);
    });

    test('copyWith clears the cycle when the account stops being a card', () {
      final cleared = card(statementDay: 15, paymentDay: 5)
          .copyWith(type: AccountType.savings, clearBillingCycle: true);

      expect(cleared.statementDay, isNull);
      expect(cleared.paymentDay, isNull);
      expect(cleared.hasBillingCycle, isFalse);
    });
  });

  group('installments', () {
    test('null or 1 instalment is not a deferred purchase', () {
      expect(purchase().isDeferred, isFalse);
      expect(purchase(installments: 1).isDeferred, isFalse);
      expect(purchase().installmentAmount, isNull);
      expect(purchase(installments: 1).installmentAmount, isNull);
    });

    test('splits the amount across the instalments', () {
      final tx = purchase(installments: 12, amount: 1200000);
      expect(tx.isDeferred, isTrue);
      expect(tx.installmentAmount, 100000);
    });

    test('the full amount still hits the card debt, not the instalment', () {
      final tx = purchase(installments: 6, amount: 600000);
      expect(tx.amount, 600000,
          reason: 'deferring changes how you pay, not what you owe');
      expect(tx.installmentAmount, 100000);
    });

    test('copyWith can drop the plan when the card is no longer the source',
        () {
      final tx = purchase(installments: 12).copyWith(clearInstallments: true);
      expect(tx.installments, isNull);
      expect(tx.isDeferred, isFalse);
    });
  });
}
