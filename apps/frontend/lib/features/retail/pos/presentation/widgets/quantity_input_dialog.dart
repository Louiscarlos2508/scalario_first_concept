import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

/// Dialog shown when the user taps a weight/volume/length product on the POS grid.
/// Returns the entered quantity as a [double] via [Navigator.pop], or null if cancelled.
class QuantityInputDialog extends StatefulWidget {
  final Product product;

  const QuantityInputDialog({super.key, required this.product});

  @override
  State<QuantityInputDialog> createState() => _QuantityInputDialogState();
}

class _QuantityInputDialogState extends State<QuantityInputDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  double? _preview;

  String get _unitLabel => widget.product.weightUnit ?? widget.product.unitType;

  double get _unitPrice =>
      widget.product.pricePerUnit ?? widget.product.price;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updatePreview);
  }

  void _updatePreview() {
    final parsed = double.tryParse(_controller.text.replaceAll(',', '.'));
    setState(() {
      _preview = parsed != null && parsed > 0 ? parsed * _unitPrice : null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Quantité — ${widget.product.name}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_fcfa(_unitPrice)} / $_unitLabel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('quantity_input_field'),
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Quantité *',
                suffixText: _unitLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Obligatoire';
                final parsed = double.tryParse(value.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) return 'Doit être > 0';
                return null;
              },
            ),
            if (_preview != null) ...[
              const SizedBox(height: 12),
              Text(
                'Total : ${_fcfa(((_preview!) / 5).round() * 5.0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          key: const Key('quantity_confirm_button'),
          onPressed: _confirm,
          child: const Text('Confirmer'),
        ),
      ],
    );
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    final qty = double.parse(_controller.text.replaceAll(',', '.'));
    Navigator.of(context).pop(qty);
  }
}
