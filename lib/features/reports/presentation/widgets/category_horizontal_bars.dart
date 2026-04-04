import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/report_data.dart';

class CategoryHorizontalBars extends StatefulWidget {
  final List<CategoryData> categories;
  final double total;
  final String title;
  final Color barColor;

  const CategoryHorizontalBars({
    super.key,
    required this.categories,
    required this.total,
    required this.title,
    this.barColor = AppColors.primary,
  });

  @override
  State<CategoryHorizontalBars> createState() => _CategoryHorizontalBarsState();
}

class _CategoryHorizontalBarsState extends State<CategoryHorizontalBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _selected = -1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(CategoryHorizontalBars old) {
    super.didUpdateWidget(old);
    if (old.categories != widget.categories) {
      _ctrl.forward(from: 0);
      _selected = -1;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppDimensions.lg),
          Center(
            child: Text('Sin datos para este mes',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.grey400)),
          ),
        ],
      );
    }

    // Show top 6 categories max to keep the UI clean
    final cats = widget.categories.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(widget.title, style: AppTextStyles.headlineSmall)),
            Text(
              CurrencyFormatter.format(widget.total, compact: true),
              style: AppTextStyles.monoSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: widget.barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        // Selected detail chip
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _selected >= 0 && _selected < cats.length
              ? _DetailChip(
                  key: ValueKey(_selected),
                  cat: cats[_selected],
                  color: widget.barColor,
                )
              : const SizedBox(height: 28),
        ),
        const SizedBox(height: AppDimensions.sm),
        AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            return Column(
              children: cats.asMap().entries.map((e) {
                final i = e.key;
                final cat = e.value;
                final isSelected = _selected == i;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selected = isSelected ? -1 : i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: _Bar(
                      cat: cat,
                      progress: cat.percentage * _anim.value,
                      color: widget.barColor,
                      isSelected: isSelected,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final CategoryData cat;
  final double progress;
  final Color color;
  final bool isSelected;

  const _Bar({
    required this.cat,
    required this.progress,
    required this.color,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(cat.category.icon,
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  cat.category.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              Text(
                '${(cat.percentage * 100).toStringAsFixed(1)}%',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? color : AppColors.grey500,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LayoutBuilder(builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 8,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 8,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.7), color],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final CategoryData cat;
  final Color color;

  const _DetailChip({super.key, required this.cat, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${cat.category.icon} ${cat.category.label}: '
        '${CurrencyFormatter.format(cat.amount)}',
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
