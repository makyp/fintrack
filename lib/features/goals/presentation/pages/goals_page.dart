import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/savings_goal.dart';
import '../cubit/goals_cubit.dart';
import 'goal_form_page.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthBloc>().state.user?.uid ?? '';
    return BlocProvider(
      create: (_) => getIt<GoalsCubit>()..watch(userId),
      child: const _GoalsView(),
    );
  }
}

class _GoalsView extends StatelessWidget {
  const _GoalsView();

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthBloc>().state.user?.uid ?? '';
    return BlocConsumer<GoalsCubit, GoalsState>(
      listener: (context, state) {
        if (state.status == GoalsStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Error'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Metas de Ahorro')),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.goals.isEmpty
                  ? _buildEmpty(context, userId)
                  : _buildList(context, state.goals, userId),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context, userId),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            icon: const Icon(Icons.add),
            label: const Text('Nueva meta'),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context, String userId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 64)),
          const SizedBox(height: AppDimensions.md),
          Text('Sin metas aún',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: AppColors.grey500)),
          const SizedBox(height: AppDimensions.sm),
          Text('Crea tu primera meta de ahorro',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.grey400)),
          const SizedBox(height: AppDimensions.xl),
          ElevatedButton.icon(
            onPressed: () => _openForm(context, userId),
            icon: const Icon(Icons.add),
            label: const Text('Crear meta'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      BuildContext context, List<SavingsGoal> goals, String userId) {
    final active = goals.where((g) => !g.isCompleted).toList();
    final completed = goals.where((g) => g.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding, AppDimensions.md,
          AppDimensions.pagePadding, 100),
      children: [
        if (active.isNotEmpty) ...[
          Text('En progreso', style: AppTextStyles.labelLarge
              .copyWith(color: AppColors.grey500)),
          const SizedBox(height: AppDimensions.sm),
          ...active.map((g) => _GoalCard(goal: g, userId: userId)),
        ],
        if (completed.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.lg),
          Text('Completadas', style: AppTextStyles.labelLarge
              .copyWith(color: AppColors.grey500)),
          const SizedBox(height: AppDimensions.sm),
          ...completed.map((g) => _GoalCard(goal: g, userId: userId)),
        ],
      ],
    );
  }

  void _openForm(BuildContext context, String userId, [SavingsGoal? goal]) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => BlocProvider.value(
        value: context.read<GoalsCubit>(),
        child: GoalFormPage(userId: userId, goal: goal),
      ),
    ));
  }
}

// ── Goal Card ──────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final String userId;

  const _GoalCard({required this.goal, required this.userId});

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress;
    final color = goal.isCompleted ? AppColors.success : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showOptions(context),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(goal.icon,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.name,
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (goal.targetDate != null)
                          Text(
                            _dateLabel(goal),
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.grey500),
                          ),
                      ],
                    ),
                  ),
                  if (goal.isCompleted)
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 20)
                  else
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: AppTextStyles.labelLarge.copyWith(color: color),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.grey100,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyFormatter.format(goal.currentAmount),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey600),
                  ),
                  Text(
                    CurrencyFormatter.format(goal.targetAmount),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey400),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(SavingsGoal g) {
    final days = g.daysLeft;
    if (days == null) return '';
    if (days < 0) return 'Vencida';
    if (days == 0) return 'Vence hoy';
    if (days == 1) return 'Vence mañana';
    return 'Vence en $days días';
  }

  void _showOptions(BuildContext context) {
    final userId = this.userId;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => BlocProvider.value(
        value: context.read<GoalsCubit>(),
        child: _GoalOptionsSheet(goal: goal, userId: userId),
      ),
    );
  }
}

// ── Options sheet ──────────────────────────────────────────────────────────────

class _GoalOptionsSheet extends StatelessWidget {
  final SavingsGoal goal;
  final String userId;

