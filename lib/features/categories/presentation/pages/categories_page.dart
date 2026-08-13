import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../domain/entities/transaction_category.dart';
import '../cubit/categories_cubit.dart';
import '../cubit/categories_state.dart';
import '../widgets/category_form_sheet.dart';

/// Manage categories: create, rename, hide and delete.
///
/// Hiding is the headline action — a category the user stops using leaves the
/// pickers but keeps naming the movements already filed under it.
class CategoriesPage extends StatefulWidget {
  final String userId;

  const CategoriesPage({super.key, required this.userId});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late final CategoriesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<CategoriesCubit>();
    _cubit.watchCategories(widget.userId);
  }

  Future<void> _create() async {
    final draft = await CategoryFormSheet.show(context);
    if (draft == null) return;
    final ok = await _cubit.createCategory(
      label: draft.label,
      icon: draft.icon,
      types: draft.types,
    );
    if (!mounted) return;
    if (!ok) _toast('No se pudo crear la categoría');
  }

  Future<void> _edit(TransactionCategory category) async {
    final draft = await CategoryFormSheet.show(context, category: category);
    if (draft == null) return;
    final ok = await _cubit.updateCategory(draft);
    if (!mounted) return;
    if (!ok) _toast('No se pudo guardar');
  }

  Future<void> _toggle(TransactionCategory category, bool value) async {
    final ok = await _cubit.setActive(category, value);
    if (!mounted || ok) return;
    _toast(category.isProtected
        ? '"${category.label}" es una categoría del sistema y no se puede ocultar'
        : 'Necesitas dejar al menos una categoría activa de este tipo');
  }

  Future<void> _delete(TransactionCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${category.label}"? '
            'Solo se puede si ningún movimiento la usa.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await _cubit.deleteCategory(category);
    if (!mounted) return;
    switch (result) {
      case DeleteCategoryResult.deleted:
        _toast('Categoría eliminada');
      case DeleteCategoryResult.inUse:
        _offerHide(category);
      case DeleteCategoryResult.protected:
        _toast('Las categorías por defecto no se eliminan, se ocultan');
      case DeleteCategoryResult.failed:
        _toast('No se pudo eliminar');
    }
  }

  /// A category in use can't be deleted without orphaning movements, so offer
  /// the safe alternative right where the user asked for the destructive one.
  void _offerHide(TransactionCategory category) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ya tiene movimientos'),
        content: Text(
            'Hay movimientos registrados con "${category.label}". Si la borras, '
            'esos registros se quedarían sin categoría.\n\n'
            'Puedes ocultarla: desaparece al registrar, pero tus movimientos '
            'siguen mostrándola.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _toggle(category, false);
            },
            child: const Text('Ocultarla'),
          ),
        ],
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: const Text('Mis categorías')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _create,
          icon: const Icon(Icons.add),
          label: const Text('Nueva'),
        ),
        body: BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, state) {
            if (state.isLoading || state.all.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final expenses = state.ofType(TransactionType.expense);
            final incomes = state.ofType(TransactionType.income);
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.pagePadding, AppDimensions.md,
                  AppDimensions.pagePadding, 96),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 18, color: AppColors.grey500),
                      const SizedBox(width: AppDimensions.sm),
                      Expanded(
                        child: Text(
                          'Apaga las que no uses: dejan de aparecer al registrar, '
                          'pero tus movimientos anteriores no cambian.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.grey600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),
                _section('Gastos', expenses),
                const SizedBox(height: AppDimensions.lg),
                _section('Ingresos', incomes),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _section(String title, List<TransactionCategory> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.grey500, letterSpacing: 0.8)),
        const SizedBox(height: AppDimensions.sm),
        ...categories.map(_tile),
      ],
    );
  }

  Widget _tile(TransactionCategory category) {
    final primary = Theme.of(context).colorScheme.primary;
    final dimmed = !category.isActive;
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.sm),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.grey200),
        ),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            alignment: Alignment.center,
            child: Text(category.icon, style: const TextStyle(fontSize: 20)),
          ),
          title: Text(category.label, style: AppTextStyles.labelLarge),
          subtitle: Text(
            category.isProtected
                ? 'Del sistema'
                : category.isDefault
                    ? (category.isActive ? 'Por defecto' : 'Oculta')
                    : (category.isActive ? 'Tuya' : 'Tuya · oculta'),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!category.isProtected)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.grey500,
                  onPressed: () => _edit(category),
                ),
              if (!category.isDefault)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.danger,
                  onPressed: () => _delete(category),
                ),
              Switch(
                value: category.isActive,
                onChanged: category.isProtected
                    ? null
                    : (v) => _toggle(category, v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
