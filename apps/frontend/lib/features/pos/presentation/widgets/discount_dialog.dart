import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/pos/presentation/state/cart_state.dart' as model;

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
    _controller = TextEditingController(text: widget.item.discountAmount.toString());
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
      title: Text('Discount: ${widget.item.product.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount'),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Type:'),
              Radio<String>(
                value: 'FIXED', 
                groupValue: _type, 
                onChanged: (v) => setState(() => _type = v!)
              ),
              const Text('\$'),
              Radio<String>(
                value: 'PERCENTAGE', 
                groupValue: _type, 
                onChanged: (v) => setState(() => _type = v!)
              ),
              const Text('%'),
            ],
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text('Cancel')
        ),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(_controller.text) ?? 0.0;
            // Validate percentage
            if (_type == 'PERCENTAGE' && (amount < 0 || amount > 100)) {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Percentage must be between 0 and 100')),
               );
               return;
            }
            if (_type == 'FIXED' && amount < 0) {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Amount cannot be negative')),
               );
               return;
            }

            ref.read(cartProvider.notifier).updateItemDiscount(
              widget.item.product.remoteId!, 
              amount, 
              _type
            );
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
