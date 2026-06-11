import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  FIMAKYP · Landing (web) — identidad morada, animada y con movimiento
// ═══════════════════════════════════════════════════════════════════════════

// ── Paleta morada ──────────────────────────────────────────────────────────
const _primary = Color(0xFF7C3AED);
const _primaryDk = Color(0xFF5B21B6);
const _primaryDeep = Color(0xFF4C1D95);
const _accent = Color(0xFFA855F7);
const _violet = Color(0xFF8B5CF6);
const _lilac = Color(0xFFC4B5FD);
const _lilacLt = Color(0xFFDDD6FE);
const _tint = Color(0xFFF5F0FF);
const _tint2 = Color(0xFFFAF7FF);
const _ink = Color(0xFF1B1533);
const _grey = Color(0xFF6E6A85);
const _greyLt = Color(0xFFA09CB8);
const _dark = Color(0xFF160A33);
const _darkAlt = Color(0xFF271252);
const _border = Color(0xFFEDE7F8);

// ── Tipografía (igual que la app: Montserrat + Inter) ──────────────────────
TextStyle _h(double size,
        {FontWeight w = FontWeight.w800,
        Color color = _ink,
        double height = 1.14,
        double ls = -0.6}) =>
    GoogleFonts.montserrat(
        fontSize: size, fontWeight: w, color: color, height: height, letterSpacing: ls);

TextStyle _b(double size,
        {FontWeight w = FontWeight.w400, Color color = _grey, double height = 1.6}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: w, color: color, height: height);

// ── Helpers responsive ─────────────────────────────────────────────────────
bool _isMobile(BuildContext c) => MediaQuery.of(c).size.width < 900;
double _hPad(BuildContext c) => _isMobile(c) ? 20 : 72;

// ── Scroll en web (mouse/touch) ─────────────────────────────────────────────
class _WebBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
      };
}

// ═══════════════════════════════════════════════════════════════════════════
//  LandingPage
// ═══════════════════════════════════════════════════════════════════════════
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scroll = ScrollController();
  final _aboutKey = GlobalKey();
  final _benefitsKey = GlobalKey();
  final _modulesKey = GlobalKey();
  final _featuresKey = GlobalKey();
  bool _shadowed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final s = _scroll.offset > 12;
    if (s != _shadowed) setState(() => _shadowed = s);
  }

  void _go(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: _Navbar(
          shadowed: _shadowed,
          onAbout: () => _go(_aboutKey),
          onBenefits: () => _go(_benefitsKey),
          onModules: () => _go(_modulesKey),
          onFeatures: () => _go(_featuresKey),
        ),
      ),
      body: ScrollConfiguration(
        behavior: _WebBehavior(),
        child: _ScrollScope(
          controller: _scroll,
          child: SingleChildScrollView(
            controller: _scroll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Hero(),
                _AboutSection(key: _aboutKey),
                _BenefitsSection(key: _benefitsKey),
                _ModulesSection(key: _modulesKey),
                _FeaturesSection(key: _featuresKey),
                const _StatsSection(),
                const _CtaSection(),
                const _Footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Reveal-on-scroll  (fade + slide cuando la sección entra a pantalla)
// ═══════════════════════════════════════════════════════════════════════════
class _ScrollScope extends InheritedWidget {
  final ScrollController controller;
  const _ScrollScope({required this.controller, required super.child});
  static ScrollController of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<_ScrollScope>()!.controller;
  @override
  bool updateShouldNotify(_ScrollScope old) => old.controller != controller;
}

class _Reveal extends StatefulWidget {
  final Widget child;
  final double dy;
  final Duration delay;
  const _Reveal({required this.child, this.dy = 44, this.delay = Duration.zero});
  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  ScrollController? _scroll;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 680));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scroll = _ScrollScope.of(context)..addListener(_check);
      _check();
    });
  }

  void _check() {
    if (_shown || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final dy = box.localToGlobal(Offset.zero).dy;
    final screenH = MediaQuery.of(context).size.height;
    if (dy < screenH - 70) {
      _shown = true;
      _scroll?.removeListener(_check);
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _scroll?.removeListener(_check);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curve,
      builder: (_, child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
            offset: Offset(0, (1 - curve.value) * widget.dy), child: child),
      ),
      child: widget.child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Navbar
// ═══════════════════════════════════════════════════════════════════════════
class _Navbar extends StatelessWidget {
  final bool shadowed;
  final VoidCallback onAbout, onBenefits, onModules, onFeatures;
  const _Navbar({
    required this.shadowed,
    required this.onAbout,
    required this.onBenefits,
    required this.onModules,
    required this.onFeatures,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 66,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(shadowed ? 0.92 : 1),
        boxShadow: shadowed
            ? [
                BoxShadow(
                    color: _primary.withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 4))
              ]
            : const [],
      ),
      padding: EdgeInsets.symmetric(horizontal: _hPad(context)),
      child: Row(
        children: [
          _Logo(size: 30, color: _primary, textColor: _ink),
          if (!mobile) ...[
            const SizedBox(width: 40),
            _NavLink('Nosotros', onAbout),
            _NavLink('Beneficios', onBenefits),
            _NavLink('Módulos', onModules),
            _NavLink('Características', onFeatures),
          ],
          const Spacer(),
          _GhostButton(
            label: 'Iniciar sesión',
            onTap: () => context.go('/login'),
            compact: true,
          ),
          if (!mobile) ...[
            const SizedBox(width: 12),
            _PrimaryButton(
              label: 'Comenzar gratis',
              icon: Icons.arrow_forward_rounded,
              onTap: () => context.go('/register'),
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final double size;
  final Color color;
  final Color textColor;
  const _Logo({required this.size, required this.color, required this.textColor});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/LogoFimakyp.png',
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_primary, _accent]),
                shape: BoxShape.circle),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 10),
        Text('Fimakyp',
            style: GoogleFonts.montserrat(
                fontSize: 19, fontWeight: FontWeight.w800, color: textColor)),
      ],
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink(this.label, this.onTap);
  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label,
                  style: _b(14,
                      w: _h ? FontWeight.w700 : FontWeight.w500,
                      color: _h ? _primary : _grey)),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2,
                width: _h ? 18 : 0,
                decoration: BoxDecoration(
                    color: _primary, borderRadius: BorderRadius.circular(2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Botones
// ═══════════════════════════════════════════════════════════════════════════
class _PrimaryButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool compact;
  const _PrimaryButton(
      {required this.label, this.icon, required this.onTap, this.compact = false});
  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _h ? -2 : 0, 0),
          padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 20 : 28,
              vertical: widget.compact ? 12 : 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_primary, _accent]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: _primary.withOpacity(_h ? 0.45 : 0.28),
                  blurRadius: _h ? 28 : 16,
                  offset: Offset(0, _h ? 10 : 6)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label,
                  style: _b(widget.compact ? 13.5 : 15,
                      w: FontWeight.w700, color: Colors.white)),
              if (widget.icon != null) ...[
                const SizedBox(width: 8),
                Icon(widget.icon, color: Colors.white, size: widget.compact ? 16 : 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool compact;
  final bool onDark;
  const _GhostButton(
      {required this.label,
      this.icon,
      required this.onTap,
      this.compact = false,
      this.onDark = false});
  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final base = widget.onDark ? Colors.white : _primary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 18 : 26,
              vertical: widget.compact ? 11 : 15),
          decoration: BoxDecoration(
            color: _h ? base.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: base.withOpacity(_h ? 0.9 : 0.5), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: base, size: widget.compact ? 16 : 18),
                const SizedBox(width: 8),
              ],
              Text(widget.label,
                  style: _b(widget.compact ? 13.5 : 15,
                      w: FontWeight.w700, color: base)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Badge / tag ─────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String text;
  final bool onDark;
  const _Tag(this.text, {this.onDark = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withOpacity(0.10) : _primary.withOpacity(0.09),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
            color: onDark ? Colors.white.withOpacity(0.22) : _primary.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
                color: onDark ? _lilac : _primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(text.toUpperCase(),
              style: _b(11.5,
                  w: FontWeight.w700,
                  color: onDark ? _lilacLt : _primaryDk)),
        ],
      ),
    );
  }
}

