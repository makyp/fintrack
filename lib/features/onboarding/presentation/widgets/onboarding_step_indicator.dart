import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class OnboardingStepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const OnboardingStepIndicator({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final stepLabels = ['Efectivo', 'Cuentas', 'Tarjetas'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(total, (i) {
            final isActive = i <= current;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isActive ? AppColors.primary : AppColors.grey200,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Paso ${current + 1} de $total — ${stepLabels[current]}',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
        ),
      ],
    );
  }
}
