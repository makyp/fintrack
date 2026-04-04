import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

/// Wraps auth pages with a split-screen layout on wide screens (≥ 800px)
/// and a plain scrollable card on mobile.
class AuthLayout extends StatelessWidget {
  final Widget form;
  final bool isLogin;

  const AuthLayout({super.key, required this.form, this.isLogin = true});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 800) {
        return _WebLayout(form: form, isLogin: isLogin);
      }
      return _MobileLayout(form: form);
    });
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
      backgroundColor: AppColors.grey50,
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
          colors: [
            Color(0xFF1A3F6F),
            Color(0xFF2563EB),
            Color(0xFF1D4ED8),
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: const Icon(Icons.account_balance_wallet,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'FinTrack',
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
                    color: Colors.white.withOpacity(0.75),
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
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child:
                                Icon(f.$1, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            f.$2,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.88),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )),

                const Spacer(flex: 3),

                // Footer
                Text(
                  '© 2025 FinTrack · Finanzas inteligentes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.4),
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

// ── Mobile layout ─────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final Widget form;
  const _MobileLayout({required this.form});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pagePadding),
          child: form,
        ),
      ),
    );
  }
}
