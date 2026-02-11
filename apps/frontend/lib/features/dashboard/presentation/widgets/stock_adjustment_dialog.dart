import 'package:flutter/material.dart';
import '../../../pos/data/models/product.dart';

class StockAdjustmentDialog extends StatefulWidget {
  final Product product;

  const StockAdjustmentDialog({super.key, required this.product});

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  String _adjustmentType = 'ADJUSTMENT'; // ADJUSTMENT, IN, OUT

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adjust Stock: ${widget.product.name}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _adjustmentType,
              items: const [
                DropdownMenuItem(value: 'ADJUSTMENT', child: Text('Manual Adjustment (+/-)')),
                DropdownMenuItem(value: 'IN', child: Text('Restock (IN)')),
                DropdownMenuItem(value: 'OUT', child: Text('Damage/Loss (OUT)')),
              ],
              onChanged: (val) => setState(() => _adjustmentType = val!),
              decoration: const InputDecoration(labelText: 'Adjustment Type'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                helperText: 'Use negative numbers to decrease stock in Adjustment mode',
              ),
              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (double.tryParse(value) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Reason for Adjustment'),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Update Stock'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      double qty = double.parse(_quantityController.text);
      
      // Enforce positive/negative based on type if not pure adjustment
      if (_adjustmentType == 'IN') qty = qty.abs();
      if (_adjustmentType == 'OUT') qty = -qty.abs();

      Navigator.pop(context, {
        'quantity': qty,
        'type': _adjustmentType,
        'reason': _reasonController.text,
      });
    }
  }
}
