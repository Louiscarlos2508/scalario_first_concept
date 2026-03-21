import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CameraScannerDialog extends StatelessWidget {
  const CameraScannerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            errorBuilder: (context, error) =>
                _BarcodeFallback(onSubmit: (v) => Navigator.pop(context, v)),
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcode = barcodes.first.rawValue;
                if (barcode != null) {
                  Navigator.pop(context, barcode);
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align barcode within the frame',
                style: TextStyle(
                    color: Colors.white, backgroundColor: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarcodeFallback extends StatefulWidget {
  final ValueChanged<String> onSubmit;

  const _BarcodeFallback({required this.onSubmit});

  @override
  State<_BarcodeFallback> createState() => _BarcodeFallbackState();
}

class _BarcodeFallbackState extends State<_BarcodeFallback> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined,
                size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Caméra non disponible sur cette plateforme.\nSaisis le code-barres manuellement.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Code-barres',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (v) {
                if (v.isNotEmpty) widget.onSubmit(v);
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (_ctrl.text.isNotEmpty) widget.onSubmit(_ctrl.text);
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }
}
