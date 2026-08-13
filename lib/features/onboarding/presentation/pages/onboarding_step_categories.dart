import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../categories/domain/entities/transaction_category.dart';
import '../../../categories/presentation/widgets/category_form_sheet.dart';
import '../../../transactions/domain/entities/transaction_type.dart';

/// Onboarding step where the user picks which of the shipped categories they
/// want, and adds their own.
///
/// Both collections are owned by [OnboardingPage] and mutated in place, the
/// same way the accounts and cards steps work.
class OnboardingStepCategories extends StatefulWidget {
  final Set<String> selectedIds;
  final List<TransactionCategory> customCategories;

  const OnboardingStepCategories({
    super.key,
    required this.selectedIds,
    required this.customCategories,
  });

  @override
  State<OnboardingStepCategories> createState() =>
      _OnboardingStepCategoriesState();
}

class _OnboardingStepCategoriesState extends State<OnboardingStepCategories> {
  List<TransactionCategory> get _defaults =>
      DefaultCategories.all.where((c) => !c.isProtected).toList();

  Future<void> _addCustom() async {
    final draft = await CategoryFormSheet.show(context);
    if (draft == null) return;
    setState(() => widget.customCategories.add(draft));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final expenses =
        _defaults.where((c) => c.appliesTo(TransactionType.expense)).toList();
    final incomes =
        _defaults.where((c) => c.appliesTo(TransactionType.income)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.lg),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.sell_outlined, size: 56, color: primary),
          ),
          const SizedBox(height: AppDimensions.lg),
          Text('¿Qué categorías usas?', style: AppTextStyles.displaySmall),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Deja marcadas las que te sirvan y agrega las tuyas. Puedes '
            'cambiarlas cuando quieras desde tu perfil.',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: AppDimensions.xl),

          _group('Gastos', expenses, primary),
          const SizedBox(height: AppDimensions.lg),
          _group('Ingresos', incomes, primary),

          if (widget.customCategories.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.lg),
            Text('LAS TUYAS',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.grey500, letterSpacing: 0.8)),
            const SizedBox(height: AppDimensions.sm),
            Wrap(
              spacing: AppDimensions.sm,
              runSpacing: AppDimensions.sm,
              children: [
                for (var i = 0; i < widget.customCategories.length; i++)
                  _customChip(widget.customCategories[i], i, primary),
              ],
            ),
          ],

          const SizedBox(height: AppDimensions.lg),
          OutlinedButton.icon(
            onPressed: _addCustom,
            icon: const Icon(Icons.add),
            label: const Text('Agregar una categoría mía'),
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
                const Icon(Icons.info_outline,
                    color: AppColors.grey500, size: 18),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    'Las que dejes sin marcar quedan ocultas, no se borran: si '
                    'cambias de idea las vuelves a activar desde tu perfil.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(
      String title, List<TransactionCategory> categories, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.grey500, letterSpacing: 0.8)),
        const SizedBox(height: AppDimensions.sm),
        Wrap(
          spacing: AppDimensions.sm,
          runSpacing: AppDimensions.sm,
          children: categories.map((c) => _chip(c, primary)).toList(),
        ),
      ],
    );
  }

  Widget _chip(TransactionCategory category, Color primary) {
    final selected = widget.selectedIds.contains(category.id);
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          widget.selectedIds.remove(category.id);
        } else {
          widget.selectedIds.add(category.id);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primary.withOpacity(0.10) : AppColors.grey100,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: selected ? primary : AppColors.grey200,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 7),
            Text(
              category.label,
              style: AppTextStyles.labelMedium.copyWith(
                  color: selected ? primary : AppColors.grey600),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle, size: 15, color: primary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _customChip(TransactionCategory category, int index, Color primary) {
    return Container(
      padding: const EdgeInsets.only(
          left: AppDimensions.md, top: 6, bottom: 6, right: 6),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: primary, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 7),
          Text(category.label,
              style: AppTextStyles.labelMedium.copyWith(color: primary)),
          IconButton(
            icon: const Icon(Icons.close, size: 15),
            color: primary,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
            onPressed: () =>
                setState(() => widget.customCategories.removeAt(index)),
          ),
        ],
      ),
    );
  }
}
