import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

const _kDark = Color(0xFF0F172A);
const _kGreen = Color(0xFF34A853);
const _kBlue = Color(0xFF4F8EF7);

Future<String?> openCameraScanner(BuildContext context) {
  return Navigator.push<String>(
    context,
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) => const CameraScannerDialog(),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 220),
    ),
  );
}

class CameraScannerDialog extends StatefulWidget {
  const CameraScannerDialog({super.key});

  @override
  State<CameraScannerDialog> createState() => _CameraScannerDialogState();
}

class _CameraScannerDialogState extends State<CameraScannerDialog>
    with SingleTickerProviderStateMixin {
  final _scannerCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _scanned = false;
  bool _torchOn = false;

  late final AnimationController _lineAnim;
  late final Animation<double> _linePos;

  @override
  void initState() {
    super.initState();
    _lineAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _linePos = CurvedAnimation(parent: _lineAnim, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    _lineAnim.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;
    _scanned = true;
    _lineAnim.stop();
    // Await stop — camera must be fully halted before popping to avoid
    // BufferQueue abandoned errors and the Camera2 priority-change loop.
    await _scannerCtrl.stop();
    if (!mounted) return;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 260));
    if (mounted) Navigator.pop(context, barcode);
  }

  void _toggleTorch() {
    _scannerCtrl.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Camera feed ──────────────────────────────────────────────────
            MobileScanner(
              controller: _scannerCtrl,
              errorBuilder: (context, error) =>
                  _BarcodeFallback(onSubmit: (v) => Navigator.pop(context, v)),
              onDetect: _onDetect,
            ),

            // ── Scan overlay (dark mask + corners + animated line) ────────────
            AnimatedBuilder(
              animation: _linePos,
              builder: (_, _) => CustomPaint(
                painter: _ScanOverlayPainter(
                  linePos: _linePos.value,
                  scanned: _scanned,
                ),
                child: const SizedBox.expand(),
              ),
            ),

            // ── Top bar ───────────────────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                bottom: false,
                child: Container(
                  height: 56,
                  color: Colors.black.withValues(alpha: 0.45),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Fermer',
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text(
                        'Scanner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: _torchOn ? Colors.amber : Colors.white60,
                        ),
                        tooltip: _torchOn ? 'Éteindre la torche' : 'Allumer la torche',
                        onPressed: _toggleTorch,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom hint ───────────────────────────────────────────────────
            Positioned(
              bottom: 56, left: 0, right: 0,
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: _scanned ? _kGreen : Colors.white70,
                    fontSize: 13,
                    fontWeight: _scanned ? FontWeight.w600 : FontWeight.normal,
                  ),
                  child: Text(_scanned ? 'Code détecté ✓' : 'Pointez le code-barres dans le cadre'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Overlay painter ───────────────────────────────────────────────────────────

class _ScanOverlayPainter extends CustomPainter {
  final double linePos;
  final bool scanned;

  const _ScanOverlayPainter({required this.linePos, required this.scanned});

  @override
  void paint(Canvas canvas, Size size) {
    final scanSize = size.width * 0.72;
    final left = (size.width - scanSize) / 2;
    final top = (size.height - scanSize) / 2 - 32;
    final rect = Rect.fromLTWH(left, top, scanSize, scanSize);

    // ── Dark mask outside scan rect ─────────────────────────────────────────
    final mask = Paint()..color = Colors.black.withValues(alpha: 0.60);
    canvas
      ..drawRect(Rect.fromLTRB(0, 0, size.width, rect.top), mask)
      ..drawRect(Rect.fromLTRB(0, rect.top, rect.left, rect.bottom), mask)
      ..drawRect(Rect.fromLTRB(rect.right, rect.top, size.width, rect.bottom), mask)
      ..drawRect(Rect.fromLTRB(0, rect.bottom, size.width, size.height), mask);

    // ── Corner accents ──────────────────────────────────────────────────────
    final cornerColor = scanned ? _kGreen : Colors.white;
    final cp = Paint()
      ..color = cornerColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const cl = 26.0; // corner length

    // Top-left
    _corner(canvas, cp, rect.left, rect.top, cl, 1, 1);
    // Top-right
    _corner(canvas, cp, rect.right, rect.top, cl, -1, 1);
    // Bottom-left
    _corner(canvas, cp, rect.left, rect.bottom, cl, 1, -1);
    // Bottom-right
    _corner(canvas, cp, rect.right, rect.bottom, cl, -1, -1);

    // ── Animated scan line ──────────────────────────────────────────────────
    if (!scanned) {
      final lineY = rect.top + linePos * scanSize;
      final linePaint = Paint()
        ..shader = LinearGradient(colors: [
          Colors.transparent,
          _kBlue.withValues(alpha: 0.85),
          Colors.transparent,
        ]).createShader(Rect.fromLTWH(rect.left, lineY, scanSize, 2));
      canvas.drawRect(Rect.fromLTWH(rect.left, lineY - 1, scanSize, 2), linePaint);
    }
  }

  void _corner(Canvas canvas, Paint p, double x, double y, double len,
      double dx, double dy) {
    canvas
      ..drawLine(Offset(x, y), Offset(x + dx * len, y), p)
      ..drawLine(Offset(x, y), Offset(x, y + dy * len), p);
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter old) =>
      old.linePos != linePos || old.scanned != scanned;
}

// ── Fallback (camera unavailable) ────────────────────────────────────────────

class _BarcodeFallback extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  const _BarcodeFallback({required this.onSubmit});

  @override
  State<_BarcodeFallback> createState() => _BarcodeFallbackState();
}

class _BarcodeFallbackState extends State<_BarcodeFallback> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kDark,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              height: 56,
              color: Colors.black.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text('Scanner',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Fallback content
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.no_photography_outlined, size: 52, color: Colors.white24),
                      const SizedBox(height: 16),
                      const Text(
                        'Caméra non disponible',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Saisissez le code-barres manuellement',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _ctrl,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Code-barres',
                          labelStyle: const TextStyle(color: Colors.white54),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white24),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: _kBlue),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.06),
                        ),
                        onSubmitted: (v) { if (v.isNotEmpty) widget.onSubmit(v); },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _kBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () { if (_ctrl.text.isNotEmpty) widget.onSubmit(_ctrl.text); },
                          child: const Text('Valider'),
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
    );
  }
}
