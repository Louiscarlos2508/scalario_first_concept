import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'printer_config.dart';
import 'receipt_data.dart';
import 'escpos_builder.dart';

/// Lists Bluetooth devices already paired at OS level.
Future<List<BluetoothInfo>> pairedBluetoothDevices() =>
    PrintBluetoothThermal.pairedBluetooths;

/// Sends ESC/POS bytes to a paired Classic Bluetooth thermal printer.
///
/// The printer must be paired in the OS Bluetooth settings beforehand.
/// [PrinterConfig.bluetoothAddress] = MAC address of the paired printer.
Future<void> printBluetoothEscPos(ReceiptData data, PrinterConfig config) async {
  if (config.bluetoothAddress == null || config.bluetoothAddress!.isEmpty) {
    throw Exception('Imprimante Bluetooth non configurée — sélectionnez-en une dans les paramètres');
  }

  final bytes = await buildEscPosReceipt(data, config.paperWidth);

  final connected = await PrintBluetoothThermal.connect(
    macPrinterAddress: config.bluetoothAddress!,
  );
  if (!connected) {
    throw Exception('Connexion Bluetooth échouée — vérifiez que l\'imprimante est allumée et couplée');
  }

  try {
    final ok = await PrintBluetoothThermal.writeBytes(bytes);
    if (!ok) {
      throw Exception('Échec d\'envoi des données à l\'imprimante');
    }
  } finally {
    await PrintBluetoothThermal.disconnect;
  }
}
