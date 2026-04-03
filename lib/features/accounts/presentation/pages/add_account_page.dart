import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../domain/entities/account.dart';
import '../cubit/accounts_cubit.dart';

class AddAccountPage extends StatefulWidget {
  final Account? editAccount;

  const AddAccountPage({super.key, this.editAccount});

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();

  AccountType _selectedType = AccountType.checking;
  int _selectedColor = 0xFF2563EB;
  bool _isLoading = false;

  bool get _isEditing => widget.editAccount != null;

  static const _colorOptions = [
    0xFF2563EB, // blue
    0xFF059669, // green
    0xFFDC2626, // red
    0xFFD97706, // amber
    0xFF7C3AED, // purple
    0xFFEC4899, // pink
    0xFF0891B2, // cyan
    0xFF1A3F6F, // dark blue
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final a = widget.editAccount!;
      _nameCtrl.text = a.name;
      _balanceCtrl.text = a.balance.toStringAsFixed(0);
      _selectedType = a.type;
      _selectedColor = a.colorValue;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(String userId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final balance = double.tryParse(_balanceCtrl.text.replaceAll(',', '')) ?? 0;
    final cubit = context.read<AccountsCubit>();

    if (_isEditing) {
      final updated = widget.editAccount!.copyWith(
        name: _nameCtrl.text.trim(),
        type: _selectedType,
        balance: balance,
        colorValue: _selectedColor,
        icon: _selectedType.icon,
      );
      await cubit.updateAccount(updated);
    } else {
      final account = Account(
        id: '',
        userId: userId,
        name: _nameCtrl.text.trim(),
        type: _selectedType,
        balance: balance,
        colorValue: _selectedColor,
        icon: _selectedType.icon,
        createdAt: DateTime.now(),
      );
      await cubit.addAccount(account);
    }

    if (mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    // userId comes from route extra or auth state
    final userId = GoRouterState.of(context).extra as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar cuenta' : 'Nueva cuenta'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: AppDimensions.lg),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la cuenta',
                  hintText: 'Ej: Bancolombia Ahorros',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: AppDimensions.md),
              TextFormField(
                controller: _balanceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                ],
                decoration: InputDecoration(
                  labelText: _isEditing ? 'Saldo actual' : 'Saldo inicial',
                  hintText: '0',
                  prefixText: '\$ ',
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingresa el saldo' : null,
              ),
              const SizedBox(height: AppDimensions.lg),
              Text('Color', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              _buildColorPicker(),
              const SizedBox(height: AppDimensions.xl),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _save(userId),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white),
                      )
                    : Text(_isEditing ? 'Guardar cambios' : 'Agregar cuenta'),
              ),
              if (_isEditing) ...[
                const SizedBox(height: AppDimensions.md),
                OutlinedButton(
                  onPressed: () => _confirmArchive(userId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  child: const Text('Archivar cuenta'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipo de cuenta', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppDimensions.sm),
        Wrap(
          spacing: AppDimensions.sm,
          runSpacing: AppDimensions.sm,
          children: AccountType.values.map((type) {
            final isSelected = _selectedType == type;
            return ChoiceChip(
              label: Text('${type.icon} ${type.label}'),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedType = type),
              selectedColor:
                  Color(_selectedColor).withOpacity(0.2),
              backgroundColor: AppColors.grey100,
              labelStyle: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? Color(_selectedColor) : AppColors.grey700,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? Color(_selectedColor) : AppColors.grey200,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: AppDimensions.sm,
      children: _colorOptions.map((color) {
        final isSelected = _selectedColor == color;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color(color),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: AppColors.grey900, width: 2)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: Color(color).withOpacity(0.4),
                          blurRadius: 8)
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: AppColors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }

  void _confirmArchive(String userId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Archivar cuenta'),
        content: const Text(
          'La cuenta se ocultará del dashboard pero sus transacciones se conservarán. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context
                  .read<AccountsCubit>()
                  .archiveAccount(userId, widget.editAccount!.id);
              if (mounted) context.pop(true);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );
  }
}
