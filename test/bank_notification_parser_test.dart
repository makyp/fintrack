import 'package:fintrack/features/capture/domain/bank_notification_parser.dart';
import 'package:fintrack/features/capture/domain/entities/transaction_draft.dart';
import 'package:fintrack/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

BankNotification _notification(String text, {String title = 'Mi Banco'}) {
  return BankNotification(
    packageName: 'com.banco.app',
    title: title,
    text: text,
    postedAt: DateTime(2026, 8, 29, 14, 32),
  );
}

void main() {
  group('compras', () {
    test('lee monto y comercio de una compra tipica', () {
      final draft = BankNotificationParser.parse(
          _notification(r'Compra por $45.000 en RAPPI COLOMBIA'));
      expect(draft, isNotNull);
      expect(draft!.amount, 45000);
      expect(draft.type, TransactionType.expense);
      expect(draft.merchant, 'Rappi Colombia');
      expect(draft.source, CaptureSource.notification);
    });

    test('descarta la cola sobre la tarjeta', () {
      final draft = BankNotificationParser.parse(_notification(
          r'Compra aprobada por $120.500 en EXITO POBLADO con tu tarjeta *1234'));
      expect(draft!.amount, 120500);
      expect(draft.merchant, 'Exito Poblado');
    });

    test('se queda con el monto mayor, no con los digitos de la tarjeta', () {
      final draft = BankNotificationParser.parse(_notification(
          r'Pago por $89.900 en NETFLIX con tarjeta terminada en 1234'));
      expect(draft!.amount, 89900);
    });

    test('entiende el codigo de moneda en vez del simbolo', () {
      final draft = BankNotificationParser.parse(
          _notification('Realizaste una compra por COP 89.900 en Spotify'));
      expect(draft!.amount, 89900);
      expect(draft.type, TransactionType.expense);
    });

    test('lee decimales de una moneda con centavos', () {
      final draft = BankNotificationParser.parse(
          _notification('Pago aprobado por S/ 45.90 en PLAZA VEA'));
      expect(draft!.amount, 45.90);
    });

    test('un retiro tambien es gasto', () {
      final draft = BankNotificationParser.parse(
          _notification(r'Retiro por $200.000 en cajero automatico'));
      expect(draft!.type, TransactionType.expense);
      expect(draft.amount, 200000);
    });
  });

  group('ingresos', () {
    test('una transferencia recibida es ingreso', () {
      final draft = BankNotificationParser.parse(
          _notification(r'Recibiste una transferencia por $500.000 de JUAN PEREZ'));
      expect(draft!.type, TransactionType.income);
      expect(draft.amount, 500000);
    });

    test('distingue enviar de recibir', () {
      final enviado = BankNotificationParser.parse(
          _notification(r'Enviaste $50.000 a MARIA GOMEZ'));
      final recibido = BankNotificationParser.parse(
          _notification(r'Te enviaron $50.000 de MARIA GOMEZ'));
      expect(enviado!.type, TransactionType.expense);
      expect(recibido!.type, TransactionType.income);
    });

    test('una consignacion es ingreso', () {
      final draft = BankNotificationParser.parse(
          _notification(r'Te consignaron $1.000.000 en tu cuenta de ahorros'));
      expect(draft!.type, TransactionType.income);
      expect(draft.amount, 1000000);
    });
  });

  group('lo que NO es un movimiento', () {
    test('el aviso de saldo se ignora', () {
      expect(
          BankNotificationParser.parse(
              _notification(r'Tu saldo disponible es $2.350.000')),
          isNull);
    });

    test('un codigo de seguridad se ignora', () {
      expect(
          BankNotificationParser.parse(
              _notification('Tu codigo de verificacion es 445566')),
          isNull);
    });

    test('una promocion se ignora aunque traiga monto', () {
      expect(
          BankNotificationParser.parse(_notification(
              r'Aprovecha: compra hoy y gana $50.000 de descuento')),
          isNull);
    });

    test('una compra rechazada no se registra', () {
      expect(
          BankNotificationParser.parse(
              _notification(r'Compra rechazada por $30.000 en TIENDA')),
          isNull);
    });

    test('un mensaje sin monto se ignora', () {
      expect(
          BankNotificationParser.parse(
              _notification('Tu compra fue aprobada correctamente')),
          isNull);
    });

    test('un recordatorio de pago no es un pago', () {
      expect(
          BankNotificationParser.parse(
              _notification(r'Recuerda pagar tu cuota de $350.000')),
          isNull);
    });
  });

  group('utilidades', () {
    test('looksLikeMovement es el filtro barato del lado nativo', () {
      expect(
          BankNotificationParser.looksLikeMovement(r'Compra por $10.000 en X'),
          isTrue);
      expect(BankNotificationParser.looksLikeMovement('Hola, como estas'),
          isFalse);
    });

    test('la fecha del movimiento es la de la notificacion', () {
      final draft = BankNotificationParser.parse(
          _notification(r'Compra por $10.000 en TIENDA'));
      expect(draft!.date, DateTime(2026, 8, 29, 14, 32));
    });

    test('la misma notificacion dos veces tiene la misma huella', () {
      final a = _notification(r'Compra por $10.000 en TIENDA');
      final b = _notification(r'Compra por $10.000 en TIENDA');
      expect(a.fingerprint, b.fingerprint);
    });

    test('se reconstruye desde el JSON que deja el servicio nativo', () {
      final n = BankNotification.fromJson({
        'package': 'com.banco.app',
        'title': 'Banco',
        'text': r'Compra por $10.000 en TIENDA',
        'postedAt': DateTime(2026, 8, 29).millisecondsSinceEpoch,
      });
      expect(n.packageName, 'com.banco.app');
      expect(BankNotificationParser.parse(n)!.amount, 10000);
    });
  });
}
