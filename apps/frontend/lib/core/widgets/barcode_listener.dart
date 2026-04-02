import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps [child] and listens for USB/HID barcode scanner input globally.
///
/// USB barcode scanners emulate a keyboard: they send characters very rapidly
/// (< 50 ms apart) and terminate the sequence with an Enter key. This listener
/// accumulates those characters using [HardwareKeyboard.instance.addHandler],
/// which is focus-independent — it works even when a text field is focused.
///
/// The 100 ms threshold distinguishes scanner bursts from manual typing.
class BarcodeScannerListener extends StatefulWidget {
  final Widget child;
  final void Function(String barcode) onBarcodeScanned;

  const BarcodeScannerListener({
    super.key,
    required this.child,
    required this.onBarcodeScanned,
  });

  @override
  State<BarcodeScannerListener> createState() => _BarcodeScannerListenerState();
}

class _BarcodeScannerListenerState extends State<BarcodeScannerListener> {
  String _buffer = '';
  DateTime? _lastKeyPress;

  static const _threshold = Duration(milliseconds: 100);
  static final _validChar = RegExp(r'^[A-Za-z0-9\-\.\$\/\+\% ]+$');

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final now = DateTime.now();
    final isRapid = _lastKeyPress == null ||
        now.difference(_lastKeyPress!) < _threshold;
    _lastKeyPress = now;

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_buffer.length >= 3) {
        widget.onBarcodeScanned(_buffer);
      }
      _buffer = '';
      // Don't consume Enter — other widgets (e.g. text fields) still need it.
      return false;
    }

    final char = event.character;
    if (char != null && _validChar.hasMatch(char)) {
      _buffer = isRapid ? (_buffer + char) : char;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
