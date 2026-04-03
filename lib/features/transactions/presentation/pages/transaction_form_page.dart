import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/cubit/accounts_state.dart';
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
  String? _selectedToAccountId;
  late DateTime _selectedDate;
  bool _isLoading = false;

  bool get _isEditing => widget.transaction != null;
  bool get _isTransfer => _type == TransactionType.transfer;

  // ── Auto-categorization keyword map ──────────────────────────────────────
  static const _categoryKeywords = <TransactionCategory, List<String>>{
    TransactionCategory.food: [
      'almuerzo', 'comida', 'restaurante', 'café', 'cafe', 'pizza', 'burger',
      'sushi', 'desayuno', 'cena', 'mercado', 'supermercado', 'rappi', 'domicilio',
      'hamburguesa', 'pollo', 'sandwich', 'taco', 'ensalada', 'postre',
    ],
    TransactionCategory.transport: [
      'uber', 'taxi', 'bus', 'metro', 'transporte', 'gasolina', 'combustible',
      'parqueadero', 'estacionamiento', 'peaje', 'tren', 'avión', 'avion', 'vuelo',
    ],
    TransactionCategory.entertainment: [
      'netflix', 'spotify', 'cine', 'película', 'pelicula', 'juego', 'concierto',
      'teatro', 'streaming', 'prime', 'disney', 'youtube', 'hbo', 'apple tv',
    ],
    TransactionCategory.health: [
      'farmacia', 'médico', 'medico', 'doctor', 'hospital', 'clínica', 'clinica',
      'medicina', 'gym', 'gimnasio', 'dentista', 'psicólogo', 'psicologo', 'droga',
    ],
    TransactionCategory.education: [
      'libro', 'curso', 'universidad', 'colegio', 'matrícula', 'matricula',
      'udemy', 'coursera', 'tutoría', 'tutoria', 'platzi', 'clase',
    ],
    TransactionCategory.home: [
      'alquiler', 'arriendo', 'luz', 'agua', 'gas', 'internet', 'cable',
      'mantenimiento', 'reparación', 'reparacion', 'mueble', 'hogar', 'limpieza',
    ],
    TransactionCategory.clothing: [
      'ropa', 'zapatos', 'camisa', 'pantalón', 'pantalon', 'vestido', 'moda',
      'tenis', 'zapatillas', 'chaqueta', 'abrigo',
    ],
    TransactionCategory.technology: [
      'celular', 'laptop', 'computador', 'tablet', 'auriculares', 'teclado',
      'software', 'app', 'apple', 'samsung', 'mouse',
    ],
    TransactionCategory.services: [
      'teléfono', 'telefono', 'plan', 'seguro', 'servicio', 'suscripción',
      'suscripcion', 'mensualidad', 'factura',
    ],
    TransactionCategory.salary: [
      'salario', 'sueldo', 'nómina', 'nomina', 'quincena', 'pago mensual',
    ],
    TransactionCategory.freelance: [
      'proyecto', 'freelance', 'consultoría', 'consultoria', 'honorarios', 'factura',
    ],
    TransactionCategory.investment: [
      'dividendo', 'interés', 'interes', 'rendimiento', 'acciones', 'crypto',
      'bitcoin', 'bolsa', 'fondo',
    ],
  };

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _type = tx?.type ?? widget.initialType ?? TransactionType.expense;
    _category = tx?.category ?? TransactionCategory.forType(_type).first;
    _selectedAccountId = tx?.accountId;
    _selectedToAccountId = tx?.toAccountId;
    _selectedDate = tx?.date ?? DateTime.now();
    if (tx != null) {
      _amountCtrl.text = tx.amount.toStringAsFixed(0);
      _descCtrl.text = tx.description;
    }
    _descCtrl.addListener(_onDescriptionChanged);
  }

  @override
  void dispose() {
    _descCtrl.removeListener(_onDescriptionChanged);
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _onDescriptionChanged() {
    if (_isTransfer) return;
    final text = _descCtrl.text.toLowerCase();
    if (text.length < 3) return;
    final suggested = _suggestCategory(text);
    if (suggested != null && suggested != _category) {
      setState(() => _category = suggested);
    }
  }

  TransactionCategory? _suggestCategory(String text) {
    for (final entry in _categoryKeywords.entries) {
      for (final kw in entry.value) {
        if (text.contains(kw)) return entry.key;
      }
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una cuenta'), backgroundColor: AppColors.danger),
      );
      return;
    }
    if (_isTransfer) {
      if (_selectedToAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona la cuenta destino'), backgroundColor: AppColors.danger),
        );
        return;
      }
      if (_selectedToAccountId == _selectedAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Las cuentas deben ser diferentes'), backgroundColor: AppColors.danger),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    final now = DateTime.now();

    // Build the transaction (whether creating or editing)
    final tx = Transaction(
      id: _isEditing ? widget.transaction!.id : '',
      userId: widget.userId,
      amount: amount,
      type: _type,
      category: _category,
      accountId: _selectedAccountId!,
      toAccountId: _isTransfer ? _selectedToAccountId : null,
      description: _descCtrl.text.trim(),
      date: _selectedDate,
      isRecurring: _isEditing ? widget.transaction!.isRecurring : false,
      householdId: _isEditing ? widget.transaction!.householdId : null,
      receiptUrl: _isEditing ? widget.transaction!.receiptUrl : null,
      tags: _isEditing ? widget.transaction!.tags : const [],
      createdAt: _isEditing ? widget.transaction!.createdAt : now,
    );

    if (_isEditing) {
      context.read<TransactionsBloc>().add(TransactionEdited(tx));
    } else {
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
                if (!_isTransfer) ...[
                  _buildCategorySelector(),
                  const SizedBox(height: AppDimensions.lg),
                ],
                _buildAccountSelector(),
                if (_isTransfer) ...[
                  const SizedBox(height: AppDimensions.lg),
                  _buildToAccountSelector(),
                ],
                const SizedBox(height: AppDimensions.lg),
                _buildDateSelector(),
                const SizedBox(height: AppDimensions.xl),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
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
    final types = [TransactionType.expense, TransactionType.income, TransactionType.transfer];
    return Row(
      children: types.map((t) {
        final isSelected = _type == t;
        final color = _typeColor(t);
        final isLast = t == types.last;
        final isFirst = t == types.first;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _type = t;
              _category = TransactionCategory.forType(t).first;
              if (t != TransactionType.transfer) _selectedToAccountId = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: isLast ? 0 : 6,
                left: isFirst ? 0 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(_typeIcon(t), color: isSelected ? AppColors.white : color, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    _typeLabel(t),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected ? AppColors.white : AppColors.grey700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _typeColor(TransactionType t) {
    switch (t) {
      case TransactionType.expense: return AppColors.danger;
      case TransactionType.income: return AppColors.success;
      case TransactionType.transfer: return AppColors.secondary;
    }
  }

  IconData _typeIcon(TransactionType t) {
    switch (t) {
      case TransactionType.expense: return Icons.remove_circle_outline;
      case TransactionType.income: return Icons.add_circle_outline;
      case TransactionType.transfer: return Icons.swap_horiz;
    }
  }

  String _typeLabel(TransactionType t) {
    switch (t) {
      case TransactionType.expense: return 'Gasto';
      case TransactionType.income: return 'Ingreso';
      case TransactionType.transfer: return 'Transferir';
    }
  }

  Widget _buildAmountField() {
    final color = _typeColor(_type);
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
    final color = _typeColor(_type);
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
        final label = _isTransfer ? 'Cuenta origen' : 'Cuenta';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.labelLarge),
            const SizedBox(height: AppDimensions.sm),
            if (accounts.isEmpty)
              Text('No hay cuentas disponibles',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500))
            else
              DropdownButtonFormField<String>(
                value: _selectedAccountId,
                decoration: InputDecoration(labelText: 'Selecciona $label'.toLowerCase()),
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

  Widget _buildToAccountSelector() {
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, accountsState) {
        final accounts = accountsState.activeAccounts
            .where((a) => a.id != _selectedAccountId)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cuenta destino', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppDimensions.sm),
            if (accounts.isEmpty)
              Text('No hay otras cuentas disponibles',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500))
            else
              DropdownButtonFormField<String>(
                value: accounts.any((a) => a.id == _selectedToAccountId)
                    ? _selectedToAccountId
                    : null,
                decoration: const InputDecoration(labelText: 'Selecciona cuenta destino'),
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
                onChanged: (v) => setState(() => _selectedToAccountId = v),
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
        _selectedDate.day == DateTime.now().day &&
                _selectedDate.month == DateTime.now().month &&
                _selectedDate.year == DateTime.now().year
            ? 'Hoy'
            : _formatDate(_selectedDate),
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
