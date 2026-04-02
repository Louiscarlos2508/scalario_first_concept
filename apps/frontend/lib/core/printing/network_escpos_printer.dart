import 'dart:io';
import 'printer_config.dart';
import 'receipt_data.dart';
import 'escpos_builder.dart';

/// Sends ESC/POS bytes to a network thermal printer via TCP.
Future<void> printNetworkEscPos(ReceiptData data, PrinterConfig config) async {
  if (config.networkIp == null || config.networkIp!.isEmpty) {
    throw Exception('Adresse IP imprimante non configurée');
  }

  final bytes = await buildEscPosReceipt(data, config.paperWidth);

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
}