// ── Forma decorativa (blob) ─────────────────────────────────────────────────
class _Blob extends StatelessWidget {
  final double size;
  final List<Color> colors;
  final double opacity;
  const _Blob({required this.size, required this.colors, this.opacity = 0.5});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
            colors: colors.map((c) => c.withOpacity(opacity)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(
              color: colors.first.withOpacity(opacity * 0.6),
              blurRadius: 80,
              spreadRadius: 20),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Encabezado de sección reutilizable
// ═══════════════════════════════════════════════════════════════════════════
class _SectionHead extends StatelessWidget {
  final String tag;
  final String titleStart;
  final String titleAccent;
  final String? titleEnd;
  final String subtitle;
  final bool onDark;
  const _SectionHead({
    required this.tag,
    required this.titleStart,
    required this.titleAccent,
    this.titleEnd,
    required this.subtitle,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile(context);
    final tStyle = _h(mobile ? 28 : 38,
        color: onDark ? Colors.white : _ink, height: 1.18);
    return _Reveal(
      child: Column(
        children: [
          _Tag(tag, onDark: onDark),
          const SizedBox(height: 18),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(style: tStyle, children: [
              TextSpan(text: titleStart),
              TextSpan(
                  text: titleAccent,
                  style: tStyle.copyWith(color: onDark ? _lilac : _primary)),
              if (titleEnd != null) TextSpan(text: titleEnd),
            ]),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: _b(mobile ? 14.5 : 16,
                    color: onDark ? Colors.white70 : _grey)),
          ),
        ],
      ),
    );
  }
}

// ── Grid de tarjetas responsive ─────────────────────────────────────────────
class _CardGrid extends StatelessWidget {
  final List<Widget> children;
  final int desktopCols;
  final double gap;
  const _CardGrid(
      {required this.children, this.desktopCols = 3, this.gap = 18});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      final w = c.maxWidth;
      int cols = desktopCols;
      if (w < 640) {
        cols = 1;
      } else if (w < 1000) {
        cols = desktopCols >= 3 ? 2 : desktopCols;
      }
      final itemW = (w - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: children
            .map((child) => SizedBox(width: itemW, child: child))
            .toList(),
      );
    });
  }
}

// ── Contenedor de sección centrado ──────────────────────────────────────────
class _Section extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final double vPad;
  const _Section(
      {required this.child, this.color, this.gradient, this.vPad = 96});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color, gradient: gradient),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: _hPad(context),
                vertical: _isMobile(context) ? vPad * 0.7 : vPad),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  HERO
