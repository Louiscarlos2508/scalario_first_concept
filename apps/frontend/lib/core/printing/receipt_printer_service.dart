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
}
