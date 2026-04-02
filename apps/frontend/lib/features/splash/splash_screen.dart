import 'package:flutter/material.dart';

/// Splash screen Scalario — fond navy + logo animé + CTA "Commencer".
///
/// Séquence :
///   S arcs draw-on   (100–860 ms, calqué sur splash_animation_preview.html)
///   CALARIO fade-in  (820–1220 ms)
///   Wordmark section fade-up (300–1100 ms, delay 0.3s)
///   Tagline fade-up  (700–1500 ms, delay 0.7s)
///   Bottom fade-up   (1100–1900 ms, delay 1.1s)
///   CTA glow pulse   (2 s infinite, démarre à 1 800 ms)
///   → widget.onComplete() déclenché par appui sur "Commencer"
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _glowCtrl;

  // S arcs draw-on (PathMetrics progress 0→1)
  late final Animation<double> _arc1, _arc2, _arc3, _arc4;
  // CALARIO text fade
  late final Animation<double> _calarioOpacity;
  // Section entrances
  late final Animation<double> _wordmarkOpacity, _wordmarkY;
  late final Animation<double> _taglineOpacity, _taglineY;
  late final Animation<double> _bottomOpacity, _bottomY;

  static const _kTotal = 2000.0;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // S arcs draw-on — timing from splash_animation_preview.html
    _arc1 = _iv(100, 320, Curves.easeInOut);
    _arc2 = _iv(280, 500, Curves.easeInOut);
    _arc3 = _iv(460, 680, Curves.easeInOut);
    _arc4 = _iv(640, 860, Curves.easeInOut);

    // CALARIO: fades in once arcs are nearly done
    _calarioOpacity = _iv(820, 1220, Curves.ease);

    // Wordmark section fade-up (0.3s → 1.1s)
    _wordmarkOpacity = _iv(300, 1100, Curves.easeOut);
    _wordmarkY       = _iv(300, 1100, Curves.easeOut);

    // Tagline (0.7s → 1.5s)
    _taglineOpacity = _iv(700, 1500, Curves.easeOut);
    _taglineY       = _iv(700, 1500, Curves.easeOut);

    // Bottom: dots + CTA + legal (1.1s → 1.9s)
    _bottomOpacity = _iv(1100, 1900, Curves.easeOut);
    _bottomY       = _iv(1100, 1900, Curves.easeOut);

    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _glowCtrl.repeat();
    });
  }

  Animation<double> _iv(double from, double to, Curve curve) =>
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(from / _kTotal, to / _kTotal, curve: curve),
      );

  @override
  void dispose() {
    _ctrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_ctrl, _glowCtrl]),
          builder: (context, _) => Column(
            children: [
              const Spacer(),

              // ── Wordmark section ──────────────────────────────────────────
              Opacity(
                opacity: _wordmarkOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _wordmarkY.value)),
                  child: Column(
                    children: [
                      // S arcs + CALARIO
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 54,
                            height: 81,
                            child: CustomPaint(
                              painter: _LogoSPainter(
                                arc1: _arc1.value,
                                arc2: _arc2.value,
                                arc3: _arc3.value,
                                arc4: _arc4.value,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Opacity(
                            opacity: _calarioOpacity.value,
                            child: const Text(
                              'CALARIO',
                              style: TextStyle(
                                fontFamily: 'Impact',
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Tagline
                      Opacity(
                        opacity: _taglineOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, 16 * (1 - _taglineY.value)),
                          child: const Text(
                            'Gérez votre boutique.\nSachez ce qui se passe.\nDepuis n\'importe où.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white54,
                              height: 1.75,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // ── Bottom section ────────────────────────────────────────────
              Opacity(
                opacity: _bottomOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _bottomY.value)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                    child: Column(
                      children: [
                        // Bouncing dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _BounceDot(delayMs: 0),
                            const SizedBox(width: 8),
                            _BounceDot(delayMs: 180),
                            const SizedBox(width: 8),
                            _BounceDot(delayMs: 360),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // CTA avec glow pulse
                        _GlowCta(
                          glowValue: _glowCtrl.value,
                          onTap: widget.onComplete,
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'En continuant, vous acceptez\nles conditions d\'utilisation de Scalario',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white24,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bouncing dot ──────────────────────────────────────────────────────────────

class _BounceDot extends StatefulWidget {
  final int delayMs;
  const _BounceDot({required this.delayMs});

  @override
  State<_BounceDot> createState() => _BounceDotState();
}

class _BounceDotState extends State<_BounceDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _y;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    // bounce: go up at 40%, back at 80%
    _y = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -7.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: -7.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 40),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
    ]).animate(_ctrl);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.35), weight: 40),
      TweenSequenceItem(tween: ConstantTween(0.35), weight: 20),
    ]).animate(_ctrl);

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.repeat();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Transform.translate(
        offset: Offset(0, _y.value),
        child: Opacity(
          opacity: _opacity.value,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ── CTA with glow pulse ───────────────────────────────────────────────────────

class _GlowCta extends StatelessWidget {
  final double glowValue;
  final VoidCallback onTap;

  const _GlowCta({required this.glowValue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // glow: 0→10px shadow spread → 0 (like HTML keyframes)
    final spreadRadius = glowValue * 10;
    final shadowOpacity = (1 - glowValue) * 0.3;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: shadowOpacity),
              spreadRadius: spreadRadius,
              blurRadius: spreadRadius * 1.5,
            ),
          ],
        ),
        child: const Text(
          'Commencer',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}

// ── CustomPainter — S Scalario ────────────────────────────────────────────────
//
// viewBox "32 20 64 90" (identique splash_animation_preview.html)
// strokeWidth 10.0 SVG units → ~8.4 dp rendu

class _LogoSPainter extends CustomPainter {
  const _LogoSPainter({
    required this.arc1,
    required this.arc2,
    required this.arc3,
    required this.arc4,
  });

  final double arc1, arc2, arc3, arc4;

  static const double _vbX = 32.0;
  static const double _vbY = 20.0;
  static const double _vbW = 64.0;
  static const double _vbH = 90.0;

  static final Path _path1 = Path()
    ..moveTo(64, 24)
    ..cubicTo(48, 24, 36, 34, 36, 48);
  static final Path _path2 = Path()
    ..moveTo(36, 48)
    ..cubicTo(36, 60, 48, 66, 64, 66);
  static final Path _path3 = Path()
    ..moveTo(64, 66)
    ..cubicTo(78, 66, 90, 72, 90, 86);
  static final Path _path4 = Path()
    ..moveTo(90, 86)
    ..cubicTo(90, 98, 78, 106, 64, 106);

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _vbW;
    final scaleY = size.height / _vbH;

    canvas.save();
    canvas.translate(-_vbX * scaleX, -_vbY * scaleY);
    canvas.scale(scaleX, scaleY);

    _drawArc(canvas, _path1, arc1, const Color(0xFFFFCC00));
    _drawArc(canvas, _path2, arc2, const Color(0xFF1A73E8));
    _drawArc(canvas, _path3, arc3, const Color(0xFF34A853));
    _drawArc(canvas, _path4, arc4, const Color(0xFFEA4335));

    canvas.restore();
  }

  static void _drawArc(Canvas canvas, Path path, double progress, Color color) {
    if (progress <= 0) return;
    final metric = path.computeMetrics().first;
    final drawn =
        metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0));
    canvas.drawPath(
      drawn,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_LogoSPainter old) =>
      old.arc1 != arc1 ||
      old.arc2 != arc2 ||
      old.arc3 != arc3 ||
      old.arc4 != arc4;
}
