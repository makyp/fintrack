import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/report_data.dart';

class DailyBarChart extends StatefulWidget {
  final List<DailyData> data;

  const DailyBarChart({super.key, required this.data});

  @override
  State<DailyBarChart> createState() => _DailyBarChartState();
}

class _DailyBarChartState extends State<DailyBarChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final active = widget.data
        .where((d) => d.income > 0 || d.expenses > 0)
        .toList();

    if (active.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: Text('Sin datos este mes',
              style: TextStyle(color: AppColors.grey400)),
        ),
      );
    }

    final maxVal = active
        .map((d) => d.income > d.expenses ? d.income : d.expenses)
        .reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal > 0 ? maxVal * 1.2 : 1000.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Row(
          children: [
            _LegendDot(color: AppColors.income, label: 'Ingresos'),
            const SizedBox(width: 16),
            _LegendDot(color: AppColors.expense, label: 'Gastos'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: safeMax,
              minY: 0,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.grey800,
                  tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  getTooltipItem: (group, _, rod, rodIndex) {
                    final d = active[group.x];
                    final label = rodIndex == 0 ? 'Ing' : 'Gas';
                    final amount = rodIndex == 0 ? d.income : d.expenses;
                    return BarTooltipItem(
                      'Día ${d.day}\n$label: ${CurrencyFormatter.format(amount, compact: true)}',
                      AppTextStyles.bodySmall.copyWith(
                          color: Colors.white, fontSize: 11),
                    );
                  },
                ),
                touchCallback: (event, response) {
                  setState(() {
                    if (response?.spot != null &&
                        event is! FlTapUpEvent &&
                        event is! FlPanEndEvent) {
                      _touchedIndex = response!.spot!.touchedBarGroupIndex;
                    } else {
                      _touchedIndex = null;
                    }
                  });
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    interval: safeMax / 4,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        CurrencyFormatter.format(value, compact: true),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 9,
                          color: AppColors.grey400,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= active.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        '${active[idx].day}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 10,
                          color: AppColors.grey400,
                        ),
                      );
                    },
                    reservedSize: 20,
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: safeMax / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.grey300,
                  strokeWidth: 0.8,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(active.length, (i) {
                final d = active[i];
                final isTouched = _touchedIndex == i;
                return BarChartGroupData(
                  x: i,
                  groupVertically: false,
                  barRods: [
                    BarChartRodData(
                      toY: d.income,
                      color: AppColors.income
                          .withOpacity(isTouched ? 1.0 : 0.85),
                      width: _barWidth(widget.data.length),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3)),
                    ),
                    BarChartRodData(
                      toY: d.expenses,
                      color: AppColors.expense
                          .withOpacity(isTouched ? 1.0 : 0.85),
                      width: _barWidth(widget.data.length),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3)),
                    ),
                  ],
                  barsSpace: 1,
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  double _barWidth(int count) {
    if (count <= 15) return 7;
    if (count <= 20) return 5;
    return 3.5;
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.grey500, fontSize: 11)),
      ],
    );
  }
}