// ═══════════════════════════════════════════════════════════════════════════
class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_tint2, Colors.white],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Formas decorativas
          Positioned(
              top: -120,
              right: -80,
              child: _Blob(size: 380, colors: const [_accent, _lilac], opacity: 0.35)),
          Positioned(
              bottom: -140,
              left: -100,
              child: _Blob(size: 360, colors: const [_primary, _violet], opacity: 0.18)),
          // Contenido
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: _hPad(context),
                    vertical: mobile ? 56 : 80),
                child: mobile
                    ? Column(
                        children: [
                          const _HeroCopy(),
                          const SizedBox(height: 48),
                          const _HeroVisual(),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Expanded(flex: 6, child: _HeroCopy()),
                          SizedBox(width: 40),
                          Expanded(flex: 5, child: _HeroVisual()),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();
  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile(context);
    final align = mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return _Reveal(
      dy: 24,
      child: Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Tag('Finanzas personales, hechas para LATAM'),
          const SizedBox(height: 24),
          RichText(
            textAlign: mobile ? TextAlign.center : TextAlign.start,
            text: TextSpan(
              style: _h(mobile ? 38 : 56, height: 1.08),
              children: [
                const TextSpan(text: 'Toma el control\nde tu '),
                TextSpan(
                    text: 'dinero',
                    style: _h(mobile ? 38 : 56, height: 1.08, color: _primary)),
                const TextSpan(text: ' hoy.'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(
              'Fimakyp transforma cómo manejas tus finanzas personales: registra '
              'gastos, crea metas de ahorro y genera reportes PDF con un solo toque.',
              textAlign: mobile ? TextAlign.center : TextAlign.start,
              style: _b(mobile ? 15 : 16.5),
            ),
          ),
          const SizedBox(height: 34),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: mobile ? WrapAlignment.center : WrapAlignment.start,
            children: [
              _PrimaryButton(
                  label: 'Comenzar gratis',
                  icon: Icons.rocket_launch_rounded,
                  onTap: () => context.go('/register')),
              _GhostButton(
                  label: 'Iniciar sesión',
                  icon: Icons.login_rounded,
                  onTap: () => context.go('/login')),
            ],
          ),
          const SizedBox(height: 34),
          _HeroSocialProof(center: mobile),
        ],
      ),
    );
  }
}

class _HeroSocialProof extends StatelessWidget {
  final bool center;
  const _HeroSocialProof({required this.center});
  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.lock_rounded, '100% gratis'),
      (Icons.block_rounded, 'Sin anuncios'),
      (Icons.verified_user_rounded, 'Datos cifrados'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: center ? WrapAlignment.center : WrapAlignment.start,
      children: [
        for (final it in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _primary.withOpacity(0.16)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(it.$1, color: _primary, size: 16),
                const SizedBox(width: 8),
                Text(it.$2,
                    style: _b(13, w: FontWeight.w700, color: _primaryDk)),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Visual del hero: teléfono flotante + tarjetas ───────────────────────────
class _HeroVisual extends StatefulWidget {
  const _HeroVisual();
  @override
  State<_HeroVisual> createState() => _HeroVisualState();
}

class _HeroVisualState extends State<_HeroVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Reveal(
      dy: 30,
      delay: const Duration(milliseconds: 120),
      child: SizedBox(
        height: 520,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Halo
            Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [_lilacLt.withOpacity(0.7), _tint],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
              ),
            ),
            // Teléfono flotante
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) => Transform.translate(
                  offset: Offset(0, math.sin(_ctrl.value * math.pi * 2) * 10),
                  child: child),
              child: const _PhoneFrame(child: _DashboardScreen()),
            ),
            // Tarjeta flotante: balance
            _FloatingChip(
              ctrl: _ctrl,
              phase: 0.0,
              top: 36,
              right: -6,
              child: _MiniStat(
                  icon: Icons.trending_up_rounded,
                  color: _primary,
                  label: 'Balance',
                  value: '\$2.540.000'),
            ),
            // Tarjeta flotante: racha
            _FloatingChip(
              ctrl: _ctrl,
              phase: 0.5,
              bottom: 70,
              left: -10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('Racha 12 días',
                      style: _b(12.5, w: FontWeight.w700, color: _ink)),
                ],
              ),
            ),
            // Tarjeta flotante: meta
            _FloatingChip(
              ctrl: _ctrl,
              phase: 0.25,
              bottom: 8,
              right: 4,
              child: _MiniStat(
                  icon: Icons.savings_rounded,
                  color: _accent,
                  label: 'Meta viaje',
                  value: '78%'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingChip extends StatelessWidget {
  final AnimationController ctrl;
  final double phase;
  final double? top, bottom, left, right;
  final Widget child;
  const _FloatingChip(
      {required this.ctrl,
      required this.phase,
      this.top,
      this.bottom,
      this.left,
      this.right,
      required this.child});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (_, c) => Transform.translate(
            offset: Offset(0, math.sin((ctrl.value + phase) * math.pi * 2) * 7),
            child: c),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: _primary.withOpacity(0.18),
                  blurRadius: 26,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _MiniStat(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: _b(10.5, color: _grey)),
            Text(value, style: _b(13, w: FontWeight.w800, color: _ink)),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Marco de teléfono + pantallas recreadas de la app
// ═══════════════════════════════════════════════════════════════════════════
class _PhoneFrame extends StatelessWidget {
  final Widget child;
  final double width;
  const _PhoneFrame({required this.child, this.width = 248});
  @override
  Widget build(BuildContext context) {
    final height = width * 2.04;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1233),
        borderRadius: BorderRadius.circular(42),
        border: Border.all(color: const Color(0xFF2E2150), width: 3),
        boxShadow: [
          BoxShadow(
              color: _primary.withOpacity(0.28),
              blurRadius: 60,
              offset: const Offset(0, 28)),
        ],
      ),
      padding: const EdgeInsets.all(7),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFFF7F4FF), child: child),
            // Notch
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                width: 80,
                height: 18,
                decoration: BoxDecoration(
                    color: const Color(0xFF1C1233),
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pantalla: Dashboard ─────────────────────────────────────────────────────
class _DashboardScreen extends StatelessWidget {
  const _DashboardScreen();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 34, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Buenas tardes,', style: _b(9.5, color: _grey)),
                  Text('Tu resumen', style: _h(15, color: _ink, ls: 0)),
                ],
              ),
              const Spacer(),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [_primary, _accent]),
                    shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('F', style: _b(13, w: FontWeight.w800, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Tarjeta balance
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_primary, _accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: _primary.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Balance total',
                    style: _b(10, color: Colors.white70)),
                const SizedBox(height: 4),
                Text('\$2.540.000',
                    style: _h(24, color: Colors.white, ls: -1)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      _balStat(Icons.trending_up_rounded, 'Activos', '\$3.1M'),
                      Container(
                          width: 1,
                          height: 26,
                          color: Colors.white24,
                          margin: const EdgeInsets.symmetric(horizontal: 12)),
                      _balStat(Icons.trending_down_rounded, 'Deudas', '\$560K'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('Últimas transacciones', style: _h(11.5, color: _ink, ls: 0)),
          const SizedBox(height: 8),
          _txRow('🍔', 'Almuerzo', 'Comida', '-\$28.000', _primaryDk),
          _txRow('💼', 'Salario', 'Ingreso', '+\$1.200.000', _violet),
          _txRow('🚕', 'Uber', 'Transporte', '-\$14.500', _primaryDk),
        ],
      ),
    );
  }

  Widget _balStat(IconData i, String l, String v) => Expanded(
        child: Row(
          children: [
            Icon(i, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l, style: _b(8.5, color: Colors.white70)),
                Text(v, style: _b(11, w: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ],
        ),
      );

  Widget _txRow(String emoji, String title, String sub, String amount, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                color: c.withOpacity(0.10),
                borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _b(11, w: FontWeight.w600, color: _ink)),
                Text(sub, style: _b(9, color: _grey)),
              ],
            ),
          ),
          Text(amount, style: _b(10.5, w: FontWeight.w800, color: c)),
        ],
      ),
    );
  }
}

