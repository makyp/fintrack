import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ── Brand palette ──────────────────────────────────────────────────────────────
class _C {
  static const blue = Color(0xFF2563EB);
  static const blueDark = Color(0xFF1D4ED8);
  static const aqua = Color(0xFF06B6D4);
  static const aquaLight = Color(0xFFCFFAFE);
  static const white = Colors.white;
  static const bg = Color(0xFFF0F9FF);
  static const grey = Color(0xFF6B7280);
  static const greyLight = Color(0xFF9CA3AF);
  static const dark = Color(0xFF0F172A);
  static const darkCard = Color(0xFF1E293B);
}

// ─────────────────────────────────────────────────────────────────────────────
// Scroll-reveal widget
// Parent must call _Reveal.checkAll() from NotificationListener<ScrollNotification>
// ─────────────────────────────────────────────────────────────────────────────
class _Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double dy;

  const _Reveal({
    required this.child,
    this.delay = Duration.zero,
    this.dy = 40,
  });

  static final _all = <_RevealState>[];
  static void checkAll() {
    for (final s in List.of(_all)) {
      s._check();
    }
  }

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _Reveal._all.add(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_done || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final pos = box.localToGlobal(Offset.zero);
    final screenH = MediaQuery.of(context).size.height;
    if (pos.dy < screenH * 0.94) {
      _done = true;
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _Reveal._all.remove(this);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _ctrl.value,
        child: Transform.translate(
          offset: Offset(0, widget.dy * (1 - _ctrl.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Float animation (loops up/down — used for hero visual)
// ─────────────────────────────────────────────────────────────────────────────
class _Float extends StatefulWidget {
  final Widget child;
  const _Float({required this.child});

  @override
  State<_Float> createState() => _FloatState();
}

class _FloatState extends State<_Float> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _y;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);
    _y = Tween<double>(begin: -8, end: 8)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _y,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, _y.value), child: child),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hover card: elevates and scales on mouse-over
// ─────────────────────────────────────────────────────────────────────────────
class _HoverCard extends StatefulWidget {
  final Widget Function(bool hovered) builder;
  final VoidCallback? onTap;
  const _HoverCard({required this.builder, this.onTap});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.035 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: widget.builder(_hovered),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hover nav link
// ─────────────────────────────────────────────────────────────────────────────
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
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _h ? _C.blue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: _h ? _C.blue : _C.grey,
              fontSize: 14,
              fontWeight: _h ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Root page
// ─────────────────────────────────────────────────────────────────────────────
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scroll = ScrollController();
  final _featuresKey = GlobalKey();
  final _curiositiesKey = GlobalKey();
  final _aboutKey = GlobalKey();

  bool _navShadow = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final shadowed = _scroll.offset > 40;
    if (shadowed != _navShadow) setState(() => _navShadow = shadowed);
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
        alignment: 0.0,
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.white,
      body: Stack(
        children: [
          // ── Scrollable content ────────────────────────────────────────────
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              _Reveal.checkAll();
              return false;
            },
            child: SingleChildScrollView(
              controller: _scroll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 72), // navbar space
                  _HeroSection(),
                  _BenefitsSection(),
                  _FeaturesSection(sectionKey: _featuresKey),
                  _CuriositiesSection(sectionKey: _curiositiesKey),
                  _AboutSection(sectionKey: _aboutKey),
                  _CtaSection(),
                  _Footer(),
                ],
              ),
            ),
          ),

          // ── Sticky navbar ─────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _Navbar(
              shadowed: _navShadow,
              onFeatures: () => _scrollTo(_featuresKey),
              onCuriosities: () => _scrollTo(_curiositiesKey),
              onAbout: () => _scrollTo(_aboutKey),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navbar
// ─────────────────────────────────────────────────────────────────────────────
class _Navbar extends StatelessWidget {
  final bool shadowed;
  final VoidCallback onFeatures;
  final VoidCallback onCuriosities;
  final VoidCallback onAbout;

