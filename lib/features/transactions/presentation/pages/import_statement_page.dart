import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/domain/currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/cubit/accounts_state.dart';
import '../../data/datasources/transaction_remote_datasource.dart';
import '../../data/models/transaction_model.dart';
import '../../../categories/domain/category_registry.dart';
import '../../domain/category_matcher.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/statement_parser.dart';
import '../bloc/transactions_bloc.dart';
import '../bloc/transactions_event.dart';

/// Imports a bank statement exported as CSV.
///
/// The cheap half of "nothing gets typed": the bank already has every movement,
/// the user downloads the file from their banking app and the mapping,
/// categories and duplicates are worked out here. Nothing is written until the
/// preview is confirmed.
class ImportStatementPage extends StatefulWidget {
  final String userId;

  const ImportStatementPage({super.key, required this.userId});

  @override
  State<ImportStatementPage> createState() => _ImportStatementPageState();
}

class _ImportStatementPageState extends State<ImportStatementPage> {
  final _accountsCubit = getIt<AccountsCubit>();

  String? _fileName;
  ParsedStatement _statement = ParsedStatement.empty;
  ColumnMapping _mapping = const ColumnMapping();
  List<StatementEntry> _entries = const [];

  /// Fingerprints already in the app for the period the file covers.
  Set<String> _existing = const {};

  /// Index of every entry the user wants to import.
  final Set<int> _selected = {};

