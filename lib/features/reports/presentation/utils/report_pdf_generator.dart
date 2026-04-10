import 'dart:math' as math;
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/models/report_data.dart';

class ReportPdfGenerator {
  static const _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  // Pie/donut chart colors
  static const _pieArgb = [
    0xFF3B82F6,
    0xFF10B981,
    0xFFEF4444,
    0xFFF59E0B,
    0xFF8B5CF6,
    0xFF06B6D4,
    0xFFEC4899,
    0xFF6B7280,
  ];

  static PdfColor _pieColor(int index) {
    final argb = _pieArgb[index % _pieArgb.length];
    final r = ((argb >> 16) & 0xFF) / 255.0;
    final g = ((argb >> 8) & 0xFF) / 255.0;
    final b = (argb & 0xFF) / 255.0;
    return PdfColor(r, g, b);
  }

  static String _fmt(double v) {
    final abs = v.abs();
    final s = abs.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return v < 0 ? '-\$ $s' : '\$ $s';
  }

  static String _fmtPct(double v) => '${v.toStringAsFixed(1)}%';

  // ── Public entry point ────────────────────────────────────────────────────

  static Future<void> shareReport(ReportData data) async {
    final bytes = await _buildPdf(data);
    final month = _months[data.month - 1];
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'reporte_${month.toLowerCase()}_${data.year}.pdf',
    );
  }

  // ── PDF construction ──────────────────────────────────────────────────────

  static Future<Uint8List> _buildPdf(ReportData data) async {
    final doc = pw.Document();

    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final fontItalic = await PdfGoogleFonts.nunitoItalic();

    final month = _months[data.month - 1];

    // Palette
    final primary = PdfColor.fromHex('2563EB');
    final primaryLight = PdfColor.fromHex('DBEAFE');
    final incomeColor = PdfColor.fromHex('10B981');
    final expenseColor = PdfColor.fromHex('EF4444');
    final balanceColor =
        data.netBalance >= 0 ? incomeColor : expenseColor;
    final greyDark = PdfColor.fromHex('1F2937');
    final greyMid = PdfColor.fromHex('6B7280');
    final greyLight = PdfColor.fromHex('F3F4F6');
    final borderGrey = PdfColor.fromHex('E5E7EB');
    const white = PdfColors.white;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        ),
        build: (ctx) => [
          // ── 1. HEADER ────────────────────────────────────────────────────
          _buildHeader(month, data.year, primary, primaryLight, fontBold, font, white),
          pw.SizedBox(height: 18),

          // ── 2. SUMMARY CARDS ─────────────────────────────────────────────
          _buildSummaryCards(data, incomeColor, expenseColor, balanceColor,
              greyMid, font, fontBold),
          pw.SizedBox(height: 22),

          // ── 3. NARRATIVE ─────────────────────────────────────────────────
          _buildNarrative(data, primary, primaryLight, incomeColor,
              expenseColor, greyDark, greyMid, borderGrey, font, fontBold, fontItalic),
          pw.SizedBox(height: 22),

          // ── 4. DONUT PIE CHART (expenses) ────────────────────────────────
          if (data.expensesByCategory.isNotEmpty) ...[
            _sectionTitle('Distribución de gastos', primary, fontBold),
            pw.SizedBox(height: 10),
            _buildDonutSection(data.expensesByCategory, greyMid, greyLight,
                borderGrey, font, fontBold),
            pw.SizedBox(height: 22),
          ],

          // ── 5. INCOME BAR CHART ──────────────────────────────────────────
          if (data.incomeByCategory.isNotEmpty) ...[
            _sectionTitle('Ingresos por categoría', primary, fontBold),
            pw.SizedBox(height: 10),
            _buildCategoryBars(data.incomeByCategory, incomeColor, greyMid,
                greyLight, font, fontBold),
            pw.SizedBox(height: 22),
          ],

          // ── 6. DAILY ACTIVITY BAR CHART ──────────────────────────────────
          if (data.daily.isNotEmpty) ...[
            _sectionTitle('Actividad diaria', primary, fontBold),
            pw.SizedBox(height: 10),
            _buildDailyChart(data.daily, incomeColor, expenseColor, greyMid,
                greyLight, borderGrey, font),
            pw.SizedBox(height: 22),
          ],

          // ── 7. INSIGHTS ──────────────────────────────────────────────────
          _buildInsights(data, primary, primaryLight, incomeColor, expenseColor,
              greyDark, greyMid, greyLight, borderGrey, font, fontBold),
        ],
      ),
    );

    return doc.save();
  }

  // ── SECTION: HEADER ───────────────────────────────────────────────────────

  static pw.Widget _buildHeader(
    String month,
    int year,
    PdfColor primary,
    PdfColor primaryLight,
    pw.Font fontBold,
    pw.Font font,
    PdfColor white,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [primary, PdfColor.fromHex('1D4ED8')],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
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
              pw.Text(
                'Fimakyp',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 24,
                  color: white,
                  letterSpacing: 0.5,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Reporte Financiero',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 11,
                  color: PdfColor.fromHex('BFDBFE'),
                ),
              ),
            ],
          ),
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: pw.BoxDecoration(
              color: const PdfColor(1, 1, 1, 0.18),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              '$month $year',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 15,
                color: white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SECTION: SUMMARY CARDS ────────────────────────────────────────────────

  static pw.Widget _buildSummaryCards(
    ReportData data,
    PdfColor incomeColor,
    PdfColor expenseColor,
    PdfColor balanceColor,
    PdfColor greyMid,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Row(
      children: [
        _summaryCard(
          label: 'Ingresos',
          value: data.totalIncome,
          color: incomeColor,
          bgHex: 'ECFDF5',
          font: font,
          fontBold: fontBold,
        ),
        pw.SizedBox(width: 10),
        _summaryCard(
          label: 'Gastos',
          value: data.totalExpenses,
          color: expenseColor,
          bgHex: 'FEF2F2',
          font: font,
          fontBold: fontBold,
        ),
        pw.SizedBox(width: 10),
        _summaryCard(
          label: 'Balance',
          value: data.netBalance,
          color: balanceColor,
          bgHex: data.netBalance >= 0 ? 'ECFDF5' : 'FEF2F2',
          font: font,
          fontBold: fontBold,
        ),
      ],
    );
  }

  static pw.Widget _summaryCard({
    required String label,
    required double value,
    required PdfColor color,
    required String bgHex,
    required pw.Font font,
    required pw.Font fontBold,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding:
            const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex(bgHex),
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: color.shade(0.3), width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 28,
              height: 3,
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: pw.BorderRadius.circular(2),
              ),
            ),
            pw.SizedBox(height: 7),
            pw.Text(
              label,
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
                color: color.shade(0.6),
                letterSpacing: 0.8,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              _fmt(value),
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SECTION: NARRATIVE ────────────────────────────────────────────────────

  static pw.Widget _buildNarrative(
    ReportData data,
    PdfColor primary,
    PdfColor primaryLight,
    PdfColor incomeColor,
    PdfColor expenseColor,
    PdfColor greyDark,
    PdfColor greyMid,
    PdfColor borderGrey,
    pw.Font font,
    pw.Font fontBold,
    pw.Font fontItalic,
  ) {
    final savingsColor =
        data.netBalance >= 0 ? incomeColor : expenseColor;
    final savingsLabel =
        data.netBalance >= 0 ? 'ahorro' : 'déficit';

    final lines = <pw.Widget>[];

    // Line 1 – income
    lines.add(_narrativeLine(
      prefix: 'Este mes te ingresaron ',
      highlight: _fmt(data.totalIncome),
      suffix: '.',
      highlightColor: incomeColor,
      greyDark: greyDark,
      font: font,
      fontBold: fontBold,
    ));

    // Line 2 – expenses
    if (data.totalExpenses > 0) {
      final nCats = data.expensesByCategory.length;
      lines.add(pw.SizedBox(height: 6));
      lines.add(_narrativeLine(
        prefix: 'Gastaste ',
        highlight: _fmt(data.totalExpenses),
        suffix:
            ' en $nCats ${nCats == 1 ? 'categoría' : 'categorías'}.',
        highlightColor: expenseColor,
        greyDark: greyDark,
        font: font,
        fontBold: fontBold,
      ));
    }

    // Line 3 – savings/deficit
    lines.add(pw.SizedBox(height: 6));
    lines.add(_narrativeLine(
      prefix: 'Tienes un $savingsLabel de ',
      highlight: _fmt(data.netBalance.abs()),
      suffix: '.',
      highlightColor: savingsColor,
      greyDark: greyDark,
      font: font,
      fontBold: fontBold,
    ));

    // Line 4 – savings rate
    if (data.totalIncome > 0) {
      final rate = (data.netBalance / data.totalIncome) * 100;
      lines.add(pw.SizedBox(height: 6));
      lines.add(_narrativeLine(
        prefix: 'Tu tasa de ahorro es del ',
        highlight: _fmtPct(rate),
        suffix: ' de tus ingresos.',
        highlightColor: savingsColor,
        greyDark: greyDark,
        font: font,
        fontBold: fontBold,
      ));
    }

    // Line 5 – top expense
    if (data.topExpense != null) {
      lines.add(pw.SizedBox(height: 6));
      lines.add(_narrativeLine(
        prefix: 'Tu mayor gasto fue en ',
        highlight: data.topExpense!.category.label,
        suffix: ': ${_fmt(data.topExpense!.amount)}.',
        highlightColor: expenseColor,
        greyDark: greyDark,
        font: font,
        fontBold: fontBold,
      ));
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: primaryLight,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: primary.shade(0.25), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(children: [
            pw.Container(
              width: 4,
              height: 4,
              decoration: pw.BoxDecoration(
                color: primary,
                borderRadius: pw.BorderRadius.circular(2),
              ),
            ),
            pw.SizedBox(width: 6),
            pw.Text(
              'Resumen del mes',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 11,
                color: primary,
              ),
            ),
          ]),
          pw.SizedBox(height: 10),
          ...lines,
        ],
      ),
    );
  }

  static pw.Widget _narrativeLine({
    required String prefix,
    required String highlight,
    required String suffix,
    required PdfColor highlightColor,
    required PdfColor greyDark,
    required pw.Font font,
    required pw.Font fontBold,
  }) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: prefix,
            style: pw.TextStyle(font: font, fontSize: 10.5, color: greyDark),
          ),
          pw.TextSpan(
            text: highlight,
            style: pw.TextStyle(
                font: fontBold, fontSize: 10.5, color: highlightColor),
          ),
          pw.TextSpan(
            text: suffix,
            style: pw.TextStyle(font: font, fontSize: 10.5, color: greyDark),
          ),
        ],
      ),
    );
  }

  // ── SECTION: DONUT PIE CHART ──────────────────────────────────────────────

  static pw.Widget _buildDonutSection(
    List<CategoryData> categories,
    PdfColor greyMid,
    PdfColor greyLight,
    PdfColor borderGrey,
    pw.Font font,
    pw.Font fontBold,
  ) {
    const chartSize = 130.0;
    const legendRowH = 16.0;

    // Trim to top 8 for readability
    final cats =
        categories.length > 8 ? categories.sublist(0, 8) : categories;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Donut
        pw.SizedBox(
          width: chartSize,
          height: chartSize,
          child: pw.CustomPaint(
            painter: (PdfGraphics canvas, PdfPoint size) {
              _drawDonut(canvas, size, cats);
            },
          ),
        ),
        pw.SizedBox(width: 16),
        // Legend
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: List.generate(cats.length, (i) {
              final cat = cats[i];
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: legendRowH * 0.55,
                      height: legendRowH * 0.55,
                      decoration: pw.BoxDecoration(
                        color: _pieColor(i),
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                    ),
                    pw.SizedBox(width: 5),
                    pw.Expanded(
                      child: pw.Text(
                        cat.category.label,
                        style: pw.TextStyle(
                            font: font, fontSize: 9, color: greyMid),
                        maxLines: 1,
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      _fmtPct(cat.percentage),
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 9,
                          color: PdfColor.fromHex('374151')),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Draws a donut chart using low-level PdfGraphics.
  /// PDF coordinate origin is bottom-left; y increases upward.
  static void _drawDonut(
      PdfGraphics canvas, PdfPoint size, List<CategoryData> cats) {
    const steps = 120; // line segments per full circle
    final cx = size.x / 2;
    final cy = size.y / 2;
    final outerR = (size.x < size.y ? size.x : size.y) / 2 - 4;
    final innerR = outerR * 0.55;

    // Calculate total for normalization (use percentages as weights)
    double totalPct = cats.fold(0.0, (sum, c) => sum + c.percentage);
    if (totalPct <= 0) totalPct = 1;

    // Draw each slice
    double startAngle = -math.pi / 2; // start at top

    for (int i = 0; i < cats.length; i++) {
      final sweepAngle =
          (cats[i].percentage / totalPct) * 2 * math.pi;

      if (sweepAngle < 0.001) {
        startAngle += sweepAngle;
        continue;
      }

      canvas.setFillColor(_pieColor(i));

      // Move to center
      canvas.moveTo(cx, cy);

      // Draw arc with line segments
      final segCount =
          ((sweepAngle / (2 * math.pi)) * steps).ceil().clamp(2, steps);
      for (int s = 0; s <= segCount; s++) {
        final angle = startAngle + (sweepAngle * s / segCount);
        final x = cx + outerR * math.cos(angle);
        final y = cy + outerR * math.sin(angle);
        canvas.lineTo(x, y);
      }

      canvas.closePath();
      canvas.fillPath();

      startAngle += sweepAngle;
    }

    // Draw white inner circle to create donut effect
    canvas.setFillColor(PdfColors.white);
    canvas.drawEllipse(cx, cy, innerR, innerR);
    canvas.fillPath();
  }

  // ── SECTION: CATEGORY BARS ────────────────────────────────────────────────

  static pw.Widget _buildCategoryBars(
    List<CategoryData> categories,
    PdfColor barColor,
    PdfColor greyMid,
    PdfColor greyLight,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Column(
      children: categories.map((cat) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: _categoryBarRow(
            cat.category.label,
            cat.amount,
            cat.percentage,
            barColor,
            greyMid,
            font,
            fontBold,
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _categoryBarRow(
    String label,
    double amount,
    double pct,
    PdfColor barColor,
    PdfColor greyMid,
    pw.Font font,
    pw.Font fontBold,
  ) {
    const trackH = 7.0;
    const trackW = 280.0;
    final fillW = (pct.clamp(0, 100) / 100) * trackW;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColor.fromHex('374151'))),
            pw.Row(children: [
              pw.Text(_fmt(amount),
                  style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 10,
                      color: PdfColor.fromHex('111827'))),
              pw.SizedBox(width: 5),
              pw.Text('(${_fmtPct(pct)})',
                  style:
                      pw.TextStyle(font: font, fontSize: 9, color: greyMid)),
            ]),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Stack(children: [
          pw.Container(
            height: trackH,
            width: trackW,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('E5E7EB'),
              borderRadius: pw.BorderRadius.circular(trackH / 2),
            ),
          ),
          if (fillW > 0)
            pw.Container(
              height: trackH,
              width: fillW,
              decoration: pw.BoxDecoration(
                color: barColor,
                borderRadius: pw.BorderRadius.circular(trackH / 2),
              ),
            ),
        ]),
      ],
    );
  }

  // ── SECTION: DAILY CHART ──────────────────────────────────────────────────

  static pw.Widget _buildDailyChart(
    List<DailyData> daily,
    PdfColor incomeColor,
    PdfColor expenseColor,
    PdfColor greyMid,
    PdfColor greyLight,
    PdfColor borderGrey,
    pw.Font font,
  ) {
    final active =
        daily.where((d) => d.income > 0 || d.expenses > 0).toList();
    if (active.isEmpty) return pw.SizedBox();

    final maxVal = active
        .map((d) => d.income > d.expenses ? d.income : d.expenses)
        .reduce((a, b) => a > b ? a : b);

    const chartH = 70.0;
    const barW = 5.0;
    const gap = 1.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Legend
        pw.Row(children: [
          pw.Container(
              width: 10,
              height: 10,
              decoration: pw.BoxDecoration(
                color: incomeColor,
                borderRadius: pw.BorderRadius.circular(2),
              )),
          pw.SizedBox(width: 4),
          pw.Text('Ingresos',
              style: pw.TextStyle(font: font, fontSize: 8.5, color: greyMid)),
          pw.SizedBox(width: 12),
          pw.Container(
              width: 10,
              height: 10,
              decoration: pw.BoxDecoration(
                color: expenseColor,
                borderRadius: pw.BorderRadius.circular(2),
              )),
          pw.SizedBox(width: 4),
          pw.Text('Gastos',
              style: pw.TextStyle(font: font, fontSize: 8.5, color: greyMid)),
        ]),
        pw.SizedBox(height: 8),
        // Chart rows
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: active.map((d) {
            final incH =
                maxVal > 0 ? (d.income / maxVal) * chartH : 0.0;
            final expH =
                maxVal > 0 ? (d.expenses / maxVal) * chartH : 0.0;
            return pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: gap / 2),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (incH > 0)
                        pw.Container(
                          width: barW,
                          height: incH,
                          decoration: pw.BoxDecoration(
                            color: incomeColor,
                            borderRadius: const pw.BorderRadius.only(
                              topLeft: pw.Radius.circular(2),
                              topRight: pw.Radius.circular(2),
                            ),
                          ),
                        ),
                      pw.SizedBox(width: gap),
                      if (expH > 0)
                        pw.Container(
                          width: barW,
                          height: expH,
                          decoration: pw.BoxDecoration(
                            color: expenseColor,
                            borderRadius: const pw.BorderRadius.only(
                              topLeft: pw.Radius.circular(2),
                              topRight: pw.Radius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    '${d.day}',
                    style: pw.TextStyle(
                        font: font, fontSize: 6.5, color: greyMid),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── SECTION: INSIGHTS ────────────────────────────────────────────────────

  static pw.Widget _buildInsights(
    ReportData data,
    PdfColor primary,
    PdfColor primaryLight,
    PdfColor incomeColor,
    PdfColor expenseColor,
    PdfColor greyDark,
    PdfColor greyMid,
    PdfColor greyLight,
    PdfColor borderGrey,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final items = <_InsightItem>[];

    // Top expense
    if (data.topExpense != null) {
      items.add(_InsightItem(
        dot: expenseColor,
        label: 'Mayor gasto',
        value:
            '${data.topExpense!.category.label} — ${_fmt(data.topExpense!.amount)}',
      ));
    }

    // Savings rate
    if (data.totalIncome > 0) {
      final rate = (data.netBalance / data.totalIncome) * 100;
      items.add(_InsightItem(
        dot: rate >= 0 ? incomeColor : expenseColor,
        label: 'Tasa de ahorro',
        value: _fmtPct(rate),
      ));
    }

    // Active days
    final activeDays =
        data.daily.where((d) => d.income > 0 || d.expenses > 0).length;
    if (activeDays > 0) {
      items.add(_InsightItem(
        dot: primary,
        label: 'Días con actividad',
        value: '$activeDays días',
      ));
    }

    // Avg daily expense
    final expDays =
        data.daily.where((d) => d.expenses > 0).length;
    if (expDays > 0) {
      items.add(_InsightItem(
        dot: expenseColor,
        label: 'Gasto promedio diario',
        value: _fmt(data.totalExpenses / expDays),
      ));
    }

    // Number of income categories
    if (data.incomeByCategory.isNotEmpty) {
      items.add(_InsightItem(
        dot: incomeColor,
        label: 'Fuentes de ingreso',
        value:
            '${data.incomeByCategory.length} ${data.incomeByCategory.length == 1 ? 'categoría' : 'categorías'}',
      ));
    }

    if (items.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Perspectivas', primary, fontBold),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: greyLight,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: borderGrey, width: 1),
          ),
          child: pw.Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              return pw.Padding(
                padding: pw.EdgeInsets.only(bottom: i < items.length - 1 ? 10 : 0),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 8,
                      height: 8,
                      decoration: pw.BoxDecoration(
                        color: item.dot,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(
                        item.label,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          color: greyMid,
                        ),
                      ),
                    ),
                    pw.Text(
                      item.value,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10,
                        color: greyDark,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ── SHARED HELPERS ────────────────────────────────────────────────────────

  static pw.Widget _sectionTitle(
      String title, PdfColor color, pw.Font fontBold) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 4,
          height: 16,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _InsightItem {
  final PdfColor dot;
  final String label;
  final String value;

  const _InsightItem({
    required this.dot,
    required this.label,
    required this.value,
  });
}
