import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/features/capture/domain/parsers/receipt_parser.dart';
import 'package:fintrack/features/capture/domain/parsers/spanish_amount_parser.dart';
import 'package:fintrack/features/capture/domain/parsers/voice_transaction_parser.dart';
import 'package:fintrack/features/transactions/domain/entities/transaction.dart';

void main() {
  group('SpanishAmountParser', () {
    test('reads plain and grouped digits', () {
      expect(SpanishAmountParser.parse('25000'), 25000);
      expect(SpanishAmountParser.parse('25.000'), 25000);
      expect(SpanishAmountParser.parse('25,000'), 25000);
      expect(SpanishAmountParser.parse(r'$25.000'), 25000);
      expect(SpanishAmountParser.parse('1.250.000'), 1250000);
    });

    test('reads digits with a multiplier', () {
      expect(SpanishAmountParser.parse('25 mil'), 25000);
      expect(SpanishAmountParser.parse('25k'), 25000);
      expect(SpanishAmountParser.parse('2 millones'), 2000000);
      expect(SpanishAmountParser.parse('1,5 millones'), 1500000);
    });

    test('reads Colombian slang', () {
      expect(SpanishAmountParser.parse('20 lucas'), 20000);
      expect(SpanishAmountParser.parse('3 palos'), 3000000);
    });

    test('reads number words', () {
      expect(SpanishAmountParser.parse('veinticinco mil'), 25000);
      expect(SpanishAmountParser.parse('treinta y cinco mil'), 35000);
      expect(SpanishAmountParser.parse('cien mil'), 100000);
      expect(SpanishAmountParser.parse('dos millones'), 2000000);
      expect(
        SpanishAmountParser.parse('dos millones trescientos mil'),
        2300000,
      );
      expect(SpanishAmountParser.parse('mil quinientos'), 1500);
    });

    test('ignores bare small numbers that are not amounts', () {
      expect(SpanishAmountParser.parse('compre 2 almuerzos'), isNull);
    });

    test('still accepts a small number with a currency signal', () {
      expect(SpanishAmountParser.parse('50 pesos'), 50);
    });
  });

  group('VoiceTransactionParser', () {
    final reference = DateTime(2026, 8, 10); // lunes

    test('parses a simple expense', () {
      final draft = VoiceTransactionParser.parse(
        'gasté 25 mil en almuerzo',
        reference: reference,
      );

      expect(draft.amount, 25000);
      expect(draft.type, TransactionType.expense);
      expect(draft.description, 'Almuerzo');
      expect(draft.category, TransactionCategory.food);
    });

    test('parses income with a relative date', () {
      final draft = VoiceTransactionParser.parse(
        'me pagaron el salario dos millones ayer',
        reference: reference,
      );

      expect(draft.amount, 2000000);
      expect(draft.type, TransactionType.income);
      expect(draft.category, TransactionCategory.salary);
      expect(draft.date, DateTime(2026, 8, 9));
    });

    test('parses a transfer', () {
      final draft = VoiceTransactionParser.parse(
        'transferí 100 mil a ahorros',
        reference: reference,
      );

      expect(draft.amount, 100000);
      expect(draft.type, TransactionType.transfer);
      expect(draft.description, 'Ahorros');
    });

    test('does not read the day of an explicit date as the amount', () {
      final draft = VoiceTransactionParser.parse(
        'el 5 de marzo pagué 80.000 de internet',
        reference: reference,
      );

      expect(draft.amount, 80000);
      expect(draft.date, DateTime(2026, 3, 5));
      expect(draft.category, TransactionCategory.home);
    });

    test('handles "hace 3 días"', () {
      final draft = VoiceTransactionParser.parse(
        'gasté 12 mil en uber hace 3 días',
        reference: reference,
      );

      expect(draft.amount, 12000);
      expect(draft.date, DateTime(2026, 8, 7));
      expect(draft.category, TransactionCategory.transport);
      expect(draft.description, 'Uber');
    });

    test('returns an empty draft for gibberish', () {
      final draft = VoiceTransactionParser.parse('', reference: reference);
      expect(draft.isEmpty, isTrue);
      expect(draft.hasAmount, isFalse);
    });
  });

  group('ReceiptParser', () {
    final reference = DateTime(2026, 8, 10);

    test('picks the labelled total, not the subtotal', () {
      const text = '''
SUPERMERCADO LA 14
NIT 890.123.456-7
Calle 10 # 5-20
FACTURA POS 00123
FECHA: 08/08/2026
------------------
Arroz            4.500
Leche            6.200
SUBTOTAL        10.700
IVA              2.033
TOTAL A PAGAR   12.733
EFECTIVO        20.000
CAMBIO           7.267
''';

      final draft = ReceiptParser.parse(text, reference: reference);

      expect(draft.amount, 12733);
      expect(draft.type, TransactionType.expense);
      expect(draft.date, DateTime(2026, 8, 8));
      expect(draft.merchant, 'Supermercado la 14');
    });

    test('reads the total when it sits on the next line', () {
      const text = '''
DROGUERIA CRUZ VERDE
TOTAL
32.900
''';

      final draft = ReceiptParser.parse(text, reference: reference);
      expect(draft.amount, 32900);
      expect(draft.category, TransactionCategory.health);
    });

    test('returns no amount rather than guessing the biggest number', () {
      // The big numbers here are a barcode and a NIT — not a total.
      const text = '''
TIENDA DON JOSE
NIT 900.456.789-1
7702004003114
Gaseosa       3.500
Pan           2.000
''';

      final draft = ReceiptParser.parse(text, reference: reference);
      expect(draft.amount, isNull);
      expect(draft.hasAmount, isFalse);
    });

    test('ignores invoice header fields that carry a number', () {
      // "CONSUMIDOR FINAL 222222222" used to read as a product: it has words
      // and a big number. The generic NIT is a long digit run, not a price.
      const text = '''
RESTAURANTE EL BUEN SABOR
NIT 900.123.456-7
CONSUMIDOR FINAL          222222222
CIUDAD MEDELLIN
MESA 4
FECHA 09/08/2026
2 BANDEJA PAISA          46.000
1 LIMONADA                7.500
TOTAL A PAGAR            53.500
''';

      final draft = ReceiptParser.parse(text, reference: reference);

      expect(draft.amount, 53500);
      expect(draft.products, ['Bandeja paisa', 'Limonada']);
    });

    test('drops non quantity-prefixed lines when the receipt uses quantities',
        () {
      // The receipt clearly prints "qty product price", so the stray
      // reference line without a quantity is not an item.
      const text = '''
TIENDA LA ESQUINA
3 AREPA DE QUESO          9.000
2 CAFE TINTO              4.000
1 JUGO NATURAL            5.500
REFERENCIA PEDIDO         4.821
TOTAL                    18.500
''';

      final draft = ReceiptParser.parse(text, reference: reference);
      expect(draft.products, ['Arepa de queso', 'Cafe tinto', 'Jugo natural']);
    });

    test('keeps products whose line starts with a barcode', () {
      const text = '''
SUPERMERCADO
7702004003114 ARROZ DIANA        4.500
7702354561230 LECHE COLANTA      6.200
TOTAL A PAGAR                   10.700
''';

      final draft = ReceiptParser.parse(text, reference: reference);
      expect(draft.products, ['Arroz diana', 'Leche colanta']);
    });

    test('strips the quantity from the product name', () {
      const text = '''
PANADERIA
2 PAN INTEGRAL            6.000
1,5 KG QUESO             28.000
TOTAL                    34.000
''';

      final draft = ReceiptParser.parse(text, reference: reference);
      expect(draft.products, ['Pan integral', 'Queso']);
    });

    test('lists the identified products in the description', () {
      const text = '''
EXITO POBLADO
NIT 890.900.608-9
FECHA 09/08/2026
Arroz Diana 500 GR      4.500
Leche Colanta 1 LT      6.200
Pan Bimbo               5.300
TOTAL A PAGAR          16.000
''';

      final draft = ReceiptParser.parse(text, reference: reference);

      expect(draft.amount, 16000);
      expect(draft.products, ['Arroz diana', 'Leche colanta', 'Pan bimbo']);
      expect(draft.description, 'Exito poblado: Arroz diana, Leche colanta, Pan bimbo');
    });

    group('date formats', () {
      DateTime? dateOf(String line) => ReceiptParser.parse(
            'TIENDA\n$line\nTOTAL 10.000',
            reference: reference,
          ).date;

      test('dd/mm/yyyy', () => expect(dateOf('FECHA 05/03/2026'), DateTime(2026, 3, 5)));

      test('mm/dd/yyyy when the second number cannot be a month',
          () => expect(dateOf('FECHA 03/25/2026'), DateTime(2026, 3, 25)));

      test('ISO yyyy-mm-dd',
          () => expect(dateOf('FECHA 2026-03-05'), DateTime(2026, 3, 5)));

      test('two-digit year',
          () => expect(dateOf('FECHA 05-03-26'), DateTime(2026, 3, 5)));

      test('month by name',
          () => expect(dateOf('FECHA 09 AGO 2026'), DateTime(2026, 8, 9)));

      test('spelled out with "de"',
          () => expect(dateOf('Fecha: 9 de agosto de 2026'), DateTime(2026, 8, 9)));

      test('ambiguous pair prefers dd/mm', () {
        // 04/08 is both a valid dd/mm and mm/dd; Colombian layout wins.
        expect(dateOf('FECHA 04/08/2026'), DateTime(2026, 8, 4));
      });

      test('swaps to mm/dd when dd/mm would be in the future', () {
        // 07/09 as dd/mm is September 7 — after the reference date — while
        // the mm/dd reading (July 9) is in the past, so that one wins.
        expect(dateOf('FECHA 07/09/2026'), DateTime(2026, 7, 9));
      });

      test('gives up when neither reading is in the past', () {
        // 10/09 is September 10 or October 9; both are still ahead.
        expect(dateOf('FECHA 10/09/2026'), isNull);
      });

      test('rejects a future date outright',
          () => expect(dateOf('FECHA 25/12/2027'), isNull));

      test('prefers the line labelled "fecha" over other numbers', () {
        const text = '''
TIENDA
FACTURA 12/34/56
FECHA 07/08/2026
TOTAL 10.000
''';
        expect(
          ReceiptParser.parse(text, reference: reference).date,
          DateTime(2026, 8, 7),
        );
      });
    });
  });
}
