import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/thousands_separator_formatter.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/account.dart';
import '../cubit/accounts_cubit.dart';
import '../cubit/accounts_state.dart';

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
  final _rateCtrl = TextEditingController();
  late final AccountsCubit _cubit;

  AccountType _selectedType = AccountType.checking;
  int _selectedColor = 0xFF2563EB;
  bool _isLoading = false;

  /// Credit card billing cycle: day the statement closes and day the payment
  /// is due. Both drive the reminders scheduled by LocalNotificationService.
  int? _statementDay;
  int? _paymentDay;

  bool get _isEditing => widget.editAccount != null;
  bool get _isCredit => _selectedType == AccountType.credit;

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
    _cubit = getIt<AccountsCubit>();
    if (_isEditing) {
      final a = widget.editAccount!;
      _nameCtrl.text = a.name;
      _balanceCtrl.text = ThousandsSeparatorFormatter()
          .formatEditUpdate(
            const TextEditingValue(text: ''),
            TextEditingValue(text: a.balance.toStringAsFixed(0)),
          )
          .text;
      _selectedType = a.type;
      _selectedColor = a.colorValue;
      if (a.interestRate != null) {
        _rateCtrl.text = (a.interestRate! * 100).toStringAsFixed(2);
      }
      _statementDay = a.statementDay;
      _paymentDay = a.paymentDay;
    }
  }

  @override
  void dispose() {
    _cubit.close();
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(String userId) async {
    if (!_formKey.currentState!.validate()) return;
    if (_isCredit && (_statementDay == null || _paymentDay == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indica la fecha de corte y la fecha límite de pago'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión no disponible, reinicia la app')),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final name = _selectedType == AccountType.cash ? 'Efectivo' : _nameCtrl.text.trim();
      final interestRate = _selectedType == AccountType.highYield
          ? (double.tryParse(_rateCtrl.text.replaceAll(',', '.')) ?? 0) / 100
          : null;
      if (_isEditing) {
        // Balance is intentionally kept unchanged when editing name/type/color.
        final updated = widget.editAccount!.copyWith(
          name: name,
          type: _selectedType,
          colorValue: _selectedColor,
          icon: _selectedType.icon,
          interestRate: interestRate,
          clearInterestRate: _selectedType != AccountType.highYield,
          statementDay: _isCredit ? _statementDay : null,
          paymentDay: _isCredit ? _paymentDay : null,
          clearBillingCycle: !_isCredit,
        );
        await _cubit.updateAccount(updated);
      } else {
        final balance = ThousandsSeparatorFormatter.parse(_balanceCtrl.text);
        final account = Account(
          id: '',
          userId: userId,
          name: name,
          type: _selectedType,
          balance: balance,
          colorValue: _selectedColor,
          icon: _selectedType.icon,
          createdAt: DateTime.now(),
          interestRate: interestRate,
          statementDay: _isCredit ? _statementDay : null,
          paymentDay: _isCredit ? _paymentDay : null,
        );
        await _cubit.addAccount(account);
      }

      if (_cubit.state.status == AccountsStatus.error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_cubit.state.errorMessage ?? 'Error al guardar'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthBloc>().state.user?.uid ?? '';

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
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
              if (_selectedType != AccountType.cash) ...[
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
              ],
              if (_selectedType == AccountType.highYield) ...[
                const SizedBox(height: AppDimensions.md),
                TextFormField(
                  controller: _rateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Tasa de interés efectivo anual (EA)',
                    hintText: 'Ej: 12.5',
                    prefixIcon: Icon(Icons.percent),
                    suffixText: '% EA',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa la tasa de interés';
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    if (n == null || n <= 0 || n > 100) return 'Ingresa un valor entre 0 y 100';
                    return null;
                  },
                ),
              ],
              if (_isCredit) ...[
                const SizedBox(height: AppDimensions.lg),
                _buildBillingCycleSection(),
              ],
              if (!_isEditing) ...[
                const SizedBox(height: AppDimensions.md),
                TextFormField(
                  controller: _balanceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorFormatter()],
                  decoration: InputDecoration(
                    // On a credit card the balance is what you owe, not what
                    // you have — say so instead of "saldo".
                    labelText: _isCredit ? 'Deuda actual' : 'Saldo inicial',
                    hintText: '0',
                    prefixText: '\$ ',
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? (_isCredit ? 'Ingresa la deuda actual' : 'Ingresa el saldo')
                      : null,
                ),
              ],
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
                  onPressed: () => _confirmDelete(userId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  child: const Text('Eliminar cuenta'),
                ),
              ],
            ],
          ),
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

  /// Asks for the two dates every credit card statement revolves around, and
  /// previews what the app will do with them so the value is obvious.
  Widget _buildBillingCycleSection() {
    final preview = _cyclePreview();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ciclo de facturación', style: AppTextStyles.labelLarge),
        const SizedBox(height: 4),
        Text(
          'Con estas dos fechas te avisamos del corte y del pago.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
        ),
        const SizedBox(height: AppDimensions.sm),
        Row(
          children: [
            Expanded(
              child: _buildDayDropdown(
                label: 'Día de corte',
                icon: Icons.event_available_outlined,
                value: _statementDay,
                onChanged: (v) => setState(() => _statementDay = v),
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: _buildDayDropdown(
                label: 'Día de pago',
                icon: Icons.event_busy_outlined,
                value: _paymentDay,
                onChanged: (v) => setState(() => _paymentDay = v),
              ),
            ),
          ],
        ),
        if (preview != null) ...[
          const SizedBox(height: AppDimensions.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: Color(_selectedColor).withOpacity(0.07),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: Color(_selectedColor).withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notifications_active_outlined,
                    size: 18, color: Color(_selectedColor)),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    preview,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Plain-language summary of the reminders these dates will produce.
  String? _cyclePreview() {
    final statement = _statementDay;
    final payment = _paymentDay;
    if (statement == null || payment == null) return null;
    return 'Te avisaremos el día $statement (corte), 3 días antes del pago y '
        'el día $payment (fecha límite de pago).';
  }

  Widget _buildDayDropdown({
    required String label,
    required IconData icon,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      items: [
        for (var day = 1; day <= 31; day++)
          DropdownMenuItem(value: day, child: Text('$day')),
      ],
      onChanged: onChanged,
      validator: (v) => v == null ? 'Requerido' : null,
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

  void _confirmDelete(String userId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Se eliminará permanentemente esta cuenta. Las transacciones registradas no se borran. ¿Continuar?',
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
                  .deleteAccount(userId, widget.editAccount!.id);
              if (mounted) context.pop(true);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
