import 'package:flutter/material.dart';

/// Splash screen Scalario — logo S animé + texte CALARIO.
///
/// Séquence (1 400 ms total, AnimationController unique) :
///   0–200 ms     Arc 1 jaune  draw-on via PathMetrics
///   250–450 ms   Arc 2 bleu
///   500–700 ms   Arc 3 vert
///   750–950 ms   Arc 4 rouge
///   800–1200 ms  "CALARIO" fade-in
///   1 400 ms     → widget.onComplete()
///
/// Thème :
///   fond  = Theme.of(context).scaffoldBackgroundColor
///   texte = Theme.of(context).colorScheme.onSurface
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Arc draw-on animations (PathMetrics progress 0→1)
  late final Animation<double> _arc1;
  late final Animation<double> _arc2;
  late final Animation<double> _arc3;
  late final Animation<double> _arc4;

  // Text fade-in
  late final Animation<double> _textOpacity;

  static const double _total = 1400.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _arc1 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0 / _total, 200 / _total, curve: Curves.easeInOut),
    );
    _arc2 = CurvedAnimation(
      parent: _controller,
      curve:
          const Interval(250 / _total, 450 / _total, curve: Curves.easeInOut),
    );
    _arc3 = CurvedAnimation(
      parent: _controller,
      curve:
          const Interval(500 / _total, 700 / _total, curve: Curves.easeInOut),
    );
    _arc4 = CurvedAnimation(
      parent: _controller,
      curve:
          const Interval(750 / _total, 950 / _total, curve: Curves.easeInOut),
    );
    _textOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(800 / _total, 1200 / _total, curve: Curves.easeIn),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Le "S" stylisé — 4 arcs Bézier en couleurs Google
                SizedBox(
                  width: 60,
                  height: 90,
                  child: CustomPaint(
                    painter: _LogoSPainter(
                      arc1: _arc1.value,
                      arc2: _arc2.value,
                      arc3: _arc3.value,
                      arc4: _arc4.value,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // "CALARIO" — fade-in en décalé
                Opacity(
                  opacity: _textOpacity.value,
                  child: Text(
                    'CALARIO',
                    style: TextStyle(
                      fontFamily: 'Impact',
                      fontSize: 60,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: textColor,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainter — S Scalario (4 arcs Bézier cubiques, coordonnées SVG)
// ---------------------------------------------------------------------------

class _LogoSPainter extends CustomPainter {
  const _LogoSPainter({
    required this.arc1,
    required this.arc2,
    required this.arc3,
    required this.arc4,
  });

  final double arc1;
  final double arc2;
  final double arc3;
  final double arc4;

  // Bornes du S dans le viewBox SVG 220×130
  static const double _svgLeft = 36.0;
  static const double _svgTop = 24.0;
  static const double _svgW = 54.0; // 90 - 36
  static const double _svgH = 82.0; // 106 - 24

  // Chemins en coordonnées SVG (statiques — données immuables)
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
    final scaleX = size.width / _svgW;
    final scaleY = size.height / _svgH;

    canvas.save();
    // Mappe les coordonnées SVG → espace Flutter :
    //   screen_x = (svgX - _svgLeft) * scaleX
    //   screen_y = (svgY - _svgTop)  * scaleY
    canvas.translate(-_svgLeft * scaleX, -_svgTop * scaleY);
    canvas.scale(scaleX, scaleY);

    _drawArc(canvas, _path1, arc1, const Color(0xFFFFCC00));
    _drawArc(canvas, _path2, arc2, const Color(0xFF1A73E8));
    _drawArc(canvas, _path3, arc3, const Color(0xFF34A853));
    _drawArc(canvas, _path4, arc4, const Color(0xFFEA4335));

    canvas.restore();
  }

  static void _drawArc(
    Canvas canvas,
    Path path,
    double progress,
    Color color,
  ) {
    if (progress <= 0) return;
    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(
      0,
      metric.length * progress.clamp(0.0, 1.0),
    );
    canvas.drawPath(
      drawn,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
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
