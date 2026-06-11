import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme.dart';

// Brand identity (matches the purple landing). Auth is always purple so it feels
// like one continuous brand from the landing, regardless of the saved theme.
const _brandPrimary = Color(0xFF7C3AED);
const _brandDeep = Color(0xFF4C1D95);
const _brandAccent = Color(0xFFA855F7);
const _brandLilac = Color(0xFFC4B5FD);

/// Wraps auth pages with a split-screen layout on wide screens (≥ 800px)
/// and a plain scrollable card on mobile. Forces the purple brand theme so the
/// login/register flow is visually continuous with the landing.
class AuthLayout extends StatelessWidget {
  final Widget form;
  final bool isLogin;

  const AuthLayout({super.key, required this.form, this.isLogin = true});

  @override
  Widget build(BuildContext context) {
    final purpleTheme =
        AppTheme.light(AppColorPalette.fromType(AppColorSchemeType.purple));
    return Theme(
      data: purpleTheme,
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          return _WebLayout(form: form, isLogin: isLogin);
        }
        return _MobileLayout(form: form);
      }),
    );
  }
}

/// Back arrow that returns to wherever the user came from — pops if there is a
/// route to pop (e.g. login → register), otherwise goes to the landing.
class _BackButton extends StatelessWidget {
  final bool onDark;
  const _BackButton({this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final color = onDark ? Colors.white : _brandPrimary;
    return Material(
      color: onDark
          ? Colors.white.withOpacity(0.14)
          : _brandPrimary.withOpacity(0.08),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.canPop() ? context.pop() : context.go('/landing'),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(Icons.arrow_back_rounded, size: 20, color: color),
        ),
      ),
    );
  }
}

// ── Web split-screen ──────────────────────────────────────────────────────────

class _WebLayout extends StatelessWidget {
  final Widget form;
  final bool isLogin;
  const _WebLayout({required this.form, required this.isLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Row(
        children: [
          // ── Left brand panel ────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: _BrandPanel(isLogin: isLogin),
          ),
          // ── Right form panel ────────────────────────────────────────────
          Expanded(
            flex: 6,
            child: Container(
              color: AppColors.white,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 40,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: form,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  final bool isLogin;
  const _BrandPanel({required this.isLogin});

  static const _features = [
    (Icons.account_balance_wallet_outlined, 'Control total de tus cuentas'),
    (Icons.bar_chart_outlined, 'Reportes visuales e interactivos'),
    (Icons.savings_outlined, 'Metas de ahorro personalizadas'),
    (Icons.home_outlined, 'Gastos compartidos del hogar'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brandDeep, _brandPrimary, _brandAccent],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          _circle(top: -60, right: -40, size: 220, opacity: 0.06),
          _circle(bottom: -80, left: -60, size: 300, opacity: 0.06),
          _circle(top: 130, left: -30, size: 120, opacity: 0.05),
          // Back arrow
          Positioned(
            top: 28,
            left: 28,
            child: const _BackButton(onDark: true),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Logo
                Row(
                  children: [
                    Image.asset(
                      'assets/images/LogoFimakyp.png',
                      width: 44,
                      height: 44,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Fimakyp',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 2),

                // Headline
                Text(
                  isLogin
                      ? 'Bienvenido\nde vuelta'
                      : 'Tus finanzas,\nbajo control',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w800,
                    fontSize: 42,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isLogin
                      ? 'Retoma el control de tus finanzas personales.'
                      : 'Empieza hoy y toma decisiones financieras más inteligentes.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.78),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 48),

                // Feature list
                ..._features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.12)),
                            ),
                            child: Icon(f.$1, color: Colors.white, size: 19),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            f.$2,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )),

                const Spacer(flex: 3),

                // Footer
                Text(
                  '© 2026 Fimakyp · Finanzas inteligentes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(
          {double? top,
          double? bottom,
          double? left,
          double? right,
          required double size,
          required double opacity}) =>
      Positioned(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(opacity),
                _brandLilac.withOpacity(opacity * 0.6),
              ],
            ),
          ),
        ),
      );
}

// ── Mobile layout ─────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final Widget form;
  const _MobileLayout({required this.form});

  @override
  Widget build(BuildContext context) {
    // Show the back arrow when there is somewhere to go back to (register from
    // login), or always on web where the landing is the real entry point.
    final showBack = kIsWeb || context.canPop();
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBack) ...[
                const _BackButton(),
                const SizedBox(height: AppDimensions.sm),
              ],
              form,
            ],
          ),
        ),
      ),
    );
  }
}
