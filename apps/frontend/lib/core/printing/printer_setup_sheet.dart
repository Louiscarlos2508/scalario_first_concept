import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'printer_config.dart';
import 'printer_config_provider.dart';
import 'usb_escpos_printer.dart' show listUsbPrinterPaths;

/// Opens the printer setup as a modal bottom sheet.
Future<void> showPrinterSetupSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => SingleChildScrollView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Imprimante',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Configuration locale à cet appareil',
                style: TextStyle(fontSize: 12, color: Colors.black45)),
            const Divider(height: 24),
            const PrinterSetupContent(),
          ],
        ),
      ),
    ),
  );
}

/// Printer setup form — usable inline (settings) or in a bottom sheet (POS).
class PrinterSetupContent extends ConsumerStatefulWidget {
  const PrinterSetupContent({super.key});

  @override
  ConsumerState<PrinterSetupContent> createState() =>
      _PrinterSetupContentState();
}

class _PrinterSetupContentState extends ConsumerState<PrinterSetupContent> {
  PrinterType _type = PrinterType.bluetoothEscPos;
  PaperWidth _paperWidth = PaperWidth.mm80;
  String? _btAddress;
  String? _btName;
  final _ipCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '9100');
  String? _usbPath;
  bool _loaded = false;
  bool _saving = false;
  bool _scanningBt = false;
  bool _scanningUsb = false;
  List<BluetoothInfo> _btDevices = [];
  List<String> _usbDevices = [];

  static bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(printerConfigProvider).whenData((config) {
      if (!_loaded) {
        _loaded = true;
        _type = config.type;
        _paperWidth = config.paperWidth;
        _btAddress = config.bluetoothAddress;
        _btName = config.bluetoothName;
        _ipCtrl.text = config.networkIp ?? '';
        _portCtrl.text = config.networkPort.toString();
        _usbPath = config.usbDevicePath;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Type ──────────────────────────────────────────────────────────
        const Text('Type d\'imprimante',
            style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 8),
        SegmentedButton<PrinterType>(
          segments: [
            if (!_isDesktop)
              const ButtonSegment(
                  value: PrinterType.bluetoothEscPos,
                  label: Text('Bluetooth'),
                  icon: Icon(Icons.bluetooth_outlined, size: 16)),
            const ButtonSegment(
                value: PrinterType.networkEscPos,
                label: Text('Réseau TCP'),
                icon: Icon(Icons.wifi_outlined, size: 16)),
            if (_isDesktop)
              const ButtonSegment(
                  value: PrinterType.usbEscPos,
                  label: Text('USB'),
                  icon: Icon(Icons.usb_outlined, size: 16)),
          ],
          selected: {_type},
          onSelectionChanged: (s) => setState(() => _type = s.first),
          style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ),

        const SizedBox(height: 16),

        // ── Type-specific fields ───────────────────────────────────────────
        if (_type == PrinterType.bluetoothEscPos) ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.print_outlined,
                          size: 18, color: Colors.black45),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _btName ?? 'Aucune imprimante sélectionnée',
                          style: TextStyle(
                            fontSize: 13,
                            color: _btName != null
                                ? Colors.black87
                                : Colors.black38,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _scanningBt
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton.icon(
                              onPressed: _scanBluetooth,
                              icon: const Icon(Icons.search, size: 16),
                              label: const Text('Choisir'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                    ],
                  ),
                ),
                if (_btDevices.isNotEmpty) ...[
                  const Divider(height: 1),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _btDevices.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final d = _btDevices[i];
                        return InkWell(
                          onTap: () => setState(() {
                            _btAddress = d.macAdress;
                            _btName = d.name;
                            _btDevices = [];
                          }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.print_outlined,
                                    size: 18, color: Colors.black45),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(d.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                    Text(d.macAdress,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.black45)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else if (_type == PrinterType.networkEscPos) ...[
          TextField(
            controller: _ipCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Adresse IP',
              hintText: '192.168.1.100',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _portCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Port',
              hintText: '9100',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
        ] else if (_type == PrinterType.usbEscPos) ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.usb_outlined,
                          size: 18, color: Colors.black45),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _usbPath ?? 'Aucun périphérique sélectionné',
                          style: TextStyle(
                            fontSize: 13,
                            color: _usbPath != null
                                ? Colors.black87
                                : Colors.black38,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _scanningUsb
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton.icon(
                              onPressed: _scanUsb,
                              icon: const Icon(Icons.search, size: 16),
                              label: const Text('Détecter'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                    ],
                  ),
                ),
                if (_usbDevices.isNotEmpty) ...[
                  const Divider(height: 1),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _usbDevices.length,
                      itemBuilder: (_, i) => InkWell(
                        onTap: () => setState(() {
                          _usbPath = _usbDevices[i];
                          _usbDevices = [];
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.usb_outlined,
                                  size: 18, color: Colors.black45),
                              const SizedBox(width: 10),
                              Text(_usbDevices[i],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Paper width ────────────────────────────────────────────────────
        const Text('Largeur papier',
            style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 8),
        SegmentedButton<PaperWidth>(
          segments: const [
            ButtonSegment(value: PaperWidth.mm80, label: Text('80 mm')),
            ButtonSegment(value: PaperWidth.mm58, label: Text('58 mm')),
          ],
          selected: {_paperWidth},
          onSelectionChanged: (s) =>
              setState(() => _paperWidth = s.first),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Sauvegarder'),
          ),
        ),
      ],
    );
  }

  Future<void> _scanBluetooth() async {
    setState(() {
      _scanningBt = true;
      _btDevices = [];
    });
    try {
      final devices = await PrintBluetoothThermal.pairedBluetooths;
      if (mounted) {
        setState(() => _btDevices = devices);
        if (devices.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Aucun appareil couplé — couplez l\'imprimante dans les réglages Bluetooth'),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur Bluetooth : $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _scanningBt = false);
    }
  }

  Future<void> _scanUsb() async {
    setState(() {
      _scanningUsb = true;
      _usbDevices = [];
    });
    try {
      final paths = await listUsbPrinterPaths();
      if (mounted) {
        setState(() => _usbDevices = paths);
        if (paths.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Aucun périphérique USB détecté — vérifiez la connexion'),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur détection USB : $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _scanningUsb = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final config = PrinterConfig(
        type: _type,
        bluetoothAddress:
            _type == PrinterType.bluetoothEscPos ? _btAddress : null,
        bluetoothName:
            _type == PrinterType.bluetoothEscPos ? _btName : null,
        networkIp: _type == PrinterType.networkEscPos
            ? _ipCtrl.text.trim()
            : null,
        networkPort: _type == PrinterType.networkEscPos
            ? int.tryParse(_portCtrl.text.trim()) ?? 9100
            : 9100,
        usbDevicePath: _type == PrinterType.usbEscPos
            ? _usbPath
            : null,
        paperWidth: _paperWidth,
      );
      await ref.read(printerConfigProvider.notifier).save(config);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Configuration imprimante sauvegardée')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
