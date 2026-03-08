import 'dart:async';
import 'package:flutter/services.dart';
import 'package:frontend/features/pos/data/repositories/product_repository.dart';
import 'package:frontend/features/pos/presentation/state/cart_notifier.dart';

class BarcodeScannerService {
  final ProductRepository _productRepository;
  final CartNotifier _cartNotifier;
  
  String _buffer = '';
  DateTime? _lastKeyPress;
  
  // Barcode scanners usually send keys within 10-50ms of each other.
  // 100ms is a safe threshold to distinguish from manual typing.
  static const _keyboardThreshold = Duration(milliseconds: 100);

  BarcodeScannerService(this._productRepository, this._cartNotifier);

  void init() {
    RawKeyboard.instance.addListener(_handleKeyEvent);
    print('[BarcodeScanner] Global listener initialized');
  }

  void dispose() {
    RawKeyboard.instance.removeListener(_handleKeyEvent);
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    final now = DateTime.now();
    final character = event.character;

    // Detect if this is a "rapid" sequence
    final isRapid = _lastKeyPress == null || now.difference(_lastKeyPress!) < _keyboardThreshold;
    _lastKeyPress = now;

    // If "Enter" is pressed and we have a buffer, process it
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_buffer.isNotEmpty && _buffer.length >= 3) {
        _processBarcode(_buffer);
      }
      _buffer = '';
      return;
    }

    if (character != null && _isNumeric(character)) {
      if (!isRapid) {
        // Not rapid enough to be a scanner, reset buffer
        _buffer = character;
      } else {
        _buffer += character;
      }
    }
  }

  bool _isNumeric(String s) {
    return RegExp(r'^[0-9]+$').hasMatch(s);
  }

  Future<void> _processBarcode(String barcode) async {
    print('[BarcodeScanner] Detected barcode: $barcode');
    try {
      final product = await _productRepository.getProductByBarcode(barcode);
      if (product != null) {
        _cartNotifier.addProduct(product);
        print('[BarcodeScanner] Added product: ${product.name}');
      } else {
        print('[BarcodeScanner] Product not found for barcode: $barcode');
      }
    } catch (e) {
      print('[BarcodeScanner] Error looking up barcode: $e');
    }
  }
}
