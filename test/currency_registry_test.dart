import 'package:fintrack/core/domain/currency.dart';
import 'package:fintrack/core/domain/currency_registry.dart';
import 'package:fintrack/core/utils/currency_formatter.dart';
import 'package:fintrack/features/accounts/domain/entities/account.dart';
import 'package:flutter_test/flutter_test.dart';

Account _account({
  required double balance,
  String currency = 'COP',
  AccountType type = AccountType.checking,
}) {
  return Account(
    id: 'a',
    userId: 'u',
    name: 'Cuenta',
    type: type,
    balance: balance,
    currency: currency,
    colorValue: 0,
    icon: '🏦',
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  tearDown(CurrencyRegistry.reset);

  group('conversión', () {
    test('la moneda base siempre vale 1, con o sin tasa cargada', () {
      CurrencyRegistry.snapshot(base: 'COP');
      expect(CurrencyRegistry.rateFor('COP'), 1);
      expect(CurrencyRegistry.toBase(1000, 'COP'), 1000);
    });

    test('convierte usando la tasa que escribió el usuario', () {
      CurrencyRegistry.snapshot(base: 'COP', rates: {'USD': 4000});
      expect(CurrencyRegistry.toBase(10, 'USD'), 40000);
      expect(CurrencyRegistry.fromBase(40000, 'USD'), 10);
    });

    test('sin tasa devuelve null en vez de convertir a 1:1', () {
      CurrencyRegistry.snapshot(base: 'COP');
      expect(CurrencyRegistry.toBase(10, 'USD'), isNull);
    });

    test('descarta tasas en cero o negativas al cargar el perfil', () {
      CurrencyRegistry.snapshot(base: 'COP', rates: {'USD': 0, 'EUR': -1});
      expect(CurrencyRegistry.rateFor('USD'), isNull);
      expect(CurrencyRegistry.rateFor('EUR'), isNull);
    });

    test('el código se normaliza a mayúsculas', () {
      CurrencyRegistry.snapshot(base: 'cop', rates: {'usd': 4000});
      expect(CurrencyRegistry.base, 'COP');
      expect(CurrencyRegistry.toBase(2, 'Usd'), 8000);
    });
  });

  group('balance consolidado', () {
    test('suma cuentas en distintas monedas convertidas a la base', () {
      CurrencyRegistry.snapshot(base: 'COP', rates: {'USD': 4000});
      final accounts = [
        _account(balance: 1000000),
        _account(balance: 250, currency: 'USD'),
      ];
      final net = accounts.consolidatedNet;
      expect(net.amount, 2000000); // 1.000.000 + 250 × 4.000
      expect(net.isComplete, isTrue);
    });

    test('una tarjeta de crédito resta, también en moneda extranjera', () {
      CurrencyRegistry.snapshot(base: 'COP', rates: {'USD': 4000});
      final accounts = [
        _account(balance: 1000000),
        _account(balance: 100, currency: 'USD', type: AccountType.credit),
      ];
      expect(accounts.consolidatedNet.amount, 600000);
    });

    test('la cuenta sin tasa queda fuera del total y se reporta', () {
      CurrencyRegistry.snapshot(base: 'COP', rates: {'USD': 4000});
      final accounts = [
        _account(balance: 1000000),
        _account(balance: 50, currency: 'EUR'),
      ];
      final net = accounts.consolidatedNet;
      expect(net.amount, 1000000);
      expect(net.missingRates, ['EUR']);
      expect(net.isComplete, isFalse);
    });

    test('detecta cuándo hay más de una moneda en juego', () {
      final single = [_account(balance: 1), _account(balance: 2)];
      final mixed = [_account(balance: 1), _account(balance: 2, currency: 'USD')];
      expect(single.isMultiCurrency, isFalse);
      expect(mixed.isMultiCurrency, isTrue);
      expect(mixed.currenciesInUse, ['COP', 'USD']);
    });
  });

  group('formato', () {
    test('usa el símbolo y los decimales de cada moneda', () {
      CurrencyRegistry.snapshot(base: 'COP');
      expect(CurrencyFormatter.format(1250), r'$1.250');
      expect(CurrencyFormatter.format(1250.5, code: 'USD'), r'US$1.250,50');
    });

    test('sin código explícito toma la moneda base del usuario', () {
      CurrencyRegistry.snapshot(base: 'PEN');
      expect(CurrencyFormatter.format(20), 'S/20,00');
    });

    test('una moneda desconocida se muestra con su propio código', () {
      expect(Currency.byCode('XYZ').symbol, 'XYZ');
      expect(Currency.isKnown('XYZ'), isFalse);
    });
  });
}
