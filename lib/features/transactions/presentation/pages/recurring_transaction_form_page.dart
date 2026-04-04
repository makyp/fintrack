import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/cubit/accounts_state.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/entities/transaction.dart';
import '../cubit/recurring_cubit.dart';

class RecurringTransactionFormPage extends StatefulWidget {
  final String userId;
  final RecurringTransaction? item;

  const RecurringTransactionFormPage({
    super.key,
    required this.userId,
    this.item,
  });

  @override
  State<RecurringTransactionFormPage> createState() =>
      _RecurringTransactionFormPageState();
}

class _RecurringTransactionFormPageState
    extends State<RecurringTransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late final AccountsCubit _accountsCubit;

  late TransactionType _type;
  late TransactionCategory _category;
  late RecurringFrequency _frequency;
  String? _accountId;
  late DateTime _startDate;
  bool _isLoading = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _accountsCubit = getIt<AccountsCubit>()
      ..watchAccounts(widget.userId);
    final item = widget.item;
    _type = item?.type ?? TransactionType.expense;
    _category = item?.category ?? TransactionCategory.forType(_type).first;
    _frequency = item?.frequency ?? RecurringFrequency.monthly;
    _accountId = item?.accountId;
    _startDate = item?.startDate ?? DateTime.now();
    if (item != null) {
      _amountCtrl.text = item.amount.toStringAsFixed(0);
      _descCtrl.text = item.description;
    }
  }

  @override
  void dispose() {
    _accountsCubit.close();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una cuenta')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final amount = double.tryParse(_amountCtrl.text) ?? 0;
      final rt = RecurringTransaction(
        id: _isEditing ? widget.item!.id : '',
        userId: widget.userId,
        amount: amount,
        type: _type,
        category: _category,
        accountId: _accountId!,
        description: _descCtrl.text.trim(),
        frequency: _frequency,
        startDate: _startDate,
        nextDueDate: _isEditing ? widget.item!.nextDueDate : _startDate,
        isActive: true,
        createdAt: _isEditing ? widget.item!.createdAt : DateTime.now(),
      );

      final cubit = context.read<RecurringCubit>();
      final ok = _isEditing ? await cubit.update(rt) : await cubit.add(rt);
      if (ok && mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _accountsCubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar recurrente' : 'Nueva recurrente'),
          leading: const CloseButton(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pagePadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tipo
                _buildTypeSelector(),
                const SizedBox(height: AppDimensions.lg),
                // Monto
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  style: AppTextStyles.displaySmall.copyWith(
                      color: _type == TransactionType.expense ? AppColors.danger : AppColors.success),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: '0', prefixText: '\$ ', border: InputBorder.none),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa el monto';
                    if ((double.tryParse(v) ?? 0) <= 0) return 'Monto inválido';
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.md),
                // Descripción
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Ingresa una descripción' : null,
                ),
                const SizedBox(height: AppDimensions.lg),
                // Categoría
                Text('Categoría', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppDimensions.sm),
                _buildCategoryChips(),
                const SizedBox(height: AppDimensions.lg),
                // Frecuencia
                Text('Frecuencia', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppDimensions.sm),
                _buildFrequencyChips(),
                const SizedBox(height: AppDimensions.lg),
                // Cuenta
                Text('Cuenta', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppDimensions.sm),
                _buildAccountDropdown(),
                const SizedBox(height: AppDimensions.lg),
                // Fecha inicio
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined, color: AppColors.grey500),
                  title: Text('Inicia', style: AppTextStyles.labelLarge),
                  subtitle: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.grey400),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => _startDate = d);
                  },
                ),
                const SizedBox(height: AppDimensions.xl),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                      : Text(_isEditing ? 'Guardar cambios' : 'Crear recurrente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: TransactionType.values
          .where((t) => t != TransactionType.transfer)
          .map((t) {
        final isSelected = _type == t;
        final color = t == TransactionType.expense ? AppColors.danger : AppColors.success;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _type = t;
              _category = TransactionCategory.forType(t).first;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: t == TransactionType.expense ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  t == TransactionType.expense ? 'Gasto' : 'Ingreso',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected ? AppColors.white : AppColors.grey700,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryChips() {
    final cats = TransactionCategory.forType(_type);
    return Wrap(
      spacing: AppDimensions.sm,
      runSpacing: AppDimensions.sm,
      children: cats.map((cat) {
        final isSelected = _category == cat;
        final color = _type == TransactionType.expense ? AppColors.danger : AppColors.success;
        return GestureDetector(
          onTap: () => setState(() => _category = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : AppColors.grey100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? color : AppColors.grey200),
            ),
            child: Text('${cat.icon} ${cat.label}',
                style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? color : AppColors.grey700,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFrequencyChips() {
    return Wrap(
      spacing: AppDimensions.sm,
      runSpacing: AppDimensions.sm,
      children: RecurringFrequency.values.map((f) {
        final isSelected = _frequency == f;
        return ChoiceChip(
          label: Text(f.label),
          selected: isSelected,
          onSelected: (_) => setState(() => _frequency = f),
          selectedColor: AppColors.primary.withOpacity(0.15),
          labelStyle: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? AppColors.primary : AppColors.grey700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccountDropdown() {
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, state) {
        final accounts = state.activeAccounts;
        if (accounts.isEmpty) {
          return Text('No hay cuentas', style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500));
        }
        return DropdownButtonFormField<String>(
          value: _accountId,
          decoration: const InputDecoration(labelText: 'Selecciona cuenta'),
          items: accounts.map((a) => DropdownMenuItem(
            value: a.id,
            child: Row(children: [
              Text(a.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(a.name),
            ]),
          )).toList(),
          onChanged: (v) => setState(() => _accountId = v),
          validator: (v) => v == null ? 'Selecciona una cuenta' : null,
        );
      },
    );
  }
}
