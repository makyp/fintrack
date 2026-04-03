import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/cubit/accounts_state.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/transactions_bloc.dart';
import '../bloc/transactions_event.dart';

class TransactionFormPage extends StatefulWidget {
  final String userId;
  final Transaction? transaction;
  final TransactionType? initialType;

  const TransactionFormPage({
    super.key,
    required this.userId,
    this.transaction,
    this.initialType,
  });

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  late TransactionType _type;
  late TransactionCategory _category;
  String? _selectedAccountId;
  late DateTime _selectedDate;
  bool _isLoading = false;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _type = tx?.type ?? widget.initialType ?? TransactionType.expense;
    _category = tx?.category ?? TransactionCategory.food;
    _selectedAccountId = tx?.accountId;
    _selectedDate = tx?.date ?? DateTime.now();
    if (tx != null) {
      _amountCtrl.text = tx.amount.toStringAsFixed(0);
      _descCtrl.text = tx.description;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una cuenta'), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => _isLoading = true);

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    final now = DateTime.now();

    if (_isEditing) {
      final updated = widget.transaction!.copyWith(
        amount: amount,
        type: _type,
        category: _category,
        accountId: _selectedAccountId,
        description: _descCtrl.text.trim(),
        date: _selectedDate,
      );
      context.read<TransactionsBloc>().add(TransactionEdited(updated));
    } else {
      final tx = Transaction(
        id: '',
        userId: widget.userId,
        amount: amount,
        type: _type,
        category: _category,
        accountId: _selectedAccountId!,
        description: _descCtrl.text.trim(),
        date: _selectedDate,
        createdAt: now,
      );
      context.read<TransactionsBloc>().add(TransactionAdded(tx));
    }

    if (mounted) Navigator.of(context).pop();
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar transacción'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TransactionsBloc>().add(TransactionDeleted(
                    userId: widget.userId,
                    transactionId: widget.transaction!.id,
                    accountId: widget.transaction!.accountId,
                    amount: widget.transaction!.amount,
                    transactionType: widget.transaction!.type,
                  ));
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AccountsCubit>()..watchAccounts(widget.userId),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar transacción' : 'Nueva transacción'),
          leading: const CloseButton(),
          actions: [
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppColors.danger,
                onPressed: _confirmDelete,
              ),
          ],
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
                _buildAmountField(),
                const SizedBox(height: AppDimensions.md),
                _buildDescriptionField(),
                const SizedBox(height: AppDimensions.lg),
                _buildCategorySelector(),
                const SizedBox(height: AppDimensions.lg),
                _buildAccountSelector(),
                const SizedBox(height: AppDimensions.lg),
                _buildDateSelector(),
                const SizedBox(height: AppDimensions.xl),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                      : Text(_isEditing ? 'Guardar cambios' : 'Registrar'),
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
              margin: EdgeInsets.only(right: t == TransactionType.expense ? 6 : 0,
                  left: t == TransactionType.income ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(t == TransactionType.expense ? Icons.remove_circle_outline : Icons.add_circle_outline,
                      color: isSelected ? AppColors.white : color, size: 24),
                  const SizedBox(height: 4),
                  Text(t == TransactionType.expense ? 'Gasto' : 'Ingreso',
                      style: AppTextStyles.labelMedium.copyWith(
                          color: isSelected ? AppColors.white : AppColors.grey700)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmountField() {
    final color = _type == TransactionType.expense ? AppColors.danger : AppColors.success;
    return TextFormField(
      controller: _amountCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      style: AppTextStyles.displaySmall.copyWith(color: color),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: '0',
        prefixText: '\$ ',
        prefixStyle: AppTextStyles.displaySmall.copyWith(color: color),
        border: InputBorder.none,
        filled: false,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ingresa el monto';
        if ((double.tryParse(v) ?? 0) <= 0) return 'El monto debe ser mayor a 0';
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descCtrl,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Descripción (opcional)',
        hintText: 'Ej: Almuerzo en restaurante',
        prefixIcon: Icon(Icons.notes),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = TransactionCategory.forType(_type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Categoría', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppDimensions.sm),
        Wrap(
          spacing: AppDimensions.sm,
          runSpacing: AppDimensions.sm,
          children: categories.map((cat) {
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(cat.label,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected ? color : AppColors.grey700,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAccountSelector() {
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, accountsState) {
        final accounts = accountsState.activeAccounts;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cuenta', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppDimensions.sm),
            if (accounts.isEmpty)
              Text('No hay cuentas disponibles',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500))
            else
              DropdownButtonFormField<String>(
                value: _selectedAccountId,
                decoration: const InputDecoration(labelText: 'Selecciona una cuenta'),
                items: accounts.map((a) {
                  return DropdownMenuItem(
                    value: a.id,
                    child: Row(
                      children: [
                        Text(a.icon, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(a.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedAccountId = v),
                validator: (v) => v == null ? 'Selecciona una cuenta' : null,
              ),
          ],
        );
      },
    );
  }

  Widget _buildDateSelector() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today_outlined, color: AppColors.grey500),
      title: Text('Fecha', style: AppTextStyles.labelLarge),
      subtitle: Text(
        _selectedDate.day == DateTime.now().day ? 'Hoy' : _formatDate(_selectedDate),
        style: AppTextStyles.bodyMedium,
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.grey400),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
