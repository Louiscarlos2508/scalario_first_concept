import 'package:flutter/material.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';

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
      title: Text('Ajuster le stock : ${widget.product.name}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _adjustmentType,
              items: const [
                DropdownMenuItem(
                  value: 'ADJUSTMENT',
                  child: Text('Ajustement manuel (+/-)'),
                ),
                DropdownMenuItem(value: 'IN', child: Text('Réapprovisionnement (IN)')),
                DropdownMenuItem(
                  value: 'OUT',
                  child: Text('Perte/Dommage (OUT)'),
                ),
              ],
              onChanged: (val) => setState(() => _adjustmentType = val!),
              decoration: const InputDecoration(labelText: "Type d'ajustement"),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantité',
                helperText:
                    'Utilisez des nombres négatifs pour diminuer le stock en mode Ajustement',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Obligatoire';
                if (double.tryParse(value) == null) return 'Nombre invalide';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: "Motif de l'ajustement",
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Obligatoire' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Mettre à jour')),
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