// ── Pantalla: Transacciones ─────────────────────────────────────────────────
class _TransactionsScreen extends StatelessWidget {
  const _TransactionsScreen();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 36, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Transacciones', style: _h(15, color: _ink, ls: 0)),
              const Spacer(),
              Icon(Icons.download_rounded, color: _primary, size: 16),
              const SizedBox(width: 10),
              Icon(Icons.filter_list_rounded, color: _primary, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text('HOY', style: _b(8.5, w: FontWeight.w700, color: _greyLt)),
          const SizedBox(height: 4),
          _row('🛒', 'Mercado', 'Hogar · 14:20', '-\$92.000', _primaryDk),
          _row('☕', 'Café', 'Comida · 09:10', '-\$8.500', _primaryDk),
          const SizedBox(height: 10),
          Text('AYER', style: _b(8.5, w: FontWeight.w700, color: _greyLt)),
          const SizedBox(height: 4),
          _row('💼', 'Salario', 'Ingreso · 08:00', '+\$1.200.000', _violet),
          _row('🎬', 'Netflix', 'Ocio · 20:00', '-\$38.900', _primaryDk),
          _row('💡', 'Luz', 'Servicios · 11:00', '-\$110.000', _primaryDk),
        ],
      ),
    );
  }

  Widget _row(String e, String t, String s, String a, Color c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: c.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text(e, style: const TextStyle(fontSize: 15)),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t, style: _b(11, w: FontWeight.w600, color: _ink)),
                  Text(s, style: _b(8.5, color: _grey)),
                ],
              ),
            ),
            Text(a, style: _b(10.5, w: FontWeight.w800, color: c)),
          ],
        ),
      );
}

// ── Pantalla: Metas ─────────────────────────────────────────────────────────
class _GoalsScreen extends StatelessWidget {
  const _GoalsScreen();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 36, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Metas de ahorro', style: _h(15, color: _ink, ls: 0)),
          const SizedBox(height: 14),
          _goal('✈️', 'Viaje a Europa', 0.78, '\$7.8M', '\$10M'),
          _goal('🚗', 'Carro nuevo', 0.45, '\$13.5M', '\$30M'),
          _goal('🏠', 'Cuota inicial', 0.32, '\$9.6M', '\$30M'),
          _goal('🎓', 'Maestría', 0.6, '\$12M', '\$20M'),
        ],
      ),
    );
  }

  Widget _goal(String e, String t, double p, String cur, String tot) => Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
                color: _primary.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(e, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(t,
                        style: _b(11.5, w: FontWeight.w700, color: _ink))),
                Text('${(p * 100).round()}%',
                    style: _b(11, w: FontWeight.w800, color: _primary)),
              ],
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: p,
                minHeight: 7,
                backgroundColor: _tint,
                valueColor: const AlwaysStoppedAnimation(_primary),
              ),
            ),
            const SizedBox(height: 6),
            Text('$cur de $tot', style: _b(9, color: _grey)),
          ],
        ),
      );
}

// ── Pantalla: Deudas ────────────────────────────────────────────────────────
class _DebtsScreen extends StatelessWidget {
  const _DebtsScreen();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 36, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deudas', style: _h(15, color: _ink, ls: 0)),
          const SizedBox(height: 12),
          // Resumen
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_primaryDk, _violet]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Me deben', style: _b(9, color: Colors.white70)),
                      Text('\$420.000',
                          style: _b(14, w: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Debo', style: _b(9, color: Colors.white70)),
                      Text('\$180.000',
                          style: _b(14, w: FontWeight.w800, color: _lilacLt)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _debt('A', 'Andrés', 'Te debe', '\$250.000', true),
          _debt('C', 'Camila', 'Te debe', '\$170.000', true),
          _debt('J', 'Juan', 'Le debes', '\$180.000', false),
        ],
      ),
    );
  }

  Widget _debt(String ini, String name, String label, String amount, bool positive) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_primary, _accent]),
                  shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(ini, style: _b(12, w: FontWeight.w800, color: Colors.white)),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: _b(11, w: FontWeight.w600, color: _ink)),
                  Text(label, style: _b(8.5, color: _grey)),
                ],
              ),
            ),
            Text(amount,
                style: _b(10.5,
                    w: FontWeight.w800, color: positive ? _violet : _primaryDk)),
          ],
        ),
      );
}

