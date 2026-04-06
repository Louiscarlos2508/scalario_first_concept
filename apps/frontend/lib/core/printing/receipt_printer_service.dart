import 'dart:io';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'printer_config.dart';
import 'receipt_data.dart';
import 'network_escpos_printer.dart';
import 'bluetooth_escpos_printer.dart';
import 'usb_escpos_printer.dart';

/// Routes a POS print job to the correct thermal printer.
///
/// PDF printing (invoices, sales history) goes through [ReceiptService]
/// in `core/services/receipt_service.dart` — not here.
class ReceiptPrinterService {
  ReceiptPrinterService._();

  static Future<void> print(ReceiptData data, PrinterConfig config) async {
    switch (config.type) {
      case PrinterType.bluetoothEscPos:
        await printBluetoothEscPos(data, config);
      case PrinterType.networkEscPos:
        await printNetworkEscPos(data, config);
      case PrinterType.usbEscPos:
        await printUsbEscPos(data, config);
    }
  }

  /// Sends pre-built ESC/POS bytes to the configured printer.
  /// Used for documents (e.g. Z-Report) that build their own byte list.
  static Future<void> printRawBytes(
      List<int> bytes, PrinterConfig config) async {
    switch (config.type) {
      case PrinterType.bluetoothEscPos:
        if (config.bluetoothAddress == null ||
            config.bluetoothAddress!.isEmpty) {
          throw Exception('Imprimante Bluetooth non configurée');
        }
        final connected = await PrintBluetoothThermal.connect(
          macPrinterAddress: config.bluetoothAddress!,
        );
        if (!connected) {
          throw Exception(
              'Connexion Bluetooth échouée — vérifiez que l\'imprimante est allumée et couplée');
        }
        try {
          final ok = await PrintBluetoothThermal.writeBytes(bytes);
          if (!ok) throw Exception('Échec d\'envoi des données à l\'imprimante');
        } finally {
          await PrintBluetoothThermal.disconnect;
        }

      case PrinterType.networkEscPos:
        if (config.networkIp == null || config.networkIp!.isEmpty) {
          throw Exception('Adresse IP imprimante non configurée');
        }
        final socket = await Socket.connect(
          config.networkIp!,
          config.networkPort,
          timeout: const Duration(seconds: 5),
        );
        try {
          socket.add(bytes);
          await socket.flush();
        } finally {
          await socket.close();
        }

      case PrinterType.usbEscPos:
        if (config.usbDevicePath == null || config.usbDevicePath!.isEmpty) {
          throw Exception('Chemin du périphérique USB non configuré');
        }
        final file = File(config.usbDevicePath!);
        final raf = await file.open(mode: FileMode.writeOnly);
        try {
          await raf.writeFrom(bytes);
          await raf.flush();
        } finally {
          await raf.close();
        }
    }
  }
}
