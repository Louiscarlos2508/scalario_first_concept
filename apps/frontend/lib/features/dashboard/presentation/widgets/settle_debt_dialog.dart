import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/pos/data/models/customer.dart';
import 'package:frontend/features/pos/presentation/providers/pos_providers.dart';
import '../screens/customers_screen.dart';

class SettleDebtDialog extends ConsumerStatefulWidget {
  final Customer customer;

  const SettleDebtDialog({super.key, required this.customer});

  @override
  ConsumerState<SettleDebtDialog> createState() => _SettleDebtDialogState();
}

class _SettleDebtDialogState extends ConsumerState<SettleDebtDialog> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with full balance
    _amountController.text = widget.customer.balance.toStringAsFixed(2);
  }

  Future<void> _settle() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(customerRepositoryProvider);
      await repo.settleDebt(widget.customer.id, amount);

      if (mounted) {
        ref.refresh(dashboardCustomersProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Settled \$${amount.toStringAsFixed(2)} for ${widget.customer.name}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Settle Debt - ${widget.customer.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Balance: \$${widget.customer.balance.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Settlement Amount',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
            enabled: !_isLoading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _settle,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('SETTLE'),
        ),
      ],
    );
  }
}
