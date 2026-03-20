import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BarcodeScannerListener extends StatefulWidget {
  final Widget child;
  final Function(String barcode) onBarcodeScanned;

  const BarcodeScannerListener({
    super.key,
    required this.child,
    required this.onBarcodeScanned,
  });

  @override
  State<BarcodeScannerListener> createState() => _BarcodeScannerListenerState();
}

class _BarcodeScannerListenerState extends State<BarcodeScannerListener> {
  final List<String> _barcodeBuffer = [];
  DateTime? _lastKeyPressTime;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Ensure we keep focus for hardware scanner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          final now = DateTime.now();

          // Clear buffer if current key is too far from last (reset)
          // Scanners typically send keys < 20ms apart
          if (_lastKeyPressTime != null && now.difference(_lastKeyPressTime!).inMilliseconds > 100) {
            _barcodeBuffer.clear();
          }
          _lastKeyPressTime = now;

          if (event.logicalKey == LogicalKeyboardKey.enter) {
            if (_barcodeBuffer.isNotEmpty) {
              widget.onBarcodeScanned(_barcodeBuffer.join());
              _barcodeBuffer.clear();
            }
          } else if (event.character != null && event.character!.isNotEmpty) {
             _barcodeBuffer.add(event.character!);
          }
        }
      },
      child: widget.child,
    );
  }
}
