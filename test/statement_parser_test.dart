import 'package:fintrack/features/transactions/domain/statement_parser.dart';
import 'package:fintrack/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('montos', () {
    test('lee el formato con coma decimal y punto de miles', () {
      expect(StatementParser.parseAmount('1.234,56'), 1234.56);
      expect(StatementParser.parseAmount('-1.234,56'), -1234.56);
    });

    test('lee el formato con punto decimal y coma de miles', () {
      expect(StatementParser.parseAmount('1,234.56'), 1234.56);
    });

    test('un grupo de tres sin decimales es de miles, no un decimal', () {
      expect(StatementParser.parseAmount('1.234'), 1234);
      expect(StatementParser.parseAmount('1,234'), 1234);
    });

    test('respeta el decimal cuando no son tres cifras', () {
      expect(StatementParser.parseAmount('12,5'), 12.5);
      expect(StatementParser.parseAmount('12.75'), 12.75);
    });

    test('entiende las convenciones contables del signo', () {
      expect(StatementParser.parseAmount('(500)'), -500);
      expect(StatementParser.parseAmount('500-'), -500);
      expect(StatementParser.parseAmount(r'$ 500'), 500);
      expect(StatementParser.parseAmount('COP 1.500,00'), 1500);
    });

    test('descarta lo que no es un monto', () {
      expect(StatementParser.parseAmount(''), isNull);
      expect(StatementParser.parseAmount('saldo'), isNull);
    });
  });

  group('fechas', () {
    test('lee los tres ordenes habituales', () {
      expect(StatementParser.parseDate('2026-03-15'), DateTime(2026, 3, 15));
      expect(StatementParser.parseDate('15/03/2026'), DateTime(2026, 3, 15));
      expect(StatementParser.parseDate('15-03-26'), DateTime(2026, 3, 15));
    });

    test('la ambigua se lee dia primero, como exportan los bancos', () {
      expect(StatementParser.parseDate('03/04/2026'), DateTime(2026, 4, 3));
    });

    test('lee el mes escrito', () {
      expect(StatementParser.parseDate('15 ene 2026'), DateTime(2026, 1, 15));
      expect(StatementParser.parseDate('15-DIC-25'), DateTime(2025, 12, 15));
    });

    test('rechaza una fecha que no existe en vez de correrla de mes', () {
      expect(StatementParser.parseDate('31/02/2026'), isNull);
      expect(StatementParser.parseDate('hola'), isNull);
    });
  });

  group('separador y comillas', () {
    test('detecta el punto y coma de los exportes en espanol', () {
      const csv = 'Fecha;Concepto;Importe\n15/03/2026;Pago, en cuotas;-1.000,50';
      expect(StatementParser.detectDelimiter(csv), ';');
    });

    test('no parte por una coma que esta dentro de comillas', () {
      final cells =
          StatementParser.splitLine('15/03/2026,"Pago, tienda",-1000', ',');
      expect(cells, ['15/03/2026', 'Pago, tienda', '-1000']);
    });

    test('respeta la comilla escapada', () {
      final cells = StatementParser.splitLine('a,"di ""hola""",b', ',');
      expect(cells[1], 'di "hola"');
    });
  });

  group('extracto completo', () {
    test('mapea columnas por titulo y separa gastos de ingresos', () {
      const csv = '''
Fecha;Descripcion;Importe
15/03/2026;Supermercado Exito;-125.400
16/03/2026;Nomina marzo;3.200.000
''';
      final parsed = StatementParser.parse(csv);
      expect(parsed.hasHeader, isTrue);
      expect(parsed.mapping.isUsable, isTrue);

      final entries = StatementParser.toEntries(parsed, parsed.mapping);
      expect(entries, hasLength(2));
      expect(entries.first.type, TransactionType.expense);
      expect(entries.first.amount, 125400);
      expect(entries.first.description, 'Supermercado Exito');
      expect(entries.last.type, TransactionType.income);
      expect(entries.last.amount, 3200000);
    });

    test('usa columnas separadas de cargo y abono', () {
      const csv = '''
Fecha,Concepto,Cargo,Abono
01/04/2026,Netflix,44900,
02/04/2026,Transferencia recibida,,150000
''';
      final parsed = StatementParser.parse(csv);
      expect(parsed.mapping.debit, 2);
      expect(parsed.mapping.credit, 3);
      expect(parsed.mapping.amount, -1);

      final entries = StatementParser.toEntries(parsed, parsed.mapping);
      expect(entries.first.type, TransactionType.expense);
      expect(entries.first.amount, 44900);
      expect(entries.last.type, TransactionType.income);
      expect(entries.last.amount, 150000);
    });

    test('adivina las columnas cuando el archivo no trae titulos', () {
      const csv = '''
15/03/2026,Supermercado,-125400
16/03/2026,Nomina,3200000
''';
      final parsed = StatementParser.parse(csv);
      expect(parsed.hasHeader, isFalse);
      expect(parsed.mapping.date, 0);
      expect(parsed.mapping.description, 1);
      expect(parsed.mapping.amount, 2);
      expect(StatementParser.toEntries(parsed, parsed.mapping), hasLength(2));
    });

    test('descarta subtotales y pies de pagina sin fecha', () {
      const csv = '''
Fecha;Descripcion;Importe
15/03/2026;Compra;-1000
;TOTAL;-1000
''';
      final parsed = StatementParser.parse(csv);
      expect(StatementParser.toEntries(parsed, parsed.mapping), hasLength(1));
    });

    test('ignora el BOM que escribe Excel', () {
      const csv = '﻿Fecha;Importe\n15/03/2026;-1000';
      final parsed = StatementParser.parse(csv);
      expect(parsed.header.first, 'Fecha');
      expect(parsed.mapping.date, 0);
    });

    test('la huella permite reconocer el mismo movimiento dos veces', () {
      const csv = 'Fecha;Descripcion;Importe\n15/03/2026;Compra;-1000';
      final a = StatementParser.toEntries(
          StatementParser.parse(csv), StatementParser.parse(csv).mapping);
      final b = StatementParser.toEntries(
          StatementParser.parse(csv), StatementParser.parse(csv).mapping);
      expect(a.first.fingerprint, b.first.fingerprint);
    });

    test('un archivo vacio no rompe nada', () {
      final parsed = StatementParser.parse('');
      expect(parsed.isEmpty, isTrue);
      expect(StatementParser.toEntries(parsed, parsed.mapping), isEmpty);
    });
  });
}
