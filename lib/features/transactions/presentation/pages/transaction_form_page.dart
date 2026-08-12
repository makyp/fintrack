import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/thousands_separator_formatter.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/cubit/accounts_state.dart';
import '../../../../core/di/injection.dart';
import '../../../capture/domain/entities/transaction_draft.dart';
import '../../domain/category_matcher.dart';
import '../../domain/entities/transaction.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/transactions_bloc.dart';
import '../bloc/transactions_event.dart';

class TransactionFormPage extends StatefulWidget {
  final String userId;
  final Transaction? transaction;
  final TransactionType? initialType;

  /// Prefill coming from a voice dictation or a receipt photo. Nothing is
  /// saved until the user confirms this form.
  final TransactionDraft? draft;

  const TransactionFormPage({
    super.key,
    required this.userId,
    this.transaction,
    this.initialType,
    this.draft,
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
  bool _shareWithHousehold = false;
  // Kept in sync with AccountsCubit so _save() can validate available balance.
  List<Account> _accounts = const [];

  /// Instalments chosen for a credit card purchase. 1 = a single payment.
  int _installments = 1;

  bool get _isEditing => widget.transaction != null;
  bool get _isTransfer => _type == TransactionType.transfer;

  /// The selected source account is a credit card, so the purchase can be
  /// deferred. Transfers and income are not deferrable.
  bool get _canDefer {
    if (_isTransfer || _type != TransactionType.expense) return false;
    final id = _selectedAccountId;
    if (id == null) return false;
    return _accountById(id)?.type == AccountType.credit;
  }

  /// True when the form was opened from a voice dictation or a receipt photo.
  bool get _isPrefilled =>
      widget.draft != null &&
      widget.draft!.source != CaptureSource.manual &&
      !widget.draft!.isEmpty;

  /// Preselected on a new transaction: the account used last time, so the
  /// most common case is one tap less.
  String? _rememberedAccountId;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    final draft = widget.draft;

    _type = tx?.type ?? draft?.type ?? widget.initialType ?? TransactionType.expense;
    _category = tx?.category ??
        _draftCategory(draft) ??
        TransactionCategory.forType(_type).first;
    _selectedAccountId = tx?.accountId;
    _selectedToAccountId = tx?.toAccountId;
    _selectedDate = tx?.date ?? draft?.date ?? DateTime.now();
    _shareWithHousehold = tx?.householdId != null;
    _installments = tx?.installments ?? 1;

    if (tx != null) {
      _setAmountText(tx.amount);
      _descCtrl.text = tx.description;
    } else if (draft != null) {
      if (draft.hasAmount) _setAmountText(draft.amount!);
      if (draft.description != null) _descCtrl.text = draft.description!;
    }

    if (!_isEditing) _loadRememberedAccount();
    _descCtrl.addListener(_onDescriptionChanged);
    _amountCtrl.addListener(_onAmountChanged);
  }

  /// Keeps the "≈ $X al mes" instalment preview in sync with the amount.
  void _onAmountChanged() {
    if (_canDefer && _installments > 1) setState(() {});
  }

  /// Only accepts the drafted category when it is valid for the resolved type.
  TransactionCategory? _draftCategory(TransactionDraft? draft) {
    final category = draft?.category;
    if (category == null) return null;
    return TransactionCategory.forType(_type).contains(category)
        ? category
        : null;
  }

  void _setAmountText(double amount) {
    _amountCtrl.text = ThousandsSeparatorFormatter()
        .formatEditUpdate(
          const TextEditingValue(text: ''),
          TextEditingValue(text: amount.toStringAsFixed(0)),
        )
        .text;
  }

  @override
  void dispose() {
    _descCtrl.removeListener(_onDescriptionChanged);
    _amountCtrl.removeListener(_onAmountChanged);
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _onDescriptionChanged() {
    if (_isTransfer) return;
    final text = _descCtrl.text;
    if (text.length < 3) return;
    final suggested = CategoryMatcher.suggest(text, type: _type);
    if (suggested != null && suggested != _category) {
      setState(() => _category = suggested);
    }
  }

  // ── Last used account ────────────────────────────────────────────────────

  String get _lastAccountKey => 'last_account_${widget.userId}';

  Future<void> _loadRememberedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_lastAccountKey);
    if (saved == null || !mounted) return;
    setState(() => _rememberedAccountId = saved);
  }

