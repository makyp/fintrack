import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/report_data.dart';

class TrendLineChart extends StatefulWidget {
  final List<MonthlyData> trend;

  const TrendLineChart({super.key, required this.trend});

  @override
  State<TrendLineChart> createState() => _TrendLineChartState();
}

class _TrendLineChartState extends State<TrendLineChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.trend.isEmpty) return const SizedBox.shrink();

    final maxY = widget.trend
        .expand((m) => [m.income, m.expenses])
        .fold(0.0, (prev, v) => v > prev ? v : prev);
    final yInterval = _niceInterval(maxY);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Evolución 6 meses', style: AppTextStyles.headlineSmall),
        const SizedBox(height: AppDimensions.sm),
        Row(
          children: [
            _LegendDot(color: AppColors.income, label: 'Ingresos'),
            const SizedBox(width: AppDimensions.md),
            _LegendDot(color: AppColors.expense, label: 'Gastos'),
            const SizedBox(width: AppDimensions.md),
            _LegendDot(color: AppColors.primary, label: 'Neto'),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY * 1.25,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final labels = ['Ing', 'Gas', 'Neto'];
                      final colors = [
                        AppColors.income,
                        AppColors.expense,
                        AppColors.primary
                      ];
                      return LineTooltipItem(
                        '${labels[spot.barIndex]}: ${CurrencyFormatter.format(spot.y, compact: true)}',
                        AppTextStyles.bodySmall.copyWith(
                          color: colors[spot.barIndex],
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
                touchCallback: (event, response) {
                  setState(() {
                    _touchedIndex = response?.lineBarSpots?.first.x.toInt() ?? -1;
                  });
                },
                handleBuiltInTouches: true,
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= widget.trend.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          widget.trend[i].label,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: i == _touchedIndex
                                ? AppColors.primary
                                : AppColors.grey500,
                            fontSize: 10,
                            fontWeight: i == _touchedIndex
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        CurrencyFormatter.format(value, compact: true),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.grey400, fontSize: 9),
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
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: AppColors.grey100, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                _buildLine(
                  spots: widget.trend.asMap().entries
                      .map((e) =>
                          FlSpot(e.key.toDouble(), e.value.income))
                      .toList(),
                  color: AppColors.income,
                ),
                _buildLine(
                  spots: widget.trend.asMap().entries
                      .map((e) =>
                          FlSpot(e.key.toDouble(), e.value.expenses))
                      .toList(),
                  color: AppColors.expense,
                ),
                _buildLine(
                  spots: widget.trend.asMap().entries
                      .map((e) => FlSpot(
                          e.key.toDouble(),
                          (e.value.net).clamp(0, double.infinity).toDouble()))
                      .toList(),
                  color: AppColors.primary,
                  dashed: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _buildLine({
    required List<FlSpot> spots,
    required Color color,
    bool dashed = false,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: dashed ? 1.5 : 2.5,
      dashArray: dashed ? [5, 4] : null,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) {
          return FlDotCirclePainter(
            radius: index == _touchedIndex ? 5 : 3,
            color: color,
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: dashed
          ? BarAreaData(show: false)
          : BarAreaData(
              show: true,
              color: color.withOpacity(0.07),
            ),
    );
  }

  double _niceInterval(double maxY) {
    if (maxY <= 0) return 1;
    final raw = maxY / 4;
    double magnitude = 1;
    while (magnitude * 10 < raw) magnitude *= 10;
    final normalized = raw / magnitude;
    final nice =
        normalized <= 1 ? 1 : normalized <= 2 ? 2 : normalized <= 5 ? 5 : 10;
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.grey600)),
      ],
    );
  }
}
