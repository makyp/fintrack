import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ── Scroll behavior para Flutter Web ─────────────────────────────────────────
class _WebBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

// ── Paleta ────────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2F5BFF);
const _purple = Color(0xFF7A5CFA);
const _aqua = Color(0xFF2EC4B6);
const _aquaDk = Color(0xFF1DA89B);
const _aquaLt = Color(0xFFE6FAF8);
const _dark = Color(0xFF0F1830);
const _darkAlt = Color(0xFF1A2B50);
const _grey = Color(0xFF6B7A9A);
const _greyLt = Color(0xFF9AAABF);
const _bg = Color(0xFFF7F9FC);
const _bgAlt = Color(0xFFEEF2FF);
const _border = Color(0xFFE5E7EB);
const _circle = Color(0xFFCDD9FF);

// ─────────────────────────────────────────────────────────────────────────────
// LandingPage
// ─────────────────────────────────────────────────────────────────────────────
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scroll = ScrollController();
  final _importanceKey = GlobalKey();
  final _functionsKey = GlobalKey();
  final _howItWorksKey = GlobalKey();
  final _aboutKey = GlobalKey();
  bool _shadowed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final s = _scroll.offset > 10;
    if (s != _shadowed) setState(() => _shadowed = s);
  }

  void _go(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic);
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
        preferredSize: const Size.fromHeight(64),
        child: _Navbar(
          shadowed: _shadowed,
          onStart: () {},
          onImportance: () => _go(_importanceKey),
          onFunctions: () => _go(_functionsKey),
          onHowItWorks: () => _go(_howItWorksKey),
          onAbout: () => _go(_aboutKey),
        ),
      ),
      body: ScrollConfiguration(
        behavior: _WebBehavior(),
        child: SingleChildScrollView(
          controller: _scroll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroSection(),
              _ImportanceSection(key: _importanceKey),
              _FunctionsSection(key: _functionsKey),
              _HowItWorksSection(key: _howItWorksKey),
              _StatsSection(),
              _AboutSection(key: _aboutKey),
              _CtaSection(),
              const _Footer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navbar
// ─────────────────────────────────────────────────────────────────────────────
class _Navbar extends StatelessWidget {
  final bool shadowed;
  final VoidCallback onStart, onImportance, onFunctions, onHowItWorks, onAbout;
  const _Navbar({
    required this.shadowed,
    required this.onStart,
    required this.onImportance,
    required this.onFunctions,
    required this.onHowItWorks,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: shadowed
            ? [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 3))
              ]
            : const [],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 72),
      child: Row(
        children: [
          // Logo
          Image.asset(
            'assets/images/LogoFimakyp.png',
            width: 30,
            height: 30,
            errorBuilder: (_, __, ___) => const Icon(
                Icons.account_balance_wallet_rounded,
                color: _blue,
                size: 26),
          ),
          const SizedBox(width: 10),
          const Text('Fimakyp',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: _blue)),
          const SizedBox(width: 36),
          // Nav links
          _NavLink('Inicio', onStart),
          _NavLink('¿Por qué?', onImportance),
          _NavLink('Funciones', onFunctions),
          _NavLink('Cómo funciona', onHowItWorks),
          _NavLink('Nosotros', onAbout),
          const Spacer(),
          // Botones
          OutlinedButton(
            onPressed: () => context.go('/login'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _blue,
              minimumSize: const Size(120, 40),
              side: const BorderSide(color: _blue, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Iniciar sesión',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(widget.label,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: _h ? FontWeight.w600 : FontWeight.w500,
                  color: _h ? _blue : _grey)),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left copy ──────────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                      color: _aquaLt, borderRadius: BorderRadius.circular(20)),
                  child: const Text(
                      '✦  La app de finanzas #1 para latinoamérica',
                      style: TextStyle(
                          color: _aquaDk,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 22),
                // H1
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.w800,
                        color: _dark,
                        height: 1.12),
                    children: [
                      TextSpan(text: 'Toma el control\n'),
                      TextSpan(
                          text: 'de tu dinero ',
                          style: TextStyle(color: _blue)),
                      TextSpan(text: 'hoy.'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Fimakyp transforma la forma en que manejas tus finanzas personales. '
                  'Registra gastos, crea metas de ahorro y genera reportes PDF con un solo toque.',
                  style: TextStyle(fontSize: 15.5, color: _grey, height: 1.7),
                ),
                const SizedBox(height: 36),
                // CTAs
                OutlinedButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text('Iniciar sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _blue,
                    minimumSize: const Size(140, 44),
                    side: const BorderSide(color: _blue, width: 1.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 32),
                // Avatares
                Row(
                  children: [
                    SizedBox(
                      width: 112,
                      height: 34,
                      child: Stack(
                        children: List.generate(5, (i) {
                          const colors = [
                            _blue,
                            _aqua,
                            Color(0xFF5B7FFF),
                            _aquaDk,
                            _purple
                          ];
                          const initials = ['M', 'J', 'A', 'C', 'L'];
                          return Positioned(
                            left: i * 20.0,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                  color: colors[i],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2)),
                              alignment: Alignment.center,
                              child: Text(initials[i],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('500+',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _dark)),
                        Text('usuarios activos',
                            style: TextStyle(fontSize: 11, color: _grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Trust pills
                const Row(
                  children: [
                    _TrustPill(Icons.lock_outline_rounded, 'Datos cifrados'),
                    SizedBox(width: 20),
                    _TrustPill(Icons.devices_rounded, 'Web y Android'),
                    SizedBox(width: 20),
                    _TrustPill(Icons.picture_as_pdf_rounded, 'Reportes PDF'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
          // ── Right visual ───────────────────────────────────────────────
          Expanded(flex: 5, child: _HeroVisual()),
        ],
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustPill(this.icon, this.label);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _aqua, size: 14),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 12.5, color: _grey, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _HeroVisual extends StatefulWidget {
  @override
  State<_HeroVisual> createState() => _HeroVisualState();
}

class _HeroVisualState extends State<_HeroVisual>
    with SingleTickerProviderStateMixin {
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
      child: SizedBox(
        height: 440,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Círculo
            Container(
              width: 360,
              height: 360,
              decoration:
                  const BoxDecoration(color: _circle, shape: BoxShape.circle),
            ),
            // Teléfono
            _PhoneMock(),
            // Balance card
            Positioned(
              bottom: 10,
              right: 0,
              child: _Card(
                  child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: _blue.withOpacity(0.12), shape: BoxShape.circle),
                    child: const Icon(Icons.trending_up_rounded,
                        color: _blue, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Balance',
                          style: TextStyle(color: _grey, fontSize: 10)),
                      Text('\$2,540,000',
                          style: TextStyle(
                              color: _dark,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              )),
            ),
            // Streak
            Positioned(
              top: 20,
              left: 0,
              child: _Card(
                  child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔥', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 6),
                  Text('Racha: 12 días',
                      style: TextStyle(
                          color: _dark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, 6))
        ],
      ),
      child: child,
    );
  }
}

class _PhoneMock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      height: 420,
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(38),
        border: Border.all(color: const Color(0xFF374151), width: 2.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 48,
              offset: const Offset(0, 20)),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFEFF6FF), Color(0xFFE0F2FE)],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 28,
                alignment: Alignment.center,
                child: Container(
                  width: 58,
                  height: 14,
                  decoration: BoxDecoration(
                      color: _dark, borderRadius: BorderRadius.circular(7)),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: _blue.withOpacity(0.12), shape: BoxShape.circle),
                    child: const Icon(Icons.smartphone_rounded,
                        color: _blue, size: 30),
                  ),
                  const SizedBox(height: 12),
                  const Text('Dashboard',
                      style: TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Importancia
// ─────────────────────────────────────────────────────────────────────────────
class _ImportanceSection extends StatelessWidget {
  const _ImportanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_dark, _darkAlt],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _aqua.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _aqua.withOpacity(0.3)),
            ),
            child: const Text('¿POR QUÉ IMPORTA?',
                style: TextStyle(
                    color: _aqua,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2)),
          ),
          const SizedBox(height: 18),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2),
              children: [
                TextSpan(text: 'La importancia de\n'),
                TextSpan(
                    text: 'manejar tus finanzas',
                    style: TextStyle(color: _aqua)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'La mayoría vivimos sin saber realmente a dónde va nuestro dinero.\nEso cambia cuando empiezas a llevar el control.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 15, height: 1.7),
          ),
          const SizedBox(height: 52),

          // Stats row
          Row(
            children: const [
              Expanded(
                  child:
                      _StatBubble('💸', '80%', 'no sabe cuánto gasta al mes')),
              SizedBox(width: 12),
              Expanded(
                  child: _StatBubble(
                      '📉', '68%', 'no tiene fondo de emergencias')),
              SizedBox(width: 12),
              Expanded(
                  child: _StatBubble(
                      '🎯', '2.5×', 'más probabilidad de lograr metas')),
              SizedBox(width: 12),
              Expanded(
                  child: _StatBubble(
                      '⏱️', '3 min', 'al día es suficiente para el control')),
            ],
          ),

          const SizedBox(height: 52),

          // Reasons grid — 3 columns × 2 rows con Row
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(
                      child: _ReasonCard(
                          Icons.visibility_rounded,
                          'Claridad financiera',
                          'Saber exactamente qué entra y qué sale elimina la ansiedad y te da poder de decisión.')),
                  SizedBox(width: 14),
                  Expanded(
                      child: _ReasonCard(
                          Icons.savings_rounded,
                          'Construye tu futuro',
                          'Cada peso registrado es un paso hacia tus metas: viajes, casa, educación o tranquilidad.')),
                  SizedBox(width: 14),
                  Expanded(
                      child: _ReasonCard(
                          Icons.emergency_rounded,
                          'Prepárate para emergencias',
                          'Las personas que llevan control financiero responden mejor a imprevistos sin endeudarse.')),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(
                      child: _ReasonCard(
                          Icons.trending_up_rounded,
                          'Elimina deudas más rápido',
                          'Identificar gastos innecesarios libera dinero para pagar deudas y salir del ciclo antes.')),
                  SizedBox(width: 14),
                  Expanded(
                      child: _ReasonCard(
                          Icons.psychology_rounded,
                          'Reduce el estrés',
                          'El desorden financiero es una de las principales causas de estrés. El control da paz mental.')),
                  SizedBox(width: 14),
                  Expanded(
                      child: _ReasonCard(Icons.star_rounded, 'Mejores hábitos',
                          'Registrar tus finanzas diariamente crea hábitos que se vuelven naturales y transforman tu vida.')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String emoji, value, desc;
  const _StatBubble(this.emoji, this.value, this.desc);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFFE6FAF8),
                  fontSize: 28,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(desc,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 12.5, height: 1.5)),
        ],
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  const _ReasonCard(this.icon, this.title, this.desc);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: _aqua.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _aqua, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(desc,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nuestras Funciones
// ─────────────────────────────────────────────────────────────────────────────
class _FunctionsSection extends StatelessWidget {
  const _FunctionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 88),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _blue.withOpacity(0.20)),
            ),
            child: const Text('NUESTRAS FUNCIONES',
                style: TextStyle(
                    color: _blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2)),
          ),
          const SizedBox(height: 18),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _dark,
                  height: 1.2),
              children: [
                TextSpan(text: 'Todo lo que necesitas para\n'),
                TextSpan(
                    text: 'dominar tus finanzas',
                    style: TextStyle(color: _blue)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Fimakyp combina herramientas poderosas en una interfaz simple y elegante.',
            style: TextStyle(color: _grey, fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 52),
          // 3 × 3 con Row/Column
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(
                      child: _FeatCard(
                          Icons.account_balance_wallet_rounded,
                          _blue,
                          'Múltiples cuentas',
                          'Efectivo, débito, crédito e inversiones en una sola vista unificada.')),
                  SizedBox(width: 14),
                  Expanded(
                      child: _FeatCard(
                          Icons.savings_rounded,
                          _aqua,
                          'Metas de ahorro',
                          'Crea objetivos con montos y fechas. Visualiza tu progreso en tiempo real.')),
                  SizedBox(width: 14),
                  Expanded(
                      child: _FeatCard(
                          Icons.picture_as_pdf_rounded,
                          _purple,
                          'Reportes PDF',
                          'Genera reportes financieros con gráficas y narrativa inteligente.')),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(
                      child: _FeatCard(
                          Icons.repeat_rounded,
                          _blue,
                          'Gastos recurrentes',
                          'Programa cobros automáticos y nunca pierdas un vencimiento.')),
                  SizedBox(width: 14),
                  Expanded(
                      child: _FeatCard(
                          Icons.notifications_active_rounded,
                          _aqua,
                          'Notificaciones',
                          'Recibe recordatorios diarios personalizados para mantener el hábito.')),
                  SizedBox(width: 14),
                  Expanded(
                      child: _FeatCard(
                          Icons.emoji_events_rounded,
                          _purple,
                          'Gamificación',
                          'Gana insignias, mantén rachas y mantente motivado con logros.')),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(
                      child: _FeatCard(
                          Icons.bar_chart_rounded,
                          _blue,
                          'Estadísticas',
                          'Gráficas con tus patrones de gasto por categoría y mes.')),
                  SizedBox(width: 14),
                  Expanded(
                      child: _FeatCard(
                          Icons.cloud_sync_rounded,
                          _aqua,
                          'Sincronización',
                          'Tus datos siempre actualizados en todos tus dispositivos al instante.')),
                  SizedBox(width: 14),
                  Expanded(
                      child: _FeatCard(
                          Icons.lock_rounded,
                          _purple,
                          'Seguridad total',
                          'Firebase Auth + cifrado. Tu información nunca se comparte.')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title, desc;
  const _FeatCard(this.icon, this.color, this.title, this.desc);
  @override
  State<_FeatCard> createState() => _FeatCardState();
}

class _FeatCardState extends State<_FeatCard> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: _h ? widget.color.withOpacity(0.35) : _border),
          boxShadow: _h
              ? [
                  BoxShadow(
                      color: widget.color.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6))
                ]
              : const [
                  BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 6,
                      offset: Offset(0, 2))
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.title,
                      style: const TextStyle(
                          color: _dark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Text(widget.desc,
                      style: const TextStyle(
                          color: _grey, fontSize: 12.5, height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cómo funciona
// ─────────────────────────────────────────────────────────────────────────────
class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 88),
      child: Column(
        children: [
          const Text('CÓMO FUNCIONA',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _aqua,
                  letterSpacing: 2.5)),
          const SizedBox(height: 14),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w800, color: _dark),
              children: [
                TextSpan(text: 'Empieza en '),
                TextSpan(
                    text: '3 simples pasos', style: TextStyle(color: _blue)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Configurar Fimakyp toma menos de 2 minutos.',
              style: TextStyle(color: _grey, fontSize: 15)),
          const SizedBox(height: 52),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(
                  child: _StepCard(
                      '01',
                      Icons.person_add_rounded,
                      'Crea tu cuenta',
                      'Regístrate con tu correo en menos de 30 segundos. Sin tarjeta de crédito.')),
              SizedBox(width: 8),
              Padding(
                padding: EdgeInsets.only(top: 44),
                child:
                    Icon(Icons.arrow_forward_rounded, color: _greyLt, size: 22),
              ),
              SizedBox(width: 8),
              Expanded(
                  child: _StepCard(
                      '02',
                      Icons.account_balance_wallet_rounded,
                      'Agrega tus cuentas',
                      'Registra efectivo, débito o crédito con el saldo inicial que tengas hoy.')),
              SizedBox(width: 8),
              Padding(
                padding: EdgeInsets.only(top: 44),
                child:
                    Icon(Icons.arrow_forward_rounded, color: _greyLt, size: 22),
              ),
              SizedBox(width: 8),
              Expanded(
                  child: _StepCard(
                      '03',
                      Icons.trending_up_rounded,
                      'Toma el control',
                      'Registra ingresos y gastos, crea metas y genera reportes PDF.')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatefulWidget {
  final String number, title, desc;
  final IconData icon;
  const _StepCard(this.number, this.icon, this.title, this.desc);
  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _h ? _bgAlt : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _h ? _blue.withOpacity(0.30) : const Color(0xFFE0F2FE)),
          boxShadow: _h
              ? [
                  BoxShadow(
                      color: _blue.withOpacity(0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 8))
                ]
              : const [
                  BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_blue, _aqua]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 22),
                ),
                const Spacer(),
                Text(widget.number,
                    style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: _blue.withOpacity(0.08))),
              ],
            ),
            const SizedBox(height: 18),
            Text(widget.title,
                style: const TextStyle(
                    color: _dark, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(widget.desc,
                style: const TextStyle(
                    color: _grey, fontSize: 13.5, height: 1.65)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats
// ─────────────────────────────────────────────────────────────────────────────
class _StatsSection extends StatelessWidget {
  const _StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 88),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _dark,
                  height: 1.2),
              children: [
                TextSpan(text: 'Números que\n'),
                TextSpan(
                    text: 'nos respaldan.', style: TextStyle(color: _blue)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Fimakyp crece cada día con usuarios que confían en la app para alcanzar sus metas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _grey, fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 48),
          Row(
            children: const [
              Expanded(
                  child:
                      _StatCard(Icons.download_rounded, '10 K+', 'Descargas')),
              SizedBox(width: 14),
              Expanded(
                  child: _StatCard(
                      Icons.people_rounded, '500+', 'Usuarios activos')),
              SizedBox(width: 14),
              Expanded(
                  child: _StatCard(Icons.star_rounded, '4.9★', 'Calificación')),
              SizedBox(width: 14),
              Expanded(
                  child: _StatCard(Icons.emoji_events_rounded, '50+',
                      'Insignias disponibles')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final IconData icon;
  final String value, label;
  const _StatCard(this.icon, this.value, this.label);
  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: _h ? _bgAlt : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _h ? _blue.withOpacity(0.25) : _border),
          boxShadow: _h
              ? [BoxShadow(color: _blue.withOpacity(0.08), blurRadius: 16)]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: _blue, size: 28),
            const SizedBox(height: 10),
            Text(widget.value,
                style: const TextStyle(
                    color: _dark, fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _grey, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nosotros
// ─────────────────────────────────────────────────────────────────────────────
class _AboutSection extends StatelessWidget {
  const _AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 88),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _aqua.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _aqua.withOpacity(0.20)),
            ),
            child: const Text('NOSOTROS',
                style: TextStyle(
                    color: _aquaDk,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2)),
          ),
          const SizedBox(height: 18),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w800, color: _dark),
              children: [
                TextSpan(text: 'Construido con '),
                TextSpan(text: 'propósito', style: TextStyle(color: _aquaDk)),
                TextSpan(text: ',\npara personas reales'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: const Text(
              'Fimakyp nació de una necesidad real: una app de finanzas que funcione en Colombia, '
              'que hable en pesos y que realmente ayude a construir mejores hábitos con el dinero.\n\n'
              'No somos un banco ni una startup de millones — somos personas que también estamos aprendiendo '
              'a manejar mejor nuestras finanzas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: _grey, height: 1.8),
            ),
          ),
          const SizedBox(height: 44),
          // Quote
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _bgAlt,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _blue.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: _blue.withOpacity(0.10), shape: BoxShape.circle),
                  child: const Icon(Icons.format_quote_rounded,
                      color: _blue, size: 28),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Text(
                    '"El primer paso para manejar bien el dinero\nes saber exactamente a dónde va."',
                    style: TextStyle(
                        fontSize: 16,
                        color: _dark,
                        fontStyle: FontStyle.italic,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 44),
          // Values
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(
                  child: _ValCard(
                      Icons.favorite_rounded,
                      _blue,
                      'Simple primero',
                      'Cada función existe porque la necesitas, sin complicaciones.')),
              SizedBox(width: 14),
              Expanded(
                  child: _ValCard(
                      Icons.security_rounded,
                      _aqua,
                      'Datos seguros',
                      'Nunca vendemos ni compartimos tu información financiera.')),
              SizedBox(width: 14),
              Expanded(
                  child: _ValCard(
                      Icons.emoji_people_rounded,
                      _purple,
                      'Hecho para LATAM',
                      'Pensado desde Colombia para toda latinoamérica, en pesos.')),
              SizedBox(width: 14),
              Expanded(
                  child: _ValCard(
                      Icons.trending_up_rounded,
                      _blue,
                      'Siempre mejorando',
                      'Cada actualización nace del feedback de nuestros usuarios.')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title, desc;
  const _ValCard(this.icon, this.color, this.title, this.desc);
  @override
  State<_ValCard> createState() => _ValCardState();
}

class _ValCardState extends State<_ValCard> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _h ? widget.color.withOpacity(0.07) : _bg,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: _h ? widget.color.withOpacity(0.25) : _border),
          boxShadow: _h
              ? [
                  BoxShadow(
                      color: widget.color.withOpacity(0.10), blurRadius: 20)
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(widget.title,
                style: const TextStyle(
                    color: _dark, fontSize: 14.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(widget.desc,
                style: const TextStyle(
                    color: _grey, fontSize: 12.5, height: 1.55)),
          ],
        ),
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_bgAlt, _bg],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_blue, _purple]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.rocket_launch_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 24),
          const Text(
            '¿Listo para tomar\ncontrol de tu dinero?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: _dark,
                height: 1.15),
          ),
          const SizedBox(height: 16),
          const Text(
            'Empieza hoy. Tu yo del futuro te lo va a agradecer.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: _grey, height: 1.6),
          ),
          const SizedBox(height: 36),
          OutlinedButton(
                onPressed: () => context.go('/login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _blue,
                  minimumSize: const Size(160, 48),
                  side: const BorderSide(color: _blue, width: 1.5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Ya tengo cuenta',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
  const _Footer();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _dark,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 52),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Image.asset('assets/images/LogoFimakyp.png',
                            width: 28,
                            height: 28,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: _blue,
                                size: 24)),
                        const SizedBox(width: 10),
                        const Text('Fimakyp',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 17)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                        'La app de finanzas personales\npara latinoamérica.',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 13, height: 1.6)),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                  flex: 2,
                  child: _FCol(
                      'Producto', ['Funciones', 'Cómo funciona', 'Descargar'])),
              Expanded(
                  flex: 2,
                  child: _FCol('Empresa', ['Nosotros', 'Blog', 'Contacto'])),
              Expanded(
                  flex: 2,
                  child: _FCol(
                      'Legal', ['Privacidad', 'Términos de uso', 'Cookies'])),
            ],
          ),
          const SizedBox(height: 36),
          const Divider(color: Color(0xFF1E293B), thickness: 1),
          const SizedBox(height: 18),
          const Text(
              '© 2025 Fimakyp · Finanzas inteligentes para latinoamérica',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
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
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13.5)),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Text(item,
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 12.5)),
            )),
      ],
    );
  }
}