  Future<void> _rememberAccount(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastAccountKey, accountId);
  }

  /// Applies the remembered account once the account list is available and
  /// the user has not chosen one yet.
  void _onAccountsLoaded(List<Account> accounts) {
    _accounts = accounts;
    if (_isEditing || _selectedAccountId != null) return;
    final remembered = _rememberedAccountId;
    if (remembered == null) return;
    if (!accounts.any((a) => a.id == remembered)) return;
    // The dropdown is built in the same frame, so defer the state change.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selectedAccountId == null) {
        setState(() => _selectedAccountId = remembered);
      }
    });
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

    final amount = ThousandsSeparatorFormatter.parse(_amountCtrl.text);

    // Warn when an expense/transfer would overdraw an asset account (credit
    // cards are liabilities, so spending on them is expected — skip those).
    if (!_isEditing && _type != TransactionType.income) {
      final source = _accountById(_selectedAccountId!);
      if (source != null &&
          !source.type.isLiability &&
          amount > source.balance) {
        await _showInsufficientBalance(source, amount);
        return; // hard block — like a bank, the transaction is not allowed
      }
    }
    if (!mounted) return;

    setState(() => _isLoading = true);
    final now = DateTime.now();
    final householdId = (!_isTransfer && _shareWithHousehold)
        ? context.read<AuthBloc>().state.user?.householdId
        : (_isEditing ? widget.transaction!.householdId : null);

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
      householdId: householdId,
      receiptUrl: _isEditing ? widget.transaction!.receiptUrl : null,
      tags: _isEditing ? widget.transaction!.tags : const [],
      createdAt: _isEditing ? widget.transaction!.createdAt : now,
      // Only kept when it actually applies: switching away from the card (or
      // to a single payment) must not leave a stale instalment count behind.
      installments: _canDefer && _installments > 1 ? _installments : null,
    );

    if (_isEditing) {
      context.read<TransactionsBloc>().add(TransactionEdited(tx));
    } else {
      context.read<TransactionsBloc>().add(TransactionAdded(tx));
      // Preselect this account next time.
      unawaited(_rememberAccount(_selectedAccountId!));
    }

    if (mounted) Navigator.of(context).pop();
  }

  Account? _accountById(String id) {
    for (final a in _accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Blocks the transaction: the amount exceeds the account's available
  /// balance, so (like a banking app) we inform the user and do not let it
  /// through. They must correct the amount or pick another account.
  Future<void> _showInsufficientBalance(Account account, double amount) {
    final missing = amount - account.balance;
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.account_balance_wallet_outlined,
            color: AppColors.danger, size: 36),
        title: const Text('Saldo insuficiente'),
        content: Text(
          'La cuenta "${account.name}" tiene '
          '${CurrencyFormatter.format(account.balance)} disponible, '
          'pero estás registrando ${CurrencyFormatter.format(amount)}.\n\n'
          'Faltan ${CurrencyFormatter.format(missing)}. No puedes registrar un '
          'movimiento mayor al saldo disponible. Verifica el monto o elige '
          'otra cuenta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    final bloc = context.read<TransactionsBloc>();
    final nav = Navigator.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar transacción'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              bloc.add(TransactionDeleted(
                userId: widget.userId,
                transactionId: widget.transaction!.id,
                accountId: widget.transaction!.accountId,
                amount: widget.transaction!.amount,
                transactionType: widget.transaction!.type,
              ));
              nav.pop();
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
        body: BlocListener<AccountsCubit, AccountsState>(
          listener: (_, state) => _onAccountsLoaded(state.activeAccounts),
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pagePadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isPrefilled) ...[
                  _buildDraftBanner(),
                  const SizedBox(height: AppDimensions.md),
                ],
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
                if (_canDefer) ...[
                  const SizedBox(height: AppDimensions.lg),
                  _buildInstallmentsSelector(),
                ],
                if (_isTransfer) ...[
                  const SizedBox(height: AppDimensions.lg),
                  _buildToAccountSelector(),
                ],
                const SizedBox(height: AppDimensions.lg),
                _buildDateSelector(),
                if (!_isTransfer) _buildHouseholdToggle(context),
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
      keyboardType: TextInputType.number,
      inputFormatters: [ThousandsSeparatorFormatter()],
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
        if (ThousandsSeparatorFormatter.parse(v) <= 0) return 'El monto debe ser mayor a 0';
        return null;
      },
    );
  }

  /// Tells the user where the prefilled values came from, and that they are
  /// still the ones deciding — the parser can misread.
  Widget _buildDraftBanner() {
    final draft = widget.draft!;
    final isVoice = draft.source == CaptureSource.voice;
    final color = isVoice
        ? Theme.of(context).colorScheme.primary
        : AppColors.secondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isVoice ? Icons.mic_none_rounded : Icons.receipt_long_outlined,
              color: color, size: 20),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(draft.source.label,
                    style: AppTextStyles.labelMedium.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(
                  'Revisa los datos y ajusta lo que falte antes de registrar.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey600),
                ),
                if (draft.rawText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '«${draft.rawText}»',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descCtrl,
      textCapitalization: TextCapitalization.sentences,
      // A receipt fills this with the whole product list, which is unreadable
      // on one line — let the field grow instead of hiding the text.
      minLines: 1,
      maxLines: 4,
      keyboardType: TextInputType.multiline,
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
                onChanged: (v) => setState(() {
                  _selectedAccountId = v;
                  // Leaving a credit card drops the instalment plan, so the
                  // field never shows a stale value when it reappears.
                  if (!_canDefer) _installments = 1;
                }),
                validator: (v) => v == null ? 'Selecciona una cuenta' : null,
              ),
          ],
        );
      },
    );
  }

  /// Common instalment plans offered by Colombian issuers. "Otro" lets the
  /// user type any number the bank actually gave them.
  static const _installmentOptions = [1, 2, 3, 6, 9, 12, 18, 24, 36];

  Widget _buildInstallmentsSelector() {
    final amount = ThousandsSeparatorFormatter.parse(_amountCtrl.text);
    final perMonth = _installments > 1 && amount > 0
        ? amount / _installments
        : null;
    final options = {..._installmentOptions, _installments}.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cuotas', style: AppTextStyles.labelLarge),
        const SizedBox(height: 4),
        Text(
          'Compra con tarjeta de crédito: ¿a cuántas cuotas la diferiste?',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
        ),
        const SizedBox(height: AppDimensions.sm),
        DropdownButtonFormField<int>(
          value: options.contains(_installments) ? _installments : 1,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.credit_card_outlined),
          ),
          items: [
            for (final n in options)
              DropdownMenuItem(
                value: n,
                child: Text(n == 1 ? 'Una sola cuota' : '$n cuotas'),
              ),
          ],
          onChanged: (v) => setState(() => _installments = v ?? 1),
        ),
        const SizedBox(height: AppDimensions.sm),
        TextButton.icon(
          onPressed: _promptCustomInstallments,
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Otro número de cuotas'),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
        if (perMonth != null) ...[
          const SizedBox(height: 4),
          Text(
            'Aprox. ${CurrencyFormatter.format(perMonth)} al mes durante '
            '$_installments meses. La deuda total de la tarjeta sube por el '
            'valor completo de la compra.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
          ),
        ],
      ],
    );
  }

  Future<void> _promptCustomInstallments() async {
    final controller = TextEditingController(text: '$_installments');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Número de cuotas'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Cuotas',
            hintText: 'Ej: 48',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final n = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, (n != null && n >= 1 && n <= 120) ? n : null);
            },
            child: const Text('Usar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && mounted) setState(() => _installments = result);
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
          builder: (ctx, child) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
              child: child!,
            ),
          ),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Widget _buildHouseholdToggle(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final householdId = authState.user?.householdId;
        if (householdId == null) return const SizedBox.shrink();
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.home_outlined, color: AppColors.grey500),
          title: const Text('Compartir con hogar'),
          subtitle: const Text('Aparecerá en el reporte del hogar'),
          value: _shareWithHousehold,
          onChanged: (v) => setState(() => _shareWithHousehold = v),
        );
      },
    );
  }
}
