import 'package:flutter/material.dart';

/// Shows a dialog requesting the serial number for an article that requires tracking.
///
/// Returns the entered serial number, or null if the user cancels.
Future<String?> showSerialInputDialog(
  BuildContext context, {
  required String productName,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _SerialInputDialog(productName: productName),
  );
}

class _SerialInputDialog extends StatefulWidget {
  final String productName;
  const _SerialInputDialog({required this.productName});

  @override
  State<_SerialInputDialog> createState() => _SerialInputDialogState();
}

class _SerialInputDialogState extends State<_SerialInputDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Numéro de série requis'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.productName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Numéro de série / IMEI',
              hintText: 'ex: IMEI-123456789',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) Navigator.of(context).pop(value.trim());
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Annuler'),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (_, value, _) => FilledButton(
            onPressed: value.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(value.text.trim()),
            child: const Text('Confirmer'),
          ),
        ),
      ],
    );
  }
}
