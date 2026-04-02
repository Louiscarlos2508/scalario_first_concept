import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

// ── Types ──────────────────────────────────────────────────────────────────────

enum PrinterType {
  bluetoothEscPos, // BLE — Android / iOS / Desktop
  networkEscPos,   // TCP socket — all platforms with dart:io
  usbEscPos,       // USB serial — Desktop (Windows / Linux / macOS)
}

enum PaperWidth { mm80, mm58 }

// ── Model ──────────────────────────────────────────────────────────────────────

class PrinterConfig {
  final PrinterType type;
  final String? networkIp;
  final int networkPort;
  final String? bluetoothAddress;
  final String? bluetoothName;
  final String? usbDevicePath; // e.g. COM3 (Windows) or /dev/usb/lp0 (Linux)
  final PaperWidth paperWidth;

  const PrinterConfig({
    this.type = PrinterType.bluetoothEscPos,
    this.networkIp,
    this.networkPort = 9100,
    this.bluetoothAddress,
    this.bluetoothName,
    this.usbDevicePath,
    this.paperWidth = PaperWidth.mm80,
  });

  PrinterConfig copyWith({
    PrinterType? type,
    String? networkIp,
    int? networkPort,
    String? bluetoothAddress,
    String? bluetoothName,
    String? usbDevicePath,
    PaperWidth? paperWidth,
  }) =>
      PrinterConfig(
        type: type ?? this.type,
        networkIp: networkIp ?? this.networkIp,
        networkPort: networkPort ?? this.networkPort,
        bluetoothAddress: bluetoothAddress ?? this.bluetoothAddress,
        bluetoothName: bluetoothName ?? this.bluetoothName,
        usbDevicePath: usbDevicePath ?? this.usbDevicePath,
        paperWidth: paperWidth ?? this.paperWidth,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'networkIp': networkIp,
        'networkPort': networkPort,
        'bluetoothAddress': bluetoothAddress,
        'bluetoothName': bluetoothName,
        'usbDevicePath': usbDevicePath,
        'paperWidth': paperWidth.name,
      };

  /// Returns the sensible default for this device:
  /// - Mobile (Android/iOS) → Bluetooth (paired via OS)
  /// - Desktop/Web          → USB on desktop, Network on web
  factory PrinterConfig.platformDefault() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      return const PrinterConfig(type: PrinterType.bluetoothEscPos);
    }
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return const PrinterConfig(type: PrinterType.usbEscPos);
    }
    return const PrinterConfig(type: PrinterType.networkEscPos);
  }

  factory PrinterConfig.fromJson(Map<String, dynamic> json) => PrinterConfig(
        type: PrinterType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => PrinterType.bluetoothEscPos,
        ),
        networkIp: json['networkIp'] as String?,
        networkPort: (json['networkPort'] as num?)?.toInt() ?? 9100,
        bluetoothAddress: json['bluetoothAddress'] as String?,
        bluetoothName: json['bluetoothName'] as String?,
        usbDevicePath: json['usbDevicePath'] as String?,
        paperWidth: PaperWidth.values.firstWhere(
          (e) => e.name == json['paperWidth'],
          orElse: () => PaperWidth.mm80,
        ),
      );
}

// ── Persistence ────────────────────────────────────────────────────────────────

const _kPrefKey = 'printer_config';

Future<PrinterConfig> loadPrinterConfig() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPrefKey);
  if (raw == null) return PrinterConfig.platformDefault();
  try {
    return PrinterConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return PrinterConfig.platformDefault();
  }
}

Future<void> savePrinterConfig(PrinterConfig config) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kPrefKey, jsonEncode(config.toJson()));
}
