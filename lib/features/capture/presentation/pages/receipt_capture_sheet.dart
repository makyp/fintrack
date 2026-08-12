import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/receipt_ocr_service.dart';
import '../../domain/entities/transaction_draft.dart';
import '../../domain/parsers/receipt_parser.dart';
import '../widgets/draft_preview_card.dart';

/// Bottom sheet that photographs a receipt, reads it with on-device OCR and
/// returns a [TransactionDraft].
///
/// Pops with the draft when the user confirms, or `null` if they back out.
class ReceiptCaptureSheet extends StatefulWidget {
  const ReceiptCaptureSheet({super.key});

  static Future<TransactionDraft?> show(BuildContext context) {
    return showModalBottomSheet<TransactionDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ReceiptCaptureSheet(),
    );
  }

  @override
  State<ReceiptCaptureSheet> createState() => _ReceiptCaptureSheetState();
}

enum _Stage { chooseSource, reading, result, failed, blocked }

class _ReceiptCaptureSheetState extends State<ReceiptCaptureSheet> {
  final _ocr = ReceiptOcrService();

  _Stage _stage = _Stage.chooseSource;
  TransactionDraft? _draft;
  Uint8List? _preview;
  String _error = '';

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _capture(ReceiptImageSource source) async {
    final isCamera = source == ReceiptImageSource.camera;

    // Ask before opening anything, so a refusal is explained rather than
    // looking like the picker failed.
    final access = await _ocr.requestAccess(source);
    if (!mounted) return;
    if (access != CaptureAccess.granted) {
      setState(() {
        if (access == CaptureAccess.blocked) {
          _stage = _Stage.blocked;
          _error = isCamera
              ? 'El permiso de cámara está bloqueado. Actívalo en los ajustes '
                  'del sistema para poder fotografiar recibos.'
              : 'El permiso de fotos está bloqueado. Actívalo en los ajustes '
                  'del sistema para poder elegir un recibo de la galería.';
        } else {
          _stage = _Stage.failed;
          _error = isCamera
              ? 'Sin permiso de cámara no puedo tomar la foto del recibo.'
              : 'Sin permiso de fotos no puedo abrir tu galería.';
        }
      });
      return;
    }

    try {
      final image = await _ocr.pickImage(source);
      if (image == null || !mounted) return; // user cancelled

      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _preview = bytes;
        _stage = _Stage.reading;
      });

      final text = await _ocr.recognize(image);
      if (!mounted) return;

      if (text.trim().isEmpty) {
        setState(() {
          _stage = _Stage.failed;
          _error = 'No pude leer texto en esa foto. Intenta con más luz, sin '
              'sombras y con el recibo plano.';
        });
        return;
      }

      setState(() {
        _draft = ReceiptParser.parse(text);
        _stage = _Stage.result;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.failed;
        _error = 'No pude procesar la imagen. Puedes intentar de nuevo o '
            'registrar el movimiento a mano.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: AppDimensions.pagePadding,
        right: AppDimensions.pagePadding,
        top: AppDimensions.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppDimensions.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            switch (_stage) {
              _Stage.chooseSource => _buildChooseSource(),
              _Stage.reading => _buildReading(),
              _Stage.result => _buildResult(),
              _Stage.failed => _buildFailed(),
              _Stage.blocked => _buildBlocked(),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildChooseSource() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Foto del recibo', style: AppTextStyles.headlineSmall),
        const SizedBox(height: AppDimensions.xs),
        Text(
          'Leo el total en tu teléfono. La foto no sale de aquí.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
        ),
        const SizedBox(height: AppDimensions.lg),
        _sourceButton(
          icon: Icons.photo_camera_outlined,
          title: 'Tomar foto',
          subtitle: 'Enfoca el recibo completo',
          onTap: () => _capture(ReceiptImageSource.camera),
        ),
        const SizedBox(height: AppDimensions.sm),
        _sourceButton(
          icon: Icons.photo_library_outlined,
          title: 'Elegir de la galería',
          subtitle: 'Usa una foto que ya tomaste',
          onTap: () => _capture(ReceiptImageSource.gallery),
        ),
        const SizedBox(height: AppDimensions.md),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _sourceButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: primary, size: 26),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  Text(subtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }

  Widget _buildReading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_preview != null) _thumbnail(),
        const SizedBox(height: AppDimensions.lg),
        const CircularProgressIndicator(),
        const SizedBox(height: AppDimensions.md),
        Text('Leyendo el recibo…', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppDimensions.xs),
        Text(
          'La primera vez puede tardar unos segundos.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
        ),
        const SizedBox(height: AppDimensions.lg),
      ],
    );
  }

  Widget _buildResult() {
    final draft = _draft!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Text('Esto leí', style: AppTextStyles.headlineSmall)),
        const SizedBox(height: AppDimensions.md),
        if (_preview != null) ...[
          Center(child: _thumbnail()),
          const SizedBox(height: AppDimensions.md),
        ],
        if (!draft.hasAmount)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.md),
            margin: const EdgeInsets.only(bottom: AppDimensions.sm),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Text(
              'No encontré el total. Revisa el monto en el formulario antes '
              'de guardar.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey700),
            ),
          ),
        DraftPreviewCard(draft: draft),
        const SizedBox(height: AppDimensions.sm),
        Text(
          'Verifica el total contra el recibo: la lectura puede fallar.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
        ),
        const SizedBox(height: AppDimensions.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _stage = _Stage.chooseSource),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Otra foto'),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(draft),
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Permanently denied: retrying the prompt does nothing, so the only useful
  /// action is a shortcut to the system settings.
  Widget _buildBlocked() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_outline, size: 40, color: AppColors.grey400),
        const SizedBox(height: AppDimensions.md),
        Text('Permiso bloqueado', style: AppTextStyles.headlineSmall),
        const SizedBox(height: AppDimensions.sm),
        Text(
          _error,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey700),
        ),
        const SizedBox(height: AppDimensions.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _stage = _Stage.chooseSource),
                child: const Text('Volver'),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: ElevatedButton(
                onPressed: _ocr.openSettings,
                child: const Text('Abrir ajustes'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFailed() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.image_not_supported_outlined,
            size: 40, color: AppColors.grey400),
        const SizedBox(height: AppDimensions.md),
        Text('No pude leerlo', style: AppTextStyles.headlineSmall),
        const SizedBox(height: AppDimensions.sm),
        Text(
          _error,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey700),
        ),
        const SizedBox(height: AppDimensions.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _stage = _Stage.chooseSource),
                child: const Text('Reintentar'),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .pop(const TransactionDraft(source: CaptureSource.manual)),
                child: const Text('Escribirlo'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _thumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Image.memory(
        _preview!,
        height: 120,
        fit: BoxFit.cover,
      ),
    );
  }
}