// ── Pantalla: Reportes ──────────────────────────────────────────────────────
class _ReportsScreen extends StatelessWidget {
  const _ReportsScreen();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 36, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reportes', style: _h(15, color: _ink, ls: 0)),
          const SizedBox(height: 14),
          // Donut
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(colors: [
                        _primary,
                        _accent,
                        _lilac,
                        _violet,
                        _primaryDk,
                        _primary,
                      ]),
                    ),
                  ),
                  Container(
                    width: 74,
                    height: 74,
                    decoration: const BoxDecoration(
                        color: Color(0xFFF7F4FF), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Gastos', style: _b(8.5, color: _grey)),
                        Text('\$1.8M',
                            style: _b(13, w: FontWeight.w800, color: _ink)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Evolución 6 meses', style: _h(11, color: _ink, ls: 0)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bar(0.5),
              _bar(0.7),
              _bar(0.4),
              _bar(0.85),
              _bar(0.6),
              _bar(1.0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar(double h) => Container(
        width: 22,
        height: 70 * h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [_accent, _primary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
          borderRadius: BorderRadius.circular(6),
        ),
      );
}

// ── Pantalla: Hogar ─────────────────────────────────────────────────────────
class _HouseholdScreen extends StatelessWidget {
  const _HouseholdScreen();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 36, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hogar', style: _h(15, color: _ink, ls: 0)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_primary, _accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gasto del hogar · este mes',
                    style: _b(9.5, color: Colors.white70)),
                const SizedBox(height: 4),
                Text('\$3.180.000', style: _h(22, color: Colors.white, ls: -1)),
                const SizedBox(height: 11),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const LinearProgressIndicator(
                    value: 0.64,
                    minHeight: 7,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Text('64% del presupuesto de \$5M',
                    style: _b(9, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('MIEMBROS', style: _b(8.5, w: FontWeight.w700, color: _greyLt)),
          const SizedBox(height: 6),
          _member('A', 'Ana', 'Aportó este mes', '\$1.8M', _primary),
          _member('L', 'Luis', 'Aportó este mes', '\$980K', _violet),
          _member('S', 'Sofía', 'Aportó este mes', '\$400K', _accent),
        ],
      ),
    );
  }

  Widget _member(String ini, String name, String label, String amount, Color c) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(ini,
                  style: _b(12, w: FontWeight.w800, color: Colors.white)),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: _b(11, w: FontWeight.w600, color: _ink)),
                  Text(label, style: _b(8.5, color: _grey)),
                ],
              ),
            ),
            Text(amount, style: _b(10.5, w: FontWeight.w800, color: _ink)),
          ],
        ),
      );
}

// ── Pantalla: Recurrentes ───────────────────────────────────────────────────
class _RecurringScreen extends StatelessWidget {
  const _RecurringScreen();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 36, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Recurrentes', style: _h(15, color: _ink, ls: 0)),
              const Spacer(),
              const Icon(Icons.add_rounded, color: _primary, size: 17),
            ],
          ),
          const SizedBox(height: 12),
          _rec('🏠', 'Arriendo', 'Mensual · día 1', '-\$1.200.000', _primaryDk),
          _rec('💼', 'Salario', 'Mensual · día 30', '+\$3.200.000', _violet),
          _rec('🎬', 'Netflix', 'Mensual · día 5', '-\$38.900', _primaryDk),
          _rec('🏋️', 'Gimnasio', 'Mensual · día 8', '-\$95.000', _primaryDk),
          _rec('💡', 'Servicios', 'Mensual · día 12', '-\$210.000', _primaryDk),
        ],
      ),
    );
  }

  Widget _rec(String e, String t, String freq, String amount, Color c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: c.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text(e, style: const TextStyle(fontSize: 15)),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t, style: _b(11, w: FontWeight.w600, color: _ink)),
                  Row(
                    children: [
                      const Icon(Icons.event_repeat_rounded,
                          size: 9, color: _greyLt),
                      const SizedBox(width: 3),
                      Text(freq, style: _b(8.5, color: _grey)),
                    ],
                  ),
                ],
              ),
            ),
            Text(amount, style: _b(10.5, w: FontWeight.w800, color: c)),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  NOSOTROS (Quiénes somos)
