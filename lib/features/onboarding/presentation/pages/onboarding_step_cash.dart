import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';

class OnboardingStepCash extends StatefulWidget {
  final void Function(double) onBalanceChanged;

  const OnboardingStepCash({super.key, required this.onBalanceChanged});

  @override
  State<OnboardingStepCash> createState() => _OnboardingStepCashState();
}

class _OnboardingStepCashState extends State<OnboardingStepCash> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.lg),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cashColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.payments_outlined,
              size: 56,
              color: AppColors.cashColor,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          Text('¿Cuánto efectivo tienes?', style: AppTextStyles.displaySmall),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Registra el dinero en efectivo que tienes ahora mismo. Esto nos ayuda a calcular tu patrimonio total.',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: AppDimensions.xl),
          TextFormField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            style: AppTextStyles.displaySmall.copyWith(color: AppColors.grey900),
            onChanged: (v) {
              final amount = double.tryParse(v) ?? 0;
              widget.onBalanceChanged(amount);
            },
            decoration: InputDecoration(
              labelText: 'Saldo en efectivo',
              hintText: '0',
              prefixText: '\$ ',
              prefixStyle: AppTextStyles.displaySmall.copyWith(
                color: AppColors.cashColor,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.grey500, size: 18),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    'Si no tienes efectivo, simplemente deja el campo en 0.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