  const _GoalOptionsSheet({required this.goal, required this.userId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppDimensions.sm),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: AppDimensions.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding),
            child: Row(
              children: [
                Text(goal.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: AppDimensions.sm),
                Text(goal.name, style: AppTextStyles.headlineSmall),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          if (!goal.isCompleted) ...[
            ListTile(
              leading: const Icon(Icons.add_circle_outline,
                  color: AppColors.success),
              title: const Text('Agregar aportación'),
              onTap: () {
                Navigator.pop(context);
                _showContributionDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined,
                  color: AppColors.primary),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => BlocProvider.value(
                    value: context.read<GoalsCubit>(),
                    child: GoalFormPage(userId: userId, goal: goal),
                  ),
                ));
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.danger),
            title: const Text('Eliminar'),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context);
            },
          ),
          const SizedBox(height: AppDimensions.sm),
        ],
      ),
    );
  }

  void _showContributionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: context.read<GoalsCubit>(),
        child: _ContributionDialog(goal: goal, userId: userId),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar meta'),
        content: Text('¿Eliminar "${goal.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<GoalsCubit>().delete(userId, goal.id);
            },
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ── Contribution dialog ────────────────────────────────────────────────────────

class _ContributionDialog extends StatefulWidget {
  final SavingsGoal goal;
  final String userId;

  const _ContributionDialog({required this.goal, required this.userId});

  @override
  State<_ContributionDialog> createState() => _ContributionDialogState();
}

class _ContributionDialogState extends State<_ContributionDialog> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Aportación a ${widget.goal.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Falta: ${CurrencyFormatter.format(widget.goal.remaining)}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: AppDimensions.sm),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            ],
            decoration: const InputDecoration(
              labelText: 'Monto',
              prefixText: '\$ ',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Agregar'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_ctrl.text) ?? 0;
    if (amount <= 0) return;
    setState(() => _loading = true);
    try {
      final updated = await context
          .read<GoalsCubit>()
          .addContribution(widget.userId, widget.goal.id, amount);
      if (!mounted) return;
      Navigator.pop(context);
      if (updated != null && updated.isReached) {
        _showCelebration(context, updated);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Celebration dialog (UC-22) ─────────────────────────────────────────────────

void _showCelebration(BuildContext context, SavingsGoal goal) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CelebrationDialog(goal: goal),
  );
}

class _CelebrationDialog extends StatefulWidget {
  final SavingsGoal goal;
  const _CelebrationDialog({required this.goal});

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog>
    with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final AnimationController _confettiCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _scaleAnim = CurvedAnimation(
        parent: _scaleCtrl, curve: Curves.elasticOut);
    _scaleCtrl.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Stack(
        children: [
          // Confetti background
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 360,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _confettiCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _ConfettiPainter(_confettiCtrl.value),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scaleAnim,
                  child: const Text('🏆', style: TextStyle(fontSize: 72)),
                ),
                const SizedBox(height: AppDimensions.md),
                Text('¡Meta alcanzada!',
                    style: AppTextStyles.headlineSmall
                        .copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: AppDimensions.sm),
                Text(
                  widget.goal.name,
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.grey600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  CurrencyFormatter.format(widget.goal.targetAmount),
                  style: AppTextStyles.displaySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('¡Celebrar! 🎉'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Confetti painter ───────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final double progress;
  static final _rng = math.Random(42);
  static final _particles = List.generate(60, (_) => _Particle(_rng));

  _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final y = (p.startY + progress * size.height * p.speed) % size.height;
      final x = p.startX * size.width +
          math.sin(progress * math.pi * 2 * p.wobble + p.phase) * 20;
      final paint = Paint()..color = p.color.withOpacity(0.7);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * math.pi * 4 * p.rotSpeed);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _Particle {
  late double startX;
  late double startY;
  late double speed;
  late double wobble;
  late double phase;
  late double rotSpeed;
  late double size;
  late Color color;

  static const _colors = [
    AppColors.primary,
    AppColors.success,
    AppColors.warning,
    AppColors.danger,
    Color(0xFF7C3AED),
    Color(0xFFEC4899),
    Color(0xFF0891B2),
  ];

  _Particle(math.Random rng) {
    startX = rng.nextDouble();
    startY = rng.nextDouble() * -1.0;
    speed = 0.3 + rng.nextDouble() * 0.5;
    wobble = 0.5 + rng.nextDouble();
    phase = rng.nextDouble() * math.pi * 2;
    rotSpeed = 0.5 + rng.nextDouble() * 2;
    size = 6.0 + rng.nextDouble() * 8;
    color = _colors[rng.nextInt(_colors.length)];
  }
}
