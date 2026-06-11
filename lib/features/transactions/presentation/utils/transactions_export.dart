import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/transaction.dart';

/// Exports a list of transactions (the full history, or the full filtered set)
/// to CSV or PDF and opens the system share sheet so the user can save / send it.
class TransactionsExport {
  static final _dateFmt = DateFormat('dd/MM/yyyy', 'es');
  static final _timeFmt = DateFormat('HH:mm', 'es');

  static String _typeLabel(TransactionType t) {
    switch (t) {
      case TransactionType.expense:
        return 'Gasto';
      case TransactionType.income:
        return 'Ingreso';
      case TransactionType.transfer:
        return 'Transferencia';
    }
  }

  /// Signed amount: expenses negative, income positive, transfer left as-is.
  static double _signedAmount(Transaction t) {
    switch (t.type) {
      case TransactionType.expense:
        return -t.amount;
      case TransactionType.income:
      case TransactionType.transfer:
        return t.amount;
    }
  }

  static String _fmtMoney(double v) {
    final s = v.abs().toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return v < 0 ? '-\$ $s' : '\$ $s';
  }

  // ── CSV ────────────────────────────────────────────────────────────────────

  static String _csvCell(Object? value) {
    final s = value?.toString() ?? '';
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static Future<void> shareCsv(
    List<Transaction> txs, {
    required Map<String, String> accountNames,
  }) async {
    final rows = <String>[];
    rows.add([
      'Fecha',
      'Hora',
      'Tipo',
      'Categoría',
      'Descripción',
      'Cuenta',
      'Cuenta destino',
      'Monto',
    ].map(_csvCell).join(','));

    for (final t in txs) {
      rows.add([
        _dateFmt.format(t.date),
        _timeFmt.format(t.date),
        _typeLabel(t.type),
        t.category.label,
        t.description,
        accountNames[t.accountId] ?? '',
        t.toAccountId != null ? (accountNames[t.toAccountId] ?? '') : '',
        _signedAmount(t).toStringAsFixed(2),
      ].map(_csvCell).join(','));
    }

    // UTF-8 BOM so Excel renders accents (á, ñ, …) correctly.
    final content = '﻿${rows.join('\r\n')}';
    final dir = await getTemporaryDirectory();
    final fileName = 'movimientos_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(utf8.encode(content));

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv', name: fileName)],
      subject: 'Histórico de movimientos',
    );
  }

  // ── PDF ────────────────────────────────────────────────────────────────────

  static Future<void> sharePdf(
    List<Transaction> txs, {
    required Map<String, String> accountNames,
  }) async {
    final bytes = await _buildPdf(txs, accountNames);
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'movimientos_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }

  static Future<Uint8List> _buildPdf(
    List<Transaction> txs,
    Map<String, String> accountNames,
  ) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    final primary = PdfColor.fromHex('2F5BFF');
    final incomeColor = PdfColor.fromHex('059669');
    final expenseColor = PdfColor.fromHex('DC2626');
    final greyMid = PdfColor.fromHex('6B7280');
    final greyLight = PdfColor.fromHex('F3F4F6');
    final borderGrey = PdfColor.fromHex('E5E7EB');

    final totalIncome = txs
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpense = txs
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        ),
        header: (ctx) => ctx.pageNumber == 1
            ? pw.SizedBox()
            : pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text('Histórico de movimientos',
                    style: pw.TextStyle(font: font, fontSize: 9, color: greyMid)),
              ),
        build: (ctx) => [
          // Header
          pw.Container(
            decoration: pw.BoxDecoration(
              color: primary,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Fimakyp',
                        style: pw.TextStyle(
                            font: fontBold, fontSize: 22, color: PdfColors.white)),
                    pw.SizedBox(height: 2),
                    pw.Text('Histórico de movimientos',
                        style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: PdfColor.fromHex('DBEAFE'))),
                  ],
                ),
                pw.Text(DateFormat('dd/MM/yyyy', 'es').format(DateTime.now()),
                    style: pw.TextStyle(
                        font: fontBold, fontSize: 11, color: PdfColors.white)),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          // Totals
          pw.Row(children: [
            _totalChip('Movimientos', '${txs.length}', greyMid, greyLight, font, fontBold),
            pw.SizedBox(width: 8),
            _totalChip('Ingresos', _fmtMoney(totalIncome), incomeColor,
                PdfColor.fromHex('ECFDF5'), font, fontBold),
            pw.SizedBox(width: 8),
            _totalChip('Gastos', _fmtMoney(totalExpense), expenseColor,
                PdfColor.fromHex('FEF2F2'), font, fontBold),
          ]),
          pw.SizedBox(height: 16),
          // Table
          pw.Table(
            border: pw.TableBorder.symmetric(
              inside: pw.BorderSide(color: borderGrey, width: 0.5),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.4),
              1: const pw.FlexColumnWidth(1.6),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(1.8),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: greyLight),
                children: [
                  _th('Fecha', fontBold, greyMid),
                  _th('Categoría', fontBold, greyMid),
                  _th('Descripción', fontBold, greyMid),
                  _th('Cuenta', fontBold, greyMid),
                  _th('Monto', fontBold, greyMid, right: true),
                ],
              ),
              ...txs.map((t) {
                final isExpense = t.type == TransactionType.expense;
                final color = isExpense
                    ? expenseColor
                    : (t.type == TransactionType.income ? incomeColor : primary);
                final sign = isExpense ? '-' : (t.type == TransactionType.income ? '+' : '');
                return pw.TableRow(children: [
                  _td(_dateFmt.format(t.date), font, greyMid),
                  _td(t.category.label, font, PdfColor.fromHex('374151')),
                  _td(t.description.isNotEmpty ? t.description : '—', font,
                      PdfColor.fromHex('374151')),
                  _td(accountNames[t.accountId] ?? '—', font, greyMid),
                  _td('$sign${_fmtMoney(t.amount)}', fontBold, color, right: true),
                ]);
              }),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _totalChip(String label, String value, PdfColor color,
      PdfColor bg, pw.Font font, pw.Font fontBold) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: pw.TextStyle(font: font, fontSize: 8.5, color: color.shade(0.5))),
            pw.SizedBox(height: 3),
            pw.Text(value,
                style: pw.TextStyle(font: fontBold, fontSize: 13, color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _th(String text, pw.Font font, PdfColor color,
      {bool right = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(text,
          textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(font: font, fontSize: 8.5, color: color)),
    );
  }

  static pw.Widget _td(String text, pw.Font font, PdfColor color,
      {bool right = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text,
          textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(font: font, fontSize: 9, color: color)),
    );
  }
}
