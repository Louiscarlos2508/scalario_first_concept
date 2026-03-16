import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart' as model;

class DiscountDialog extends ConsumerStatefulWidget {
  final model.CartItem item;

  const DiscountDialog({super.key, required this.item});

  @override
  ConsumerState<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends ConsumerState<DiscountDialog> {
  late TextEditingController _controller;
  late String _type;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.item.discountAmount.toString());
    _type = widget.item.discountType;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Remise : ${widget.item.product.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Montant'),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Type :'),
              Radio<String>(
                value: 'FIXED',
                groupValue: _type,
                onChanged: (v) => setState(() => _type = v!),
              ),
              const Text('FCFA'),
              Radio<String>(
                value: 'PERCENTAGE',
                groupValue: _type,
                onChanged: (v) => setState(() => _type = v!),
              ),
              const Text('%'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(_controller.text) ?? 0.0;
            if (_type == 'PERCENTAGE' && (amount < 0 || amount > 100)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Le pourcentage doit être entre 0 et 100')),
              );
              return;
            }
            if (_type == 'FIXED' && amount < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Le montant ne peut pas être négatif')),
              );
              return;
            }

            ref.read(cartProvider.notifier).updateItemDiscount(
                  widget.item.product.remoteId!,
                  amount,
                  _type,
                );
            Navigator.pop(context);
          },
          child: const Text('Appliquer'),
        ),
      ],
    );
  }
}
