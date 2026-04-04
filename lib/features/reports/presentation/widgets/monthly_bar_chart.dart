import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/report_data.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<MonthlyData> trend;

  const MonthlyBarChart({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox.shrink();

    final maxY = trend
        .expand((m) => [m.income, m.expenses])
        .fold(0.0, (prev, v) => v > prev ? v : prev);
    final yInterval = _niceInterval(maxY);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tendencia mensual', style: AppTextStyles.headlineSmall),
        const SizedBox(height: AppDimensions.sm),
        // Legend
        Row(
          children: [
            _LegendDot(color: AppColors.success, label: 'Ingresos'),
            const SizedBox(width: AppDimensions.md),
            _LegendDot(color: AppColors.danger, label: 'Gastos'),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxY * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final m = trend[group.x.toInt()];
                    final isIncome = rodIndex == 0;
                    return BarTooltipItem(
                      '${isIncome ? 'Ing' : 'Gas'}: ${CurrencyFormatter.format(rod.toY, compact: true)}',
                      AppTextStyles.bodySmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= trend.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          trend[i].label,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.grey500, fontSize: 10),
                        ),
                      );
                    },
                    reservedSize: 24,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        CurrencyFormatter.format(value, compact: true),
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey400, fontSize: 9),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.grey100,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: trend.asMap().entries.map((e) {
                final i = e.key;
                final m = e.value;
                return BarChartGroupData(
                  x: i,
                  groupVertically: false,
                  barRods: [
                    BarChartRodData(
                      toY: m.income,
                      color: AppColors.success,
                      width: 10,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                    BarChartRodData(
                      toY: m.expenses,
                      color: AppColors.danger,
                      width: 10,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ],
                  barsSpace: 3,
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  double _niceInterval(double maxY) {
    if (maxY <= 0) return 1;
    final raw = maxY / 4;
    double magnitude = 1;
    while (magnitude * 10 < raw) magnitude *= 10;
    final normalized = raw / magnitude;
    final nice = normalized <= 1 ? 1 : normalized <= 2 ? 2 : normalized <= 5 ? 5 : 10;
    return nice * magnitude;
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
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.grey600)),
      ],
    );
  }
}