  String? _accountId;
  bool _isReading = false;
  bool _isImporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _accountsCubit.watchAccounts(widget.userId);
  }

  @override
  void dispose() {
    _accountsCubit.close();
    super.dispose();
  }

  // ── Reading the file ─────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    setState(() {
      _isReading = true;
      _error = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'txt'],
        withData: true, // works on web too, where there is no path
      );
      final file = result?.files.singleOrNull;
      if (file == null) {
        setState(() => _isReading = false);
        return;
      }
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() {
          _isReading = false;
          _error = 'No se pudo leer el archivo. Intenta con otro.';
        });
        return;
      }

      // Bank exports are UTF-8 more often than not, but the ones that aren't
      // are Latin-1 — decoding those as UTF-8 throws, so fall back instead of
      // showing a file full of question marks.
      String content;
      try {
        content = utf8.decode(bytes);
      } on FormatException {
        content = latin1.decode(bytes);
      }

      final parsed = StatementParser.parse(content);
      if (parsed.isEmpty) {
        setState(() {
          _isReading = false;
          _error = 'El archivo no tiene filas que se puedan leer.';
        });
        return;
      }

      setState(() {
        _fileName = file.name;
        _statement = parsed;
        _mapping = parsed.mapping;
        _isReading = false;
      });
      _rebuildEntries();
      await _loadExisting();
    } catch (e) {
      setState(() {
        _isReading = false;
        _error = 'No se pudo abrir el archivo: $e';
      });
    }
  }

  void _rebuildEntries() {
    final entries = StatementParser.toEntries(_statement, _mapping);
    setState(() {
      _entries = entries;
      _selected
        ..clear()
        ..addAll([
          for (var i = 0; i < entries.length; i++)
            if (!_existing.contains(entries[i].fingerprint)) i,
        ]);
    });
  }

  /// Loads what the app already has for the period the file covers, so a
  /// second import of an overlapping statement doesn't duplicate everything.
  Future<void> _loadExisting() async {
    if (_entries.isEmpty) return;
    final dates = _entries.map((e) => e.date).toList()..sort();
    try {
      final source = getIt<TransactionRemoteDataSource>();
      final existing = await source.getTransactions(
        widget.userId,
        from: dates.first,
        to: dates.last.add(const Duration(days: 1)),
        limit: 1000,
      );
      if (!mounted) return;
      setState(() {
        _existing = existing
            .map((t) => StatementEntry(
                  date: t.date,
                  description: t.description,
                  amount: t.amount,
                  type: t.type,
                ).fingerprint)
            .toSet();
      });
      _rebuildEntries();
    } catch (_) {
      // Offline, or no permission to read: the preview still works, the user
      // just doesn't get duplicates pre-unchecked.
    }
  }

  // ── Importing ────────────────────────────────────────────────────────────

  Future<void> _import() async {
    final accountId = _accountId;
    if (accountId == null || _selected.isEmpty) return;
    setState(() => _isImporting = true);

    final account = _accountsCubit.state.activeAccounts
        .where((a) => a.id == accountId)
        .firstOrNull;
    final now = DateTime.now();
    final models = <TransactionModel>[];
    for (final index in _selected.toList()..sort()) {
      final entry = _entries[index];
      final description = entry.description.trim();
      models.add(TransactionModel(
        id: '',
        userId: widget.userId,
        amount: entry.amount,
        type: entry.type,
        // Same matcher the voice and photo capture use, so an imported
        // "NETFLIX.COM" lands in the same category as a dictated one.
        category: CategoryMatcher.suggest(description, type: entry.type) ??
            CategoryRegistry.forType(entry.type).first,
        accountId: accountId,
        description: description.isEmpty ? 'Movimiento importado' : description,
        date: entry.date,
        createdAt: now,
        currency: account?.currency,
        tags: const ['importado'],
      ));
    }

    try {
      final count = await getIt<TransactionRemoteDataSource>()
          .importTransactions(widget.userId, models);
      if (!mounted) return;
      context
          .read<TransactionsBloc>()
          .add(TransactionsWatchStarted(widget.userId));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count movimientos importados'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _error = 'No se pudieron importar: $e';
      });
    }
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _accountsCubit,
      child: Scaffold(
        appBar: AppBar(title: const Text('Importar extracto')),
        body: BlocBuilder<AccountsCubit, AccountsState>(
          builder: (context, state) {
            final accounts = state.activeAccounts;
            return ListView(
              padding: const EdgeInsets.all(AppDimensions.pagePadding),
              children: [
                _buildIntro(),
                const SizedBox(height: AppDimensions.lg),
                _buildFileTile(),
                if (_error != null) ...[
                  const SizedBox(height: AppDimensions.md),
                  Text(_error!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.danger)),
                ],
                if (_entries.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.xl),
                  _buildAccountPicker(accounts),
                  const SizedBox(height: AppDimensions.lg),
                  _buildMappingSection(),
                  const SizedBox(height: AppDimensions.lg),
                  _buildEntriesHeader(),
                  const SizedBox(height: AppDimensions.sm),
                  ..._buildEntryTiles(accounts),
                  const SizedBox(height: AppDimensions.xl),
                  _buildImportButton(),
                  const SizedBox(height: AppDimensions.xl),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Desde el archivo de tu banco',
              style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Descarga el extracto en CSV o Excel desde la app de tu banco y '
            'ábrelo aquí. Reconocemos las columnas solas, marcamos lo que ya '
            'tienes registrado y no se guarda nada hasta que lo confirmes.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTile() {
    return OutlinedButton.icon(
      onPressed: _isReading ? null : _pickFile,
      icon: _isReading
          ? const SizedBox(
              height: 16, width: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.upload_file_outlined),
      label: Text(_fileName ?? 'Elegir archivo CSV'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildAccountPicker(List<Account> accounts) {
    // Nothing can be booked without knowing which account the statement is
    // from — the file itself never says.
    return DropdownButtonFormField<String>(
      value: _accountId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Cuenta del extracto',
        prefixIcon: Icon(Icons.account_balance_outlined),
      ),
      items: [
        for (final a in accounts)
          DropdownMenuItem(
            value: a.id,
            child: Text('${a.icon}  ${a.name} · ${a.currency}',
                overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) => setState(() => _accountId = v),
      validator: (v) => v == null ? 'Elige la cuenta' : null,
    );
  }

  Widget _buildMappingSection() {
    final columns = <DropdownMenuItem<int>>[
      const DropdownMenuItem(value: -1, child: Text('—')),
      for (var i = 0; i < _statement.header.length; i++)
        DropdownMenuItem(
            value: i,
            child: Text(_statement.header[i], overflow: TextOverflow.ellipsis)),
    ];

    Widget picker(String label, int value, void Function(int) onChanged) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.sm),
        child: DropdownButtonFormField<int>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: label, isDense: true),
          items: columns,
          onChanged: (v) {
            if (v == null) return;
            onChanged(v);
            _rebuildEntries();
          },
        ),
      );
    }

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: AppDimensions.sm),
      title: Text('Columnas detectadas', style: AppTextStyles.labelLarge),
      subtitle: Text(
        'Ábrelo solo si algo quedó en la columna equivocada',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
      ),
      children: [
        picker('Fecha', _mapping.date,
            (v) => _mapping = _mapping.copyWith(date: v)),
        picker('Descripción', _mapping.description,
            (v) => _mapping = _mapping.copyWith(description: v)),
        picker('Monto (con signo)', _mapping.amount,
            (v) => _mapping = _mapping.copyWith(amount: v)),
        picker('Cargo / débito', _mapping.debit,
            (v) => _mapping = _mapping.copyWith(debit: v)),
        picker('Abono / crédito', _mapping.credit,
            (v) => _mapping = _mapping.copyWith(credit: v)),
      ],
    );
  }

  Widget _buildEntriesHeader() {
    final duplicates = _entries
        .where((e) => _existing.contains(e.fingerprint))
        .length;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_entries.length} movimientos leídos',
                  style: AppTextStyles.labelLarge),
              if (duplicates > 0)
                Text(
                  '$duplicates ya estaban registrados y quedaron desmarcados',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.warning),
                ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => setState(() {
            if (_selected.length == _entries.length) {
              _selected.clear();
            } else {
              _selected
                ..clear()
                ..addAll(List.generate(_entries.length, (i) => i));
            }
          }),
          child: Text(
              _selected.length == _entries.length ? 'Ninguno' : 'Todos'),
        ),
      ],
    );
  }

  List<Widget> _buildEntryTiles(List<Account> accounts) {
    final account = accounts.where((a) => a.id == _accountId).firstOrNull;
    final code = account?.currency;
    return [
      for (var i = 0; i < _entries.length; i++)
        _buildEntryTile(i, _entries[i], code),
    ];
  }

  Widget _buildEntryTile(int index, StatementEntry entry, String? code) {
    final isDuplicate = _existing.contains(entry.fingerprint);
    final isExpense = entry.type == TransactionType.expense;
    final category =
        CategoryMatcher.suggest(entry.description, type: entry.type);
    return CheckboxListTile(
      value: _selected.contains(index),
      onChanged: (checked) => setState(() {
        if (checked ?? false) {
          _selected.add(index);
        } else {
          _selected.remove(index);
        }
      }),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        entry.description.isEmpty ? 'Sin descripción' : entry.description,
        style: AppTextStyles.bodyMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          DateFormatter.formatShortDate(entry.date),
          if (category != null) category.label,
          if (isDuplicate) 'ya registrado',
        ].join(' · '),
        style: AppTextStyles.bodySmall.copyWith(
          color: isDuplicate ? AppColors.warning : AppColors.grey500,
        ),
      ),
      secondary: Text(
        '${isExpense ? '-' : '+'}'
        '${CurrencyFormatter.format(entry.amount, code: code)}',
        style: AppTextStyles.monoSmall.copyWith(
          color: isExpense ? AppColors.danger : AppColors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildImportButton() {
    final ready = _accountId != null && _selected.isNotEmpty && !_isImporting;
    final account = _accountsCubit.state.activeAccounts
        .where((a) => a.id == _accountId)
        .firstOrNull;
    return Column(
      children: [
        ElevatedButton(
          onPressed: ready ? _import : null,
          child: _isImporting
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.white))
              : Text('Importar ${_selected.length} movimientos'),
        ),
        if (account != null) ...[
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Se registrarán en ${account.name} y ajustarán su saldo en '
            '${Currency.byCode(account.currency).code}.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),
        ],
      ],
    );
  }
}
