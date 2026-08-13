import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../domain/entities/transaction_category.dart';

const _kIcons = [
  '🍔', '🍕', '☕', '🛒', '🚗', '⛽', '🚌', '✈️', '🏠', '💡',
  '💊', '🏥', '🏋️', '📚', '🎓', '💻', '📱', '🎬', '🎮', '🎵',
  '👕', '👟', '💇', '🧹', '🐾', '🎁', '💼', '📈', '💰', '🧾',
  '🍺', '🌱', '🔧', '📌', '⭐', '❤️',
];

/// Add / edit sheet shared by onboarding and the profile screen.
///
/// Returns the category to save — with an empty [TransactionCategory.id] when
/// it is new, so the caller decides how ids are minted — or null on cancel.
class CategoryFormSheet extends StatefulWidget {
  final TransactionCategory? category;

  const CategoryFormSheet({super.key, this.category});

  static Future<TransactionCategory?> show(
    BuildContext context, {
    TransactionCategory? category,
  }) {
    return showModalBottomSheet<TransactionCategory>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryFormSheet(category: category),
    );
  }

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _icon = '📌';
  final Set<TransactionType> _types = {TransactionType.expense};

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    if (c != null) {
      _nameCtrl.text = c.label;
      _icon = c.icon;
      _types
        ..clear()
        ..addAll(c.types.where((t) => t != TransactionType.transfer));
      if (_types.isEmpty) _types.add(TransactionType.expense);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_types.isEmpty) return;
    final base = widget.category;
    final result = base != null
        ? base.copyWith(
            label: _nameCtrl.text.trim(),
            icon: _icon,
            types: _types.toList(),
          )
        : TransactionCategory(
            id: '',
            label: _nameCtrl.text.trim(),
            icon: _icon,
            types: _types.toList(),
          );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding,
          AppDimensions.sm,
          AppDimensions.pagePadding,
          AppDimensions.lg,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppDimensions.md),
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(_isEditing ? 'Editar categoría' : 'Nueva categoría',
                  style: AppTextStyles.headlineSmall),
              const SizedBox(height: AppDimensions.lg),

              // ── Nombre ────────────────────────────────────────────────────
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Mascotas, Ahorro, Viajes…',
                  prefixIcon: Container(
                    alignment: Alignment.center,
                    width: 24,
                    child: Text(_icon, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.isEmpty) return 'Ponle un nombre';
                  if (text.length > 24) return 'Máximo 24 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.lg),

              // ── Tipo ──────────────────────────────────────────────────────
              Text('¿Dónde la vas a usar?', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              Row(
                children: [
                  _typeChip('Gastos', TransactionType.expense, primary),
                  const SizedBox(width: AppDimensions.sm),
                  _typeChip('Ingresos', TransactionType.income, primary),
                ],
              ),
              const SizedBox(height: AppDimensions.lg),

              // ── Ícono ─────────────────────────────────────────────────────
              Text('Ícono', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              SizedBox(
                height: 132,
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 9,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: _kIcons.length,
                  itemBuilder: (_, i) {
                    final emoji = _kIcons[i];
                    final selected = emoji == _icon;
                    return GestureDetector(
                      onTap: () => setState(() => _icon = emoji),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? primary.withOpacity(0.14)
                              : AppColors.grey100,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusSm),
                          border: Border.all(
                            color: selected ? primary : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(emoji, style: const TextStyle(fontSize: 18)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppDimensions.lg),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(_isEditing ? 'Guardar cambios' : 'Crear categoría'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String label, TransactionType type, Color primary) {
    final selected = _types.contains(type);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          // At least one type has to stay selected.
          if (selected && _types.length > 1) {
            _types.remove(type);
          } else if (!selected) {
            _types.add(type);
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
          decoration: BoxDecoration(
            color: selected ? primary.withOpacity(0.10) : AppColors.grey100,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: selected ? primary : AppColors.grey200,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: selected ? primary : AppColors.grey400,
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: AppTextStyles.labelLarge.copyWith(
                      color: selected ? primary : AppColors.grey600)),
            ],
          ),
        ),
      ),
    );
  }
}
