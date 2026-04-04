import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';

class SocialSignInButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const SocialSignInButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.isLoading = false,
  });

  factory SocialSignInButton.google({
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return SocialSignInButton(
      label: 'Continuar con Google',
      icon: const _GoogleIcon(),
      onTap: onTap,
      isLoading: isLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.grey900,
        side: const BorderSide(color: AppColors.grey300),
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: AppDimensions.sm),
                Text(label,
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 15)),
              ],
            ),
    );
  }
}

// ── Google logo rendered as a memory PNG (no asset file required) ─────────────
// PNG bytes of the Google multicolor "G" at 20×20, base64-decoded at build time.
// Generated from the official Google brand logo (public domain colors).

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  // 20×20 PNG of the Google "G" logo encoded in-memory.
  // We draw it with CustomPainter using the official brand colors.
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

/// Draws the Google "G" logo at any size using official brand colors.
/// Reference: https://developers.google.com/identity/branding-guidelines
class _GoogleLogoPainter extends CustomPainter {
  static const _blue   = Color(0xFF4285F4);
  static const _red    = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green  = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // Stroke width scales with size
    final sw = w * 0.22;
    final arcR = (w - sw) / 2;
    final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: arcR);

    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    // Red arc  (top-left, about 3π/4 sweep)
    p.color = _red;
    canvas.drawArc(arcRect, -2.356, 1.483, false, p);   // ~135° start, ~85°

    // Yellow arc (bottom-left)
    p.color = _yellow;
    canvas.drawArc(arcRect, -0.873, 1.658, false, p);   // ~50° → ~95°

    // Green arc (bottom-right)
    p.color = _green;
    canvas.drawArc(arcRect, 0.785, 1.396, false, p);

    // Blue arc (top-right + right side)
    p.color = _blue;
    canvas.drawArc(arcRect, 2.181, 1.920, false, p);

    // ── Horizontal bar of the "G" ────────────────────────────────────────
    final barTop    = cy - sw * 0.45;
    final barBottom = cy + sw * 0.45;
    final barLeft   = cx - sw * 0.1;
    final barRight  = cx + arcR + sw * 0.45;

    // White mask to cut through the arc
    canvas.drawRect(
      Rect.fromLTRB(barLeft, barTop, barRight + 2, barBottom),
      Paint()..color = Colors.white,
    );
    // Blue fill for the bar
    canvas.drawRect(
      Rect.fromLTRB(barLeft, barTop, barRight, barBottom),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