// ═══════════════════════════════════════════════════════════════════════════
class _AboutSection extends StatelessWidget {
  const _AboutSection({super.key});
  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile(context);
    final text = _Reveal(
      child: Column(
        crossAxisAlignment:
            mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Tag('Quiénes somos'),
          const SizedBox(height: 18),
          RichText(
            textAlign: mobile ? TextAlign.center : TextAlign.start,
            text: TextSpan(
              style: _h(mobile ? 26 : 36, height: 1.2),
              children: [
                const TextSpan(text: 'Construido con '),
                TextSpan(
                    text: 'propósito',
                    style: _h(mobile ? 26 : 36, height: 1.2, color: _primary)),
                const TextSpan(text: ',\npara personas reales.'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Fimakyp nació de una necesidad real: una app de finanzas que funcione '
            'en latinoamérica, que hable en pesos y que de verdad ayude a construir '
            'mejores hábitos con el dinero.\n\nNo somos un banco ni una startup de '
            'millones: somos personas que también aprendemos a manejar mejor nuestras '
            'finanzas, y construimos la herramienta que nos hubiera gustado tener.',
            textAlign: mobile ? TextAlign.center : TextAlign.start,
            style: _b(mobile ? 14.5 : 15.5, height: 1.8),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 22,
            runSpacing: 14,
            alignment: mobile ? WrapAlignment.center : WrapAlignment.start,
            children: const [
              _MiniFact(icon: Icons.flag_rounded, text: 'Misión: democratizar las finanzas'),
              _MiniFact(icon: Icons.public_rounded, text: 'Hecho para LATAM, en pesos'),
              _MiniFact(icon: Icons.favorite_rounded, text: 'Tus datos nunca se venden'),
            ],
          ),
        ],
      ),
    );

    final quote = _Reveal(
      delay: const Duration(milliseconds: 120),
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [_primary, _primaryDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: _primary.withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 18)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.format_quote_rounded, color: _lilac, size: 44),
            const SizedBox(height: 12),
            Text(
              '"El primer paso para manejar bien el dinero es saber exactamente a dónde va."',
              style: _h(20, color: Colors.white, w: FontWeight.w700, height: 1.45, ls: 0),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('F',
                      style: _h(18, color: Colors.white, ls: 0)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Equipo Fimakyp',
                        style: _b(13, w: FontWeight.w700, color: Colors.white)),
                    Text('Finanzas para todos',
                        style: _b(11.5, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return _Section(
      color: Colors.white,
      child: mobile
          ? Column(children: [text, const SizedBox(height: 36), quote])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 6, child: text),
                const SizedBox(width: 48),
                Expanded(flex: 5, child: quote),
              ],
            ),
    );
  }
}

class _MiniFact extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MiniFact({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: _primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _primary, size: 16),
        ),
        const SizedBox(width: 10),
        Text(text, style: _b(13, w: FontWeight.w600, color: _ink)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  BENEFICIOS
// ═══════════════════════════════════════════════════════════════════════════
class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection({super.key});

  static const _items = [
    (Icons.visibility_rounded, 'Claridad total',
        'Sabe exactamente qué entra y qué sale. Elimina la ansiedad y decide con datos.'),
    (Icons.savings_rounded, 'Construye tu futuro',
        'Cada peso registrado es un paso hacia tus metas: viajes, casa, educación o paz.'),
    (Icons.shield_rounded, 'Listo para imprevistos',
        'Quien lleva control responde mejor a emergencias sin caer en deudas.'),
    (Icons.trending_down_rounded, 'Sal de deudas antes',
        'Detecta gastos innecesarios y libera dinero para pagar y romper el ciclo.'),
    (Icons.self_improvement_rounded, 'Menos estrés',
        'El desorden financiero estresa. El control te devuelve la tranquilidad.'),
    (Icons.auto_awesome_rounded, 'Mejores hábitos',
        'Registrar a diario crea hábitos que se vuelven naturales y transforman tu vida.'),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_tint2, _tint],
      ),
      child: Column(
        children: [
          const _SectionHead(
            tag: '¿Por qué importa?',
            titleStart: 'Beneficios de ',
            titleAccent: 'tomar el control',
            subtitle:
                'La mayoría vivimos sin saber a dónde va el dinero. Eso cambia cuando empiezas a llevar el control con Fimakyp.',
          ),
          const SizedBox(height: 52),
          _CardGrid(
            children: [
              for (var i = 0; i < _items.length; i++)
                _Reveal(
                  delay: Duration(milliseconds: 60 * i),
                  child: _BenefitCard(
                      _items[i].$1, _items[i].$2, _items[i].$3),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  const _BenefitCard(this.icon, this.title, this.desc);
  @override
  State<_BenefitCard> createState() => _BenefitCardState();
}

class _BenefitCardState extends State<_BenefitCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: Matrix4.translationValues(0, _hover ? -6 : 0, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: _hover ? _primary.withOpacity(0.3) : _border),
          boxShadow: [
            BoxShadow(
                color: _primary.withOpacity(_hover ? 0.16 : 0.05),
                blurRadius: _hover ? 28 : 12,
                offset: Offset(0, _hover ? 12 : 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                gradient: _hover
                    ? const LinearGradient(colors: [_primary, _accent])
                    : null,
                color: _hover ? null : _primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(widget.icon,
                  color: _hover ? Colors.white : _primary, size: 24),
            ),
            const SizedBox(height: 16),
            Text(widget.title, style: _h(17, color: _ink, ls: 0)),
            const SizedBox(height: 8),
            Text(widget.desc, style: _b(13.5)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MÓDULOS (carrusel)
// ═══════════════════════════════════════════════════════════════════════════
class _ModuleData {
  final String tag, title, desc;
  final List<String> bullets;
  final Widget screen;
  const _ModuleData(this.tag, this.title, this.desc, this.bullets, this.screen);
}

const _modules = <_ModuleData>[
  _ModuleData(
    'Inicio',
    'Dashboard inteligente',
    'Tu balance total, activos, deudas y últimos movimientos en una sola vista clara y elegante.',
    ['Balance consolidado', 'Resumen de cuentas', 'Racha y actividad diaria'],
    _DashboardScreen(),
  ),
  _ModuleData(
    'Transacciones',
    'Registra en segundos',
    'Agrega ingresos, gastos y transferencias con categorías automáticas, filtros y exportación.',
    ['Categorización automática', 'Filtros por cuenta y fecha', 'Exporta a CSV y PDF'],
    _TransactionsScreen(),
  ),
  _ModuleData(
    'Metas',
    'Metas de ahorro',
    'Crea objetivos con monto y fecha. Visualiza tu progreso en tiempo real y mantente motivado.',
    ['Progreso en vivo', 'Aportes por meta', 'Fechas objetivo'],
    _GoalsScreen(),
  ),
  _ModuleData(
    'Deudas',
    'Control de deudas',
    'Lleva quién te debe y a quién le debes, registra abonos y nunca pierdas el rastro del dinero.',
    ['Te deben / debes', 'Abonos y pagos', 'Resumen por persona'],
    _DebtsScreen(),
  ),
  _ModuleData(
    'Reportes',
    'Reportes con gráficas',
    'Gráficas de gastos por categoría y la evolución de 6 meses, lista para descargar en PDF.',
    ['Donut por categoría', 'Evolución mensual', 'Reporte PDF profesional'],
    _ReportsScreen(),
  ),
  _ModuleData(
    'Hogar',
    'Finanzas en familia',
    'Comparte un presupuesto con tu hogar, registra los aportes de cada miembro y mira en qué se va el dinero entre todos.',
    ['Presupuesto compartido', 'Aportes por miembro', 'Gastos del hogar'],
    _HouseholdScreen(),
  ),
  _ModuleData(
    'Recurrentes',
    'Pagos automáticos',
    'Programa ingresos y gastos que se repiten. Fimakyp los registra solo y te recuerda cada vencimiento.',
    ['Frecuencia flexible', 'Registro automático', 'Recordatorios a tiempo'],
    _RecurringScreen(),
  ),
];

class _ModulesSection extends StatelessWidget {
  const _ModulesSection({super.key});
  @override
  Widget build(BuildContext context) {
    return _Section(
      color: Colors.white,
      child: Column(
        children: const [
          _SectionHead(
            tag: 'Módulos',
            titleStart: 'Una app, ',
            titleAccent: 'todo lo que necesitas',
            subtitle:
                'Siete módulos diseñados para que domines tus finanzas sin complicaciones.',
          ),
          SizedBox(height: 44),
          _ModulesCarousel(),
        ],
      ),
    );
  }
}

class _ModulesCarousel extends StatefulWidget {
  const _ModulesCarousel();
  @override
  State<_ModulesCarousel> createState() => _ModulesCarouselState();
}

class _ModulesCarouselState extends State<_ModulesCarousel> {
  final _pc = PageController();
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_index + 1) % _modules.length;
      _pc.animateToPage(next,
          duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  void _goTo(int i) {
    _pc.animateToPage(i,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile(context);
    return _Reveal(
      child: Column(
        children: [
          SizedBox(
            height: mobile ? 880 : 560,
            child: Row(
              children: [
                if (!mobile)
                  _Arrow(
                      icon: Icons.chevron_left_rounded,
                      onTap: () =>
                          _goTo((_index - 1 + _modules.length) % _modules.length)),
                Expanded(
                  child: PageView.builder(
                    controller: _pc,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemCount: _modules.length,
                    itemBuilder: (_, i) => _ModulePage(_modules[i], mobile: mobile),
                  ),
                ),
                if (!mobile)
                  _Arrow(
                      icon: Icons.chevron_right_rounded,
                      onTap: () => _goTo((_index + 1) % _modules.length)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Indicadores
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_modules.length, (i) {
              final active = i == _index;
              return GestureDetector(
                onTap: () => _goTo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 28 : 9,
                  height: 9,
                  decoration: BoxDecoration(
                    gradient: active
                        ? const LinearGradient(colors: [_primary, _accent])
                        : null,
                    color: active ? null : _lilac,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Arrow({required this.icon, required this.onTap});
  @override
  State<_Arrow> createState() => _ArrowState();
}

class _ArrowState extends State<_Arrow> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _h ? _primary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: _h ? _primary : _border),
            boxShadow: [
              BoxShadow(
                  color: _primary.withOpacity(_h ? 0.3 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Icon(widget.icon, color: _h ? Colors.white : _primary, size: 26),
        ),
      ),
    );
  }
}

class _ModulePage extends StatelessWidget {
  final _ModuleData m;
  final bool mobile;
  const _ModulePage(this.m, {required this.mobile});
  @override
  Widget build(BuildContext context) {
    final phone = _PhoneFrame(child: m.screen);
    final copy = Column(
      crossAxisAlignment:
          mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Tag(m.tag),
        const SizedBox(height: 16),
        Text(m.title,
            textAlign: mobile ? TextAlign.center : TextAlign.start,
            style: _h(mobile ? 24 : 32, color: _ink)),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(m.desc,
              textAlign: mobile ? TextAlign.center : TextAlign.start,
              style: _b(mobile ? 14.5 : 16)),
        ),
        const SizedBox(height: 22),
        ...m.bullets.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [_primary, _accent]),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 13),
                  ),
                  const SizedBox(width: 12),
                  Text(b, style: _b(14, w: FontWeight.w600, color: _ink)),
                ],
              ),
            )),
      ],
    );

    if (mobile) {
      return SingleChildScrollView(
        child: Column(
          children: [
            copy,
            const SizedBox(height: 30),
            Center(child: phone),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: copy),
          const SizedBox(width: 40),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [_lilacLt.withOpacity(0.6), _tint],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                  ),
                ),
                phone,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  CARACTERÍSTICAS
// ═══════════════════════════════════════════════════════════════════════════
class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection({super.key});

  static const _items = [
    (Icons.account_balance_wallet_rounded, 'Múltiples cuentas',
        'Efectivo, débito, crédito e inversiones en una vista unificada.'),
    (Icons.repeat_rounded, 'Gastos recurrentes',
        'Programa cobros automáticos y nunca pierdas un vencimiento.'),
    (Icons.notifications_active_rounded, 'Recordatorios',
        'Notificaciones diarias personalizadas para mantener el hábito.'),
    (Icons.emoji_events_rounded, 'Gamificación',
        'Gana insignias, mantén rachas y mantente motivado con logros.'),
    (Icons.groups_rounded, 'Modo hogar',
        'Comparte gastos con tu familia y lleva un presupuesto en conjunto.'),
    (Icons.picture_as_pdf_rounded, 'Reportes PDF',
        'Genera reportes con gráficas y narrativa lista para compartir.'),
    (Icons.cloud_sync_rounded, 'Sincronización',
        'Tus datos siempre al día en todos tus dispositivos al instante.'),
    (Icons.palette_rounded, 'Temas a tu gusto',
        'Personaliza la app con paletas de color: morado, azul o verde.'),
    (Icons.lock_rounded, 'Seguridad total',
        'Firebase Auth + cifrado. Tu información nunca se comparte ni se vende.'),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_tint, _tint2],
      ),
      child: Column(
        children: [
          const _SectionHead(
            tag: 'Características',
            titleStart: 'Potente por dentro, ',
            titleAccent: 'simple por fuera',
            subtitle:
                'Herramientas pensadas para que controlar tu dinero sea fácil y hasta divertido.',
          ),
          const SizedBox(height: 52),
          _CardGrid(
            children: [
              for (var i = 0; i < _items.length; i++)
                _Reveal(
                  delay: Duration(milliseconds: 40 * i),
                  child: _FeatureCard(
                      _items[i].$1, _items[i].$2, _items[i].$3),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  const _FeatureCard(this.icon, this.title, this.desc);
  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _hover ? Colors.white : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: _hover ? _primary.withOpacity(0.3) : _border),
          boxShadow: _hover
              ? [
                  BoxShadow(
                      color: _primary.withOpacity(0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 10))
                ]
              : const [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                  color: _primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(widget.icon, color: _primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.title, style: _h(15, color: _ink, ls: 0)),
                  const SizedBox(height: 5),
                  Text(widget.desc, style: _b(12.8)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STATS (banda morada con contadores animados)
// ═══════════════════════════════════════════════════════════════════════════
class _StatsSection extends StatelessWidget {
  const _StatsSection();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [_primaryDeep, _primary, _accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
      child: Stack(
        children: [
          Positioned(
              top: -60,
              left: -40,
              child: _Blob(size: 240, colors: const [Colors.white, _lilac], opacity: 0.10)),
          Positioned(
              bottom: -80,
              right: -30,
              child: _Blob(size: 260, colors: const [Colors.white, _lilacLt], opacity: 0.10)),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: _hPad(context), vertical: 72),
                child: _Reveal(
                  child: Column(
                    children: [
                      Text('Todo lo que incluye',
                          textAlign: TextAlign.center,
                          style: _h(_isMobile(context) ? 24 : 32,
                              color: Colors.white)),
                      const SizedBox(height: 12),
                      Text(
                        'Una sola app, sin costo y sin anuncios, con todo lo que necesitas para tus finanzas.',
                        textAlign: TextAlign.center,
                        style: _b(15, color: Colors.white70),
                      ),
                      const SizedBox(height: 44),
                      const _CardGrid(
                        desktopCols: 4,
                        gap: 16,
                        children: [
                          _StatItem(Icons.widgets_rounded, 7, '', 'Módulos'),
                          _StatItem(Icons.auto_awesome_rounded, 9, '', 'Características'),
                          _StatItem(Icons.palette_rounded, 3, '', 'Temas de color'),
                          _StatItem(Icons.favorite_rounded, 100, '%', 'Gratis'),
                        ],
                      ),
                    ],
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

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int end;
  final String suffix;
  final String label;
  const _StatItem(this.icon, this.end, this.suffix, this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: end.toDouble()),
            duration: const Duration(milliseconds: 1600),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) {
              return Text('${v.round()}$suffix',
                  style: _h(34, color: Colors.white, ls: -1));
            },
          ),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: _b(13, color: Colors.white70)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  CTA final
// ═══════════════════════════════════════════════════════════════════════════
class _CtaSection extends StatelessWidget {
  const _CtaSection();
  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile(context);
    return _Section(
      color: Colors.white,
      child: _Reveal(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              horizontal: mobile ? 28 : 64, vertical: mobile ? 48 : 72),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_primaryDeep, _primary, _accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                  color: _primary.withOpacity(0.35),
                  blurRadius: 50,
                  offset: const Offset(0, 24)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    shape: BoxShape.circle),
                child: const Icon(Icons.rocket_launch_rounded,
                    color: Colors.white, size: 38),
              ),
              const SizedBox(height: 24),
              Text('¿Listo para tomar el\ncontrol de tu dinero?',
                  textAlign: TextAlign.center,
                  style: _h(mobile ? 28 : 42, color: Colors.white, height: 1.15)),
              const SizedBox(height: 16),
              Text('Empieza hoy, gratis. Tu yo del futuro te lo va a agradecer.',
                  textAlign: TextAlign.center,
                  style: _b(mobile ? 14.5 : 16.5, color: Colors.white70)),
              const SizedBox(height: 32),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  _CtaWhiteButton(onTap: () => context.go('/register')),
                  _GhostButton(
                      label: 'Ya tengo cuenta',
                      onTap: () => context.go('/login'),
                      onDark: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CtaWhiteButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CtaWhiteButton({required this.onTap});
  @override
  State<_CtaWhiteButton> createState() => _CtaWhiteButtonState();
}

class _CtaWhiteButtonState extends State<_CtaWhiteButton> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _h ? -2 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(_h ? 0.22 : 0.12),
                  blurRadius: _h ? 24 : 12,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Comenzar gratis',
                  style: _b(15, w: FontWeight.w800, color: _primary)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: _primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Footer
// ═══════════════════════════════════════════════════════════════════════════
class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile(context);
    final cols = Wrap(
      spacing: 56,
      runSpacing: 28,
      children: const [
        _FCol('Producto', ['Módulos', 'Características', 'Beneficios']),
        _FCol('Empresa', ['Nosotros', 'Blog', 'Contacto']),
        _FCol('Legal', ['Privacidad', 'Términos de uso', 'Cookies']),
      ],
    );

    final brand = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Logo(size: 30, color: _lilac, textColor: Colors.white),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(
            'La app de finanzas personales para latinoamérica. Toma el control de tu dinero, hoy.',
            style: _b(13, color: Colors.white60),
          ),
        ),
      ],
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [_dark, _darkAlt],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: _hPad(context), vertical: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mobile)
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [brand, const SizedBox(height: 36), cols])
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: brand),
                      Expanded(flex: 4, child: cols),
                    ],
                  ),
                const SizedBox(height: 40),
                Divider(color: Colors.white.withOpacity(0.12)),
                const SizedBox(height: 18),
                Text('© 2026 Fimakyp · Finanzas inteligentes para latinoamérica',
                    style: _b(12, color: Colors.white38)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FCol extends StatelessWidget {
  final String title;
  final List<String> items;
  const _FCol(this.title, this.items);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: _b(13.5, w: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 14),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FooterLink(item),
            )),
      ],
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String label;
  const _FooterLink(this.label);
  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: Text(widget.label,
          style: _b(12.5, color: _h ? _lilac : Colors.white54)),
    );
  }
}
