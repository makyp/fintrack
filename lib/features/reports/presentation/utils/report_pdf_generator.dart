import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/models/report_data.dart';

class ReportPdfGenerator {
  static const _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  static String _fmt(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '\$ $s';
  }

  static Future<void> shareReport(ReportData data) async {
    final bytes = await _buildPdf(data);
    final month = _months[data.month - 1];
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'reporte_${month.toLowerCase()}_${data.year}.pdf',
    );
  }

  static Future<Uint8List> _buildPdf(ReportData data) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final month = _months[data.month - 1];

    final primaryColor = PdfColor.fromHex('2563EB');
    final incomeColor = PdfColor.fromHex('10B981');
    final expenseColor = PdfColor.fromHex('EF4444');
    final greyColor = PdfColor.fromHex('6B7280');
    final lightGrey = PdfColor.fromHex('F3F4F6');

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        ),
        build: (ctx) => [
          // ── Header ─────────────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('FinTrack',
                        style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 22,
                            color: PdfColors.white)),
                    pw.Text('Reporte Financiero',
                        style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColor.fromHex('FFFFFFB2'))),
                  ],
                ),
                pw.Text('$month ${data.year}',
                    style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 16,
                        color: PdfColors.white)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── Summary cards ────────────────────────────────────────────────
          pw.Row(
            children: [
              _summaryCard('Ingresos', data.totalIncome, incomeColor, font, fontBold),
              pw.SizedBox(width: 8),
              _summaryCard('Gastos', data.totalExpenses, expenseColor, font, fontBold),
              pw.SizedBox(width: 8),
              _summaryCard('Balance', data.netBalance,
                  data.netBalance >= 0 ? incomeColor : expenseColor, font, fontBold),
            ],
          ),
          pw.SizedBox(height: 20),

          // ── Insights ─────────────────────────────────────────────────────
          if (data.expensesByCategory.isNotEmpty) ...[
            _sectionTitle('Análisis del mes', primaryColor, fontBold),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightGrey,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _insightRow(
                    '💰',
                    'Gasto más alto',
                    '${data.topExpense!.category.label}: ${_fmt(data.topExpense!.amount)}',
                    font,
                  ),
                  if (data.totalIncome > 0) ...[
                    pw.SizedBox(height: 6),
                    _insightRow(
                      '📊',
                      'Tasa de ahorro',
                      '${((data.netBalance / data.totalIncome) * 100).toStringAsFixed(1)}% de tus ingresos',
                      font,
                    ),
                  ],
                  if (data.daily.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    _insightRow(
                      '📅',
                      'Días con actividad',
                      '${data.daily.where((d) => d.income > 0 || d.expenses > 0).length} días este mes',
                      font,
                    ),
                  ],
                  if (data.totalExpenses > 0 && data.daily.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    _insightRow(
                      '📉',
                      'Gasto promedio diario',
                      _fmt(data.totalExpenses /
                          data.daily.where((d) => d.expenses > 0).length.clamp(1, 31)),
                      font,
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          // ── Expenses by category ─────────────────────────────────────────
          if (data.expensesByCategory.isNotEmpty) ...[
            _sectionTitle('Gastos por categoría', primaryColor, fontBold),
            pw.SizedBox(height: 8),
            ...data.expensesByCategory.map((cat) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: _categoryBar(cat.category.label, cat.amount,
                      cat.percentage, expenseColor, greyColor, font, fontBold),
                )),
            pw.SizedBox(height: 20),
          ],

          // ── Income by category ───────────────────────────────────────────
          if (data.incomeByCategory.isNotEmpty) ...[
            _sectionTitle('Ingresos por categoría', primaryColor, fontBold),
            pw.SizedBox(height: 8),
            ...data.incomeByCategory.map((cat) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: _categoryBar(cat.category.label, cat.amount,
                      cat.percentage, incomeColor, greyColor, font, fontBold),
                )),
            pw.SizedBox(height: 20),
          ],

          // ── Daily activity ───────────────────────────────────────────────
          if (data.daily.isNotEmpty) ...[
            _sectionTitle('Actividad diaria', primaryColor, fontBold),
            pw.SizedBox(height: 8),
            _dailyBarChart(data.daily, incomeColor, expenseColor, greyColor, font),
          ],
        ],
      ),
    );

    return doc.save();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static pw.Widget _sectionTitle(
      String title, PdfColor color, pw.Font fontBold) {
    return pw.Row(
      children: [
        pw.Container(width: 3, height: 16, color: color),
        pw.SizedBox(width: 8),
        pw.Text(title,
            style: pw.TextStyle(font: fontBold, fontSize: 13, color: color)),
      ],
    );
  }

  static pw.Widget _summaryCard(String label, double value, PdfColor color,
      pw.Font font, pw.Font fontBold) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColor.fromHex('6B7280'))),
            pw.SizedBox(height: 4),
            pw.Text(_fmt(value),
                style: pw.TextStyle(
                    font: fontBold, fontSize: 13, color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _insightRow(
      String emoji, String label, String value, pw.Font font) {
    return pw.Row(
      children: [
        pw.Text(emoji, style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(width: 6),
        pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                  text: '$label: ',
                  style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColor.fromHex('374151'))),
              pw.TextSpan(
                  text: value,
                  style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColor.fromHex('111827'))),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _categoryBar(
      String label, double amount, double pct, PdfColor barColor,
      PdfColor greyColor, pw.Font font, pw.Font fontBold) {
    const maxWidth = 300.0;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(font: font, fontSize: 10)),
            pw.Row(children: [
              pw.Text(_fmt(amount),
                  style: pw.TextStyle(font: fontBold, fontSize: 10)),
              pw.SizedBox(width: 4),
              pw.Text('(${pct.toStringAsFixed(1)}%)',
                  style: pw.TextStyle(
                      font: font, fontSize: 9, color: greyColor)),
            ]),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Stack(children: [
          pw.Container(
              height: 6,
              width: maxWidth,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('E5E7EB'),
                borderRadius: pw.BorderRadius.circular(3),
              )),
          pw.Container(
              height: 6,
              width: (pct / 100) * maxWidth,
              decoration: pw.BoxDecoration(
                color: barColor,
                borderRadius: pw.BorderRadius.circular(3),
              )),
        ]),
      ],
    );
  }

  static pw.Widget _dailyBarChart(List<DailyData> daily,
      PdfColor incomeColor, PdfColor expenseColor,
      PdfColor greyColor, pw.Font font) {
    final active = daily.where((d) => d.income > 0 || d.expenses > 0).toList();
    if (active.isEmpty) return pw.SizedBox();

    final maxVal = active
        .map((d) => d.income > d.expenses ? d.income : d.expenses)
        .reduce((a, b) => a > b ? a : b);
    const chartH = 60.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Legend
        pw.Row(children: [
          pw.Container(width: 10, height: 10, color: incomeColor),
          pw.SizedBox(width: 4),
          pw.Text('Ingresos',
              style: pw.TextStyle(font: font, fontSize: 9, color: greyColor)),
          pw.SizedBox(width: 12),
          pw.Container(width: 10, height: 10, color: expenseColor),
          pw.SizedBox(width: 4),
          pw.Text('Gastos',
              style: pw.TextStyle(font: font, fontSize: 9, color: greyColor)),
        ]),
        pw.SizedBox(height: 6),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: active.map((d) {
            final incH = maxVal > 0 ? (d.income / maxVal) * chartH : 0.0;
            final expH = maxVal > 0 ? (d.expenses / maxVal) * chartH : 0.0;
            return pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (incH > 0)
                        pw.Container(
                            width: 4,
                            height: incH,
                            color: incomeColor),
                      pw.SizedBox(width: 1),
                      if (expH > 0)
                        pw.Container(
                            width: 4,
                            height: expH,
                            color: expenseColor),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text('${d.day}',
                      style: pw.TextStyle(
                          font: font, fontSize: 7, color: greyColor)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