  const _Navbar({
    required this.shadowed,
    required this.onFeatures,
    required this.onCuriosities,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: _C.white.withOpacity(shadowed ? 0.97 : 1.0),
        boxShadow: shadowed
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 80,
        vertical: 14,
      ),
      child: Row(
        children: [
          // Logo
          Image.asset('assets/images/LogoFimakyp.png', width: 34, height: 34),
          const SizedBox(width: 10),
          const Text(
            'Fimakyp',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _C.blue,
            ),
          ),
          const Spacer(),
          if (!isMobile) ...[
            _NavLink('Características', onFeatures),
            _NavLink('Curiosidades', onCuriosities),
            _NavLink('Nosotros', onAbout),
            const SizedBox(width: 20),
          ],
          OutlinedButton(
            onPressed: () => context.go('/login'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _C.blue,
              side: const BorderSide(color: _C.blue, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            ),
            child: const Text('Iniciar sesión',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => context.go('/register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.blue,
              foregroundColor: _C.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            ),
            child: const Text('Registrarse',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────────────────────────────────────
class _HeroSection extends StatefulWidget {
  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      5,
      (_) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 650)),
    );
    _anims = _ctrls
        .map((c) =>
            CurvedAnimation(parent: c, curve: Curves.easeOutCubic))
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var i = 0; i < _ctrls.length; i++) {
        Future.delayed(Duration(milliseconds: 80 + i * 130), () {
          if (mounted) _ctrls[i].forward();
        });
      }
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  Widget _a(int i, Widget child) => AnimatedBuilder(
        animation: _anims[i],
        builder: (_, w) => Opacity(
          opacity: _anims[i].value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - _anims[i].value)),
            child: w,
          ),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 900;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFECFEFF)],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical: isMobile ? 52 : 88,
      ),
      child: isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _heroText(isMobile),
              const SizedBox(height: 48),
              _heroVisual(),
            ])
          : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(flex: 5, child: _heroText(isMobile)),
              const SizedBox(width: 64),
              Expanded(flex: 4, child: _heroVisual()),
            ]),
    );
  }

  Widget _heroText(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _a(
          0,
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _C.aquaLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '✦  Finanzas inteligentes para todos',
              style: TextStyle(
                color: _C.aqua,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        _a(
          1,
          const Text(
            'Controla tu dinero,\nconstruye tu futuro',
            style: TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w800,
              color: _C.dark,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _a(
          2,
          const Text(
            'Fimakyp transforma la forma en que manejas tus finanzas. '
            'Registra gastos, alcanza metas y entiende tu dinero con '
            'reportes visuales que te hablan claro.',
            style: TextStyle(fontSize: 16, color: _C.grey, height: 1.65),
          ),
        ),
        const SizedBox(height: 36),
        _a(
          3,
          Row(
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.blue,
                  foregroundColor: _C.white,
                  elevation: 4,
                  shadowColor: _C.blue.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Comenzar ahora',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 14),
              Builder(builder: (ctx) => TextButton(
                onPressed: () => ctx.go('/login'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 15),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Iniciar sesión',
                        style: TextStyle(
                            color: _C.blue,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        color: _C.blue, size: 16),
                  ],
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _a(
          4,
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: const [
              _Pill(Icons.lock_outline_rounded, 'Datos cifrados'),
              _Pill(Icons.devices_rounded, 'Web y Android'),
              _Pill(Icons.bar_chart_rounded, 'Reportes PDF'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroVisual() {
    return _Float(
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _C.blue.withOpacity(0.12),
              _C.aqua.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _C.blue.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _C.blue.withOpacity(0.14),
              blurRadius: 48,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _C.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.smartphone_rounded, size: 52, color: _C.blue),
            ),
            const SizedBox(height: 20),
            const Text('📱 Imagen de la app aquí',
                style: TextStyle(
                    color: _C.blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(height: 8),
            const Text('Reemplaza con un screenshot real',
                style: TextStyle(color: _C.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _C.aqua, size: 15),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: _C.grey, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Benefits — "Por qué Fimakyp"
// ─────────────────────────────────────────────────────────────────────────────
class _BenefitsSection extends StatelessWidget {
  static const _benefits = [
    (
      Icons.account_balance_wallet_rounded,
      _C.blue,
      'Control total',
      'Ve exactamente cuánto entra y cuánto sale. Múltiples cuentas, una sola vista.',
    ),
    (
      Icons.bar_chart_rounded,
      _C.aqua,
      'Reportes PDF',
      'Genera reportes con gráficas de actividad y categorías con un solo toque.',
    ),
    (
      Icons.savings_rounded,
      _C.blue,
      'Metas de ahorro',
      'Define objetivos con fecha, haz seguimiento y celebra cuando los alcanzas.',
    ),
    (
      Icons.people_rounded,
      _C.aqua,
      'Finanzas compartidas',
      'Comparte gastos del hogar con tu pareja o familia en tiempo real.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      color: _C.white,
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80, vertical: 72),
      child: Column(
        children: [
          _Reveal(
            child: const Text(
              'POR QUÉ FIMAKYP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _C.aqua,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Reveal(
            delay: const Duration(milliseconds: 80),
            child: const Text(
              'Todo lo que necesitas\npara manejar tu dinero',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: _C.dark,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Reveal(
            delay: const Duration(milliseconds: 140),
            child: const Text(
              'Diseñado para que en 3 minutos al día tengas el control '
              'que siempre quisiste sobre tus finanzas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, color: _C.grey, height: 1.6),
            ),
          ),
          const SizedBox(height: 48),
          isMobile
              ? Column(
                  children: _benefits
                      .asMap()
                      .entries
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _Reveal(
                              delay: Duration(milliseconds: e.key * 80),
                              child: _BenefitCard(
                                icon: e.value.$1,
                                color: e.value.$2,
                                title: e.value.$3,
                                desc: e.value.$4,
                              ),
                            ),
                          ))
                      .toList(),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _benefits
                      .asMap()
                      .entries
                      .map(
                        (e) => Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: _Reveal(
                              delay: Duration(milliseconds: e.key * 80),
                              child: _BenefitCard(
                                icon: e.value.$1,
                                color: e.value.$2,
                                title: e.value.$3,
                                desc: e.value.$4,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  const _BenefitCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.desc});

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      builder: (hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hovered ? color.withOpacity(0.4) : const Color(0xFFE0F2FE),
          ),
          boxShadow: hovered
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  )
                ]
              : [
                  const BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 18),
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _C.dark)),
            const SizedBox(height: 8),
            Text(desc,
                style: const TextStyle(
                    fontSize: 13, color: _C.grey, height: 1.6)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Features — "Características"
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturesSection extends StatelessWidget {
  final GlobalKey sectionKey;
  const _FeaturesSection({required this.sectionKey});

  static const _features = [
    (
      Icons.account_balance_wallet_outlined,
      _C.blue,
      'Gestión de cuentas',
      'Maneja efectivo, débito, crédito e inversiones en un solo lugar. '
          'Fimakyp calcula tu patrimonio neto automáticamente y te muestra '
          'el estado real de tus finanzas en tiempo real.',
      '🏦 Imagen de cuentas',
    ),
    (
      Icons.bar_chart_outlined,
      _C.aqua,
      'Reportes inteligentes',
      'Con un clic genera un PDF con tus ingresos, gastos por categoría, '
          'actividad diaria y métricas clave del mes. Perfecto para entender '
          'tus patrones de consumo y tomar mejores decisiones.',
      '📊 Imagen de reportes',
    ),
    (
      Icons.emoji_events_outlined,
      _C.blue,
      'Logros y racha diaria',
      'Mantén una racha de registro diario y desbloquea insignias según '
          'tus hábitos. Fimakyp hace que manejar dinero sea motivador '
          'y no una obligación.',
      '🏆 Imagen de logros',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      key: sectionKey,
      color: _C.bg,
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80, vertical: 80),
      child: Column(
        children: [
          _Reveal(
            child: const Text(
              'CARACTERÍSTICAS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _C.aqua,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Reveal(
            delay: const Duration(milliseconds: 80),
            child: const Text(
              'Herramientas que\nrealmente necesitas',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: _C.dark,
                  height: 1.2),
            ),
          ),
          const SizedBox(height: 56),
          ..._features.asMap().entries.map((entry) {
            final i = entry.key;
            final f = entry.value;
            final reversed = !isMobile && i % 2 == 1;

            final textBlock = _Reveal(
              delay: Duration(milliseconds: i * 60),
              dy: reversed ? -30 : 30,
              child: _FeatureText(f.$1, f.$2, f.$3, f.$4),
            );
            final mockup = _Reveal(
              delay: Duration(milliseconds: i * 60 + 80),
              dy: reversed ? 30 : -30,
              child: _FeatureMockup(f.$5, f.$2),
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 72),
              child: isMobile
                  ? Column(children: [
                      textBlock,
                      const SizedBox(height: 28),
                      mockup
                    ])
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: reversed
                          ? [
                              Expanded(flex: 5, child: mockup),
                              const SizedBox(width: 64),
                              Expanded(flex: 5, child: textBlock)
                            ]
                          : [
                              Expanded(flex: 5, child: textBlock),
                              const SizedBox(width: 64),
                              Expanded(flex: 5, child: mockup)
                            ],
                    ),
            );
          }),
        ],
      ),
    );
  }
}

class _FeatureText extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  const _FeatureText(this.icon, this.color, this.title, this.desc);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 20),
        Text(title,
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _C.dark)),
        const SizedBox(height: 14),
        Text(desc,
            style: const TextStyle(
                fontSize: 15, color: _C.grey, height: 1.7)),
      ],
    );
  }
}

class _FeatureMockup extends StatelessWidget {
  final String placeholder;
  final Color color;
  const _FeatureMockup(this.placeholder, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.09),
            color.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, size: 36, color: color.withOpacity(0.4)),
            const SizedBox(height: 10),
            Text(placeholder,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const SizedBox(height: 4),
            Text('Reemplaza con screenshot',
                style: TextStyle(
                    color: color.withOpacity(0.5), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Curiosities
// ─────────────────────────────────────────────────────────────────────────────
class _CuriositiesSection extends StatelessWidget {
  final GlobalKey sectionKey;
  const _CuriositiesSection({required this.sectionKey});

  static const _items = [
    ('💸', '80%', 'de las personas no sabe cuánto gasta al mes'),
    ('⏱️', '3 min', 'es todo lo que necesitas al día para llevar el control'),
    ('🎯', '2.5×', 'más probabilidad de alcanzar metas con seguimiento activo'),
    ('🔥', '30 días', 'es la racha máxima que puedes lograr en Fimakyp'),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      key: sectionKey,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.blue, Color(0xFF0369A1)],
        ),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80, vertical: 80),
      child: Column(
        children: [
          _Reveal(
            child: const Text(
              '¿SABÍAS QUE...?',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Reveal(
            delay: const Duration(milliseconds: 80),
            child: const Text(
              'Curiosidades sobre finanzas personales',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 52),
          isMobile
              ? Column(
                  children: _items
                      .asMap()
                      .entries
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _Reveal(
                              delay: Duration(milliseconds: e.key * 90),
                              child: _CuriosityCard(
                                  e.value.$1, e.value.$2, e.value.$3),
                            ),
                          ))
                      .toList(),
                )
              : Row(
                  children: _items
                      .asMap()
                      .entries
                      .map((e) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: _Reveal(
                                delay: Duration(milliseconds: e.key * 90),
                                child: _CuriosityCard(
                                    e.value.$1, e.value.$2, e.value.$3),
                              ),
                            ),
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }
}

class _CuriosityCard extends StatelessWidget {
  final String emoji;
  final String stat;
  final String desc;
  const _CuriosityCard(this.emoji, this.stat, this.desc);

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      builder: (hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: hovered
              ? Colors.white.withOpacity(0.18)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.white.withOpacity(hovered ? 0.35 : 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 14),
            Text(stat,
                style: const TextStyle(
                  color: _C.aquaLight,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                )),
            const SizedBox(height: 8),
            Text(desc,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// About — "Nosotros"
// ─────────────────────────────────────────────────────────────────────────────
class _AboutSection extends StatelessWidget {
  final GlobalKey sectionKey;
  const _AboutSection({required this.sectionKey});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      key: sectionKey,
      color: _C.white,
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80, vertical: 80),
      child: Column(
        children: [
          _Reveal(
            child: const Text(
              'NOSOTROS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _C.aqua,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Reveal(
            delay: const Duration(milliseconds: 80),
            child: const Text(
              'Construido con propósito',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: _C.dark),
            ),
          ),
          const SizedBox(height: 16),
          _Reveal(
            delay: const Duration(milliseconds: 130),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: const Text(
                'Fimakyp nació de una necesidad real: tener una app de finanzas '
                'personales que funcione en Colombia, que hable en pesos, que sea '
                'simple de usar y que realmente ayude a construir mejores hábitos '
                'con el dinero. No somos un banco ni una startup de millones — '
                'somos personas que también estamos aprendiendo a manejar mejor '
                'nuestras finanzas.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 15, color: _C.grey, height: 1.75),
              ),
            ),
          ),
          const SizedBox(height: 52),
          _Reveal(
            delay: const Duration(milliseconds: 180),
            child: isMobile
                ? Column(children: _aboutValues())
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _aboutValues()
                        .map((w) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: w,
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 56),
          _Reveal(
            delay: const Duration(milliseconds: 220),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _C.blue.withOpacity(0.06),
                    _C.aqua.withOpacity(0.04)
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.blue.withOpacity(0.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _C.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.format_quote_rounded,
                        color: _C.blue, size: 28),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Text(
                      '"El primer paso para manejar bien el dinero\n'
                      'es saber exactamente a dónde va."',
                      style: TextStyle(
                        fontSize: 16,
                        color: _C.dark,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _aboutValues() => [
        _ValueChip(Icons.favorite_rounded, _C.blue, 'Simple primero'),
        _ValueChip(Icons.security_rounded, _C.aqua, 'Datos seguros'),
        _ValueChip(Icons.trending_up_rounded, _C.blue, 'Siempre mejorando'),
      ];
}

class _ValueChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _ValueChip(this.icon, this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA
// ─────────────────────────────────────────────────────────────────────────────
class _CtaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFECFEFF)],
        ),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80, vertical: 88),
      child: Column(
        children: [
          _Reveal(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _C.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.rocket_launch_rounded,
                  color: _C.blue, size: 40),
            ),
          ),
          const SizedBox(height: 24),
          _Reveal(
            delay: const Duration(milliseconds: 80),
            child: const Text(
              '¿Listo para tomar\ncontrol de tu dinero?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: _C.dark,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Reveal(
            delay: const Duration(milliseconds: 130),
            child: const Text(
              'Empieza hoy. Tu yo del futuro te lo va a agradecer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, color: _C.grey, height: 1.6),
            ),
          ),
          const SizedBox(height: 36),
          _Reveal(
            delay: const Duration(milliseconds: 180),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => context.go('/register'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.blue,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shadowColor: _C.blue.withOpacity(0.35),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Crear mi cuenta',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                OutlinedButton(
                  onPressed: () => context.go('/login'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _C.blue,
                    side: const BorderSide(color: _C.blue, width: 1.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ya tengo cuenta',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      color: _C.dark,
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80, vertical: 28),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _footerLogo(),
                const SizedBox(height: 12),
                _footerCopy(),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _footerLogo(),
                _footerCopy(),
              ],
            ),
    );
  }

  Widget _footerLogo() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/LogoFimakyp.png', width: 26, height: 26),
          const SizedBox(width: 8),
          const Text('Fimakyp',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ],
      );

  Widget _footerCopy() => const Text(
        '© 2025 Fimakyp · Finanzas inteligentes',
        style: TextStyle(color: Colors.white38, fontSize: 12),
      );
}
