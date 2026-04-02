import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'printer_config.dart';

class PrinterConfigNotifier extends AsyncNotifier<PrinterConfig> {
  @override
  Future<PrinterConfig> build() => loadPrinterConfig();

  Future<void> save(PrinterConfig config) async {
    await savePrinterConfig(config);
    state = AsyncData(config);
  }
}

final printerConfigProvider =
    AsyncNotifierProvider<PrinterConfigNotifier, PrinterConfig>(
  PrinterConfigNotifier.new,
);
