import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/report_data.dart';

class ExpenseDonutChart extends StatefulWidget {
  final List<CategoryData> categories;
  final double total;
  final String title;

  const ExpenseDonutChart({
    super.key,
    required this.categories,
    required this.total,
    required this.title,
  });

  @override
  State<ExpenseDonutChart> createState() => _ExpenseDonutChartState();
}

class _ExpenseDonutChartState extends State<ExpenseDonutChart> {
  int _touched = -1;

  static const _colors = AppColors.categoryColors;

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return _buildEmpty();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: AppTextStyles.headlineSmall),
        const SizedBox(height: AppDimensions.md),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      _touched = -1;
                      return;
                    }
                    _touched =
                        response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: _buildSections(),
              centerSpaceRadius: 56,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        _buildLegend(),
      ],
    );
  }

  List<PieChartSectionData> _buildSections() {
    return widget.categories.asMap().entries.map((e) {
      final i = e.key;
      final cat = e.value;
      final isTouched = i == _touched;
      final color = _colors[i % _colors.length];
      return PieChartSectionData(
        color: color,
        value: cat.amount,
        radius: isTouched ? 72 : 60,
        title: cat.percentage > 0.06
            ? '${(cat.percentage * 100).toStringAsFixed(0)}%'
            : '',
        titleStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
        ),
        badgeWidget: isTouched
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cat.category.icon,
                  style: const TextStyle(fontSize: 14),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.1,
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Column(
      children: widget.categories.asMap().entries.map((e) {
        final i = e.key;
        final cat = e.value;
        final color = _colors[i % _colors.length];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppDimensions.sm),
              Text('${cat.category.icon} ${cat.category.label}',
                  style: AppTextStyles.bodySmall),
              const Spacer(),
              Text(
                CurrencyFormatter.format(cat.amount),
                style: AppTextStyles.monoSmall
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: AppDimensions.sm),
              SizedBox(
                width: 36,
                child: Text(
                  '${(cat.percentage * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey400),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmpty() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: AppTextStyles.headlineSmall),
        const SizedBox(height: AppDimensions.xl),
        Center(
          child: Text('Sin datos para este mes',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.grey400)),
        ),
      ],
    );
  }
}
