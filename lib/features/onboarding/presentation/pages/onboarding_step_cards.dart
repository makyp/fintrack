import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';

class OnboardingStepCards extends StatefulWidget {
  final List<Map<String, dynamic>> cards;

  const OnboardingStepCards({super.key, required this.cards});

  @override
  State<OnboardingStepCards> createState() => _OnboardingStepCardsState();
}

class _OnboardingStepCardsState extends State<OnboardingStepCards> {
  void _addCard() {
    setState(() {
      widget.cards.add({'name': '', 'balance': 0.0, 'type': 'credito'});
    });
  }

  void _removeCard(int index) {
    setState(() => widget.cards.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.lg),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.creditColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.credit_card_outlined,
              size: 56,
              color: AppColors.creditColor,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          Text('Agrega tus tarjetas', style: AppTextStyles.displaySmall),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Registra tus tarjetas de crédito o débito. Para crédito, ingresa el saldo que debes actualmente.',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: AppDimensions.xl),
          if (widget.cards.isEmpty)
            _buildEmptyState()
          else
            ...widget.cards.asMap().entries.map(
                  (e) => _CardTile(
                    data: e.value,
                    onRemove: () => _removeCard(e.key),
                  ),
                ),
          const SizedBox(height: AppDimensions.md),
          OutlinedButton.icon(
            onPressed: _addCard,
            icon: const Icon(Icons.add),
            label: const Text('Agregar tarjeta'),
          ),
          const SizedBox(height: AppDimensions.lg),
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    '¡Ya casi terminaste! Al finalizar podrás ver tu patrimonio neto consolidado.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.credit_card_outlined, size: 40, color: AppColors.grey400),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Sin tarjetas aún',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
          ),
          Text(
            'Puedes agregarlas después',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey400),
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onRemove;
  const _CardTile({required this.data, required this.onRemove});

  @override
  State<_CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<_CardTile> {
  String _type = 'credito';

  @override
  void initState() {
    super.initState();
    _type = widget.data['type'] as String? ?? 'credito';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          children: [
            Row(
              children: [
                Text('Tarjeta', style: AppTextStyles.labelLarge),
                const Spacer(),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.close, size: 18),
                  color: AppColors.grey400,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            TextFormField(
              initialValue: widget.data['name'] as String?,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre / Banco',
                hintText: 'Ej: Visa Bancolombia',
              ),
              onChanged: (v) => widget.data['name'] = v,
            ),
            const SizedBox(height: AppDimensions.sm),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const [
                DropdownMenuItem(value: 'credito', child: Text('Tarjeta de crédito')),
                DropdownMenuItem(value: 'debito', child: Text('Tarjeta de débito')),
              ],
              onChanged: (v) {
                setState(() => _type = v ?? 'credito');
                widget.data['type'] = _type;
              },
            ),
            const SizedBox(height: AppDimensions.sm),
            TextFormField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              decoration: InputDecoration(
                labelText: _type == 'credito'
                    ? 'Deuda actual (saldo a pagar)'
                    : 'Saldo disponible',
                prefixText: '\$ ',
              ),
              onChanged: (v) => widget.data['balance'] = double.tryParse(v) ?? 0.0,
            ),
          ],
        ),
      ),
    );
  }
}
