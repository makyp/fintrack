import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' show LocaleName;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/speech_capture_service.dart';
import '../../domain/entities/transaction_draft.dart';
import '../../domain/parsers/voice_transaction_parser.dart';
import '../widgets/draft_preview_card.dart';

/// Bottom sheet that listens to the user and turns what they said into a
/// [TransactionDraft].
///
/// Pops with the draft when the user confirms, or with `null` if they back
/// out. Nothing is saved here — the caller opens the form with the draft.
class VoiceCaptureSheet extends StatefulWidget {
  const VoiceCaptureSheet({super.key});

  /// Opens the sheet and returns the confirmed draft, if any.
  static Future<TransactionDraft?> show(BuildContext context) {
    return showModalBottomSheet<TransactionDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceCaptureSheet(),
    );
  }

  @override
  State<VoiceCaptureSheet> createState() => _VoiceCaptureSheetState();
}

enum _Stage { starting, listening, result, unavailable }

class _VoiceCaptureSheetState extends State<VoiceCaptureSheet>
    with SingleTickerProviderStateMixin {
  final _speech = SpeechCaptureService();
  late final AnimationController _pulse;

  _Stage _stage = _Stage.starting;
  String _transcript = '';
  double _level = 0;
  TransactionDraft? _draft;

  /// The language the recognizer is actually listening in.
  LocaleName? _locale;

  /// True when the device has no Spanish recognizer installed at all.
  bool _missingSpanish = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _startListening();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _stage = _Stage.starting;
      _transcript = '';
      _draft = null;
    });

    final ready = await _speech.initialize(onDone: _onRecognizerDone);
    if (!mounted) return;
    if (!ready) {
      setState(() => _stage = _Stage.unavailable);
      return;
    }

    // Resolve the language before listening so the label never lies about
    // what the recognizer is doing.
    final locale = await _speech.activeLocale();
    final hasSpanish = await _speech.hasSpanish();
    if (!mounted) return;
    setState(() {
      _locale = locale;
      _missingSpanish = !hasSpanish;
    });

    await _speech.start(
      onResult: (transcript, isFinal) {
        if (!mounted) return;
        setState(() => _transcript = transcript);
        if (isFinal) _finish();
      },
      onSoundLevel: (level) {
        if (!mounted) return;
        // Android reports roughly -2..10; normalize to 0..1 for the pulse.
        setState(() => _level = (level.clamp(0, 10)) / 10);
      },
    );
    if (mounted) setState(() => _stage = _Stage.listening);
  }

  /// The recognizer released the mic on its own (silence timeout).
  void _onRecognizerDone() {
    if (!mounted || _stage != _Stage.listening) return;
    _finish();
  }

  void _finish() {
    if (!mounted || _stage == _Stage.result) return;
    _speech.stop();
    final text = _transcript.trim();
    setState(() {
      _draft = VoiceTransactionParser.parse(text);
      _stage = _Stage.result;
    });
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
          if (_stage == _Stage.unavailable)
            _buildUnavailable()
          else if (_stage == _Stage.result)
            _buildResult()
          else
            _buildListening(),
        ],
      ),
    );
  }

  Widget _buildListening() {
    final primary = Theme.of(context).colorScheme.primary;
    final isStarting = _stage == _Stage.starting;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isStarting ? 'Preparando el micrófono…' : 'Te escucho',
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          'Di el monto y en qué fue',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
        ),
        const SizedBox(height: AppDimensions.sm),
        _buildLocaleChip(),
        if (_missingSpanish) ...[
          const SizedBox(height: AppDimensions.sm),
          _buildMissingSpanishNotice(),
        ],
        const SizedBox(height: AppDimensions.md),
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            // The ring breathes on its own and swells with the voice level, so
            // the user can tell the mic is actually picking them up.
            final scale = 1 + (_pulse.value * 0.08) + (_level * 0.25);
            return Container(
              width: 108 * scale,
              height: 108 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withOpacity(0.12),
              ),
              child: child,
            );
          },
          child: Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(shape: BoxShape.circle, color: primary),
              child: const Icon(Icons.mic, color: AppColors.white, size: 34),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.lg),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: _transcript.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Por ejemplo:',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.grey500)),
                    const SizedBox(height: 4),
                    Text('«gasté 25 mil en almuerzo»',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.grey700)),
                    Text('«me pagaron el salario dos millones»',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.grey700)),
                  ],
                )
              : Text(_transcript, style: AppTextStyles.bodyLarge),
        ),
        const SizedBox(height: AppDimensions.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: ElevatedButton(
                onPressed: isStarting ? null : _finish,
                child: const Text('Listo'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Shows the language in use and lets the user change it — the recognizer
  /// often defaults to the phone's system language, which is not necessarily
  /// the one they speak to the app in.
  Widget _buildLocaleChip() {
    final primary = Theme.of(context).colorScheme.primary;
    final label = _locale?.name ?? 'Idioma del sistema';

    return InkWell(
      onTap: _pickLocale,
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: primary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 15, color: primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.expand_more, size: 16, color: primary),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingSpanishNotice() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(
        'Tu teléfono no tiene español instalado para dictado. Instálalo en '
        'Ajustes › Idiomas › Reconocimiento de voz para que te entienda.',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey700),
      ),
    );
  }

  /// Lets the user choose among the languages the device actually has.
  Future<void> _pickLocale() async {
    final locales = await _speech.availableLocales();
    if (!mounted) return;

    if (locales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El teléfono no reportó idiomas de dictado'),
        ),
      );
      return;
    }

    await _speech.cancel();
    if (!mounted) return;

    final chosen = await showModalBottomSheet<LocaleName>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => _LocalePicker(
        locales: locales,
        selectedId: _locale?.localeId,
      ),
    );
    if (chosen == null || !mounted) return;

    await _speech.setPreferredLocale(chosen.localeId);
    if (!mounted) return;
    setState(() => _locale = chosen);
    await _startListening();
  }

  Widget _buildResult() {
    final draft = _draft!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text('Esto entendí', style: AppTextStyles.headlineSmall),
        ),
        const SizedBox(height: AppDimensions.md),
        if (draft.rawText.isNotEmpty) ...[
          Text('«${draft.rawText}»',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.grey500,
                fontStyle: FontStyle.italic,
              )),
          const SizedBox(height: AppDimensions.md),
        ],
        if (draft.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Text(
              'No alcancé a entender un monto. Puedes repetirlo o abrir el '
              'formulario y escribirlo.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey700),
            ),
          )
        else
          DraftPreviewCard(draft: draft),
        const SizedBox(height: AppDimensions.sm),
        Text(
          'Podrás revisar y ajustar todo antes de guardar.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
        ),
        const SizedBox(height: AppDimensions.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _startListening,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Repetir'),
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

  Widget _buildUnavailable() {
    final failure = _speech.lastFailure;
    final message = failure == SpeechFailure.permissionDenied
        ? 'Necesito permiso del micrófono para escucharte. Actívalo en los '
            'ajustes del teléfono y vuelve a intentar.'
        : 'Este dispositivo no tiene reconocimiento de voz disponible. Puedes '
            'registrar el movimiento a mano.';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mic_off_outlined, size: 40, color: AppColors.grey400),
        const SizedBox(height: AppDimensions.md),
        Text('No puedo escucharte', style: AppTextStyles.headlineSmall),
        const SizedBox(height: AppDimensions.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey700),
        ),
        const SizedBox(height: AppDimensions.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _startListening,
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
}

/// Lists the dictation languages the device reports, Spanish variants first.
class _LocalePicker extends StatelessWidget {
  final List<LocaleName> locales;
  final String? selectedId;

  const _LocalePicker({required this.locales, this.selectedId});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              children: [
                Text('Idioma del dictado', style: AppTextStyles.headlineSmall),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  'Solo aparecen los idiomas que tu teléfono tiene instalados',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey500),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: locales.length,
              itemBuilder: (context, index) {
                final locale = locales[index];
                final isSelected = locale.localeId == selectedId;
                return ListTile(
                  title: Text(locale.name),
                  subtitle: Text(
                    locale.localeId,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey500),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(locale),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
