import 'dart:async';
import 'package:flutter/services.dart';
import 'package:frontend/features/retail/pos/data/repositories/product_repository.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_notifier.dart';

class ScanEvent {
  final bool found;
  final String barcode;
  final String? productName;

  const ScanEvent({
    required this.found,
    required this.barcode,
    this.productName,
  });
}

class BarcodeScannerService {
  final ProductRepository _productRepository;
  final CartNotifier _cartNotifier;

  String _buffer = '';
  DateTime? _lastKeyPress;

  // Barcode scanners send keys within 10-50ms of each other.
  // 100ms is a safe threshold to distinguish from manual typing.
  static const _keyboardThreshold = Duration(milliseconds: 100);

  final _eventController = StreamController<ScanEvent>.broadcast();
  Stream<ScanEvent> get events => _eventController.stream;

  BarcodeScannerService(this._productRepository, this._cartNotifier);

  void init() {
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _eventController.close();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final now = DateTime.now();
    final character = event.character;

    final isRapid = _lastKeyPress == null ||
        now.difference(_lastKeyPress!) < _keyboardThreshold;
    _lastKeyPress = now;

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_buffer.isNotEmpty && _buffer.length >= 3) {
        _processBarcode(_buffer);
      }
      _buffer = '';
      return true;
    }

    // Accept any printable character valid in standard barcode symbologies:
    // digits, letters, and common special chars (-, ., $, /, +, %, space)
    if (character != null && _isBarcodeChar(character)) {
      if (!isRapid) {
        _buffer = character;
      } else {
        _buffer += character;
      }
    }
    return false;
  }

  bool _isBarcodeChar(String s) {
    return RegExp(r'^[A-Za-z0-9\-\.\$\/\+\% ]+$').hasMatch(s);
  }

  Future<void> _processBarcode(String barcode) async {
    try {
      final product = await _productRepository.getProductByBarcode(barcode);
      if (product != null) {
        _cartNotifier.addProduct(product);
        _eventController.add(
          ScanEvent(found: true, barcode: barcode, productName: product.name),
        );
      } else {
        _eventController.add(ScanEvent(found: false, barcode: barcode));
      }
    } catch (_) {
      _eventController.add(ScanEvent(found: false, barcode: barcode));
    }
  }
}
