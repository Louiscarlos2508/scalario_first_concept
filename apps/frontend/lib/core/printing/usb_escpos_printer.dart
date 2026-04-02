import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'printer_config.dart';
import 'receipt_data.dart';
import 'escpos_builder.dart';

/// Lists USB/serial device paths available on this machine.
///
/// Linux   : /dev/usb/lp* + /dev/ttyUSB*
/// macOS   : /dev/cu.usb*
/// Windows : COM ports via wmic
Future<List<String>> listUsbPrinterPaths() async {
  if (kIsWeb) return [];

  if (Platform.isLinux) {
    final paths = <String>[];
    final usbDir = Directory('/dev/usb');
    if (await usbDir.exists()) {
      await for (final e in usbDir.list()) {
        paths.add(e.path);
      }
    }
    await for (final e in Directory('/dev').list()) {
      final name = e.path.split('/').last;
      if (name.startsWith('ttyUSB')) paths.add(e.path);
    }
    paths.sort();
    return paths;
  }

  if (Platform.isMacOS) {
    final paths = <String>[];
    await for (final e in Directory('/dev').list()) {
      final name = e.path.split('/').last;
      if (name.startsWith('cu.usb') || name.startsWith('cu.USB')) {
        paths.add(e.path);
      }
    }
    paths.sort();
    return paths;
  }

  if (Platform.isWindows) {
    try {
      final result = await Process.run(
          'wmic', ['path', 'Win32_SerialPort', 'get', 'DeviceID']);
      if (result.exitCode == 0) {
        return (result.stdout as String)
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.startsWith('COM'))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  return [];
}

/// Sends ESC/POS bytes to a USB thermal printer via device file path.
///
/// Windows : COM3, COM4, …
/// Linux   : /dev/usb/lp0, /dev/ttyUSB0, …
/// macOS   : /dev/usb/lp0, /dev/cu.usbserial-…
Future<void> printUsbEscPos(ReceiptData data, PrinterConfig config) async {
  if (config.usbDevicePath == null || config.usbDevicePath!.isEmpty) {
    throw Exception('Chemin du périphérique USB non configuré');
  }

  final bytes = await buildEscPosReceipt(data, config.paperWidth);

  final file = File(config.usbDevicePath!);
  final raf = await file.open(mode: FileMode.writeOnly);
  try {
    await raf.writeFrom(bytes);
    await raf.flush();
  } finally {
    await raf.close();
  }
}
