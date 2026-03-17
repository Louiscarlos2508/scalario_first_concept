import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/retail/inventory/data/repositories/inventory_repository.dart';

/// Form to confirm receipt of a TRANSFER_OUT movement.
/// Allows receiver to enter actual received quantity and records variance.
class TransferConfirmForm extends ConsumerStatefulWidget {
  final InventoryRepository repository;
  final String referenceId;
  final String? catalogItemId;
  final int declaredQuantity;

  const TransferConfirmForm({
    super.key,
    required this.repository,
    required this.referenceId,
    required this.catalogItemId,
    required this.declaredQuantity,
  });

  @override
  ConsumerState<TransferConfirmForm> createState() =>
      _TransferConfirmFormState();
}

class _TransferConfirmFormState extends ConsumerState<TransferConfirmForm> {
  late final TextEditingController _quantityController;
  bool _isSubmitting = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _quantityController =
        TextEditingController(text: widget.declaredQuantity.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _quantityController.text.isNotEmpty &&
      int.tryParse(_quantityController.text) != null &&
      !_isSubmitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);

    final tenantId = ref.read(activeTenantProvider) ?? '';
    final quantity = int.parse(_quantityController.text);
    final variance = (quantity - widget.declaredQuantity).abs();

    try {
      final result = await widget.repository.confirmTransfer(
        referenceId: widget.referenceId,
        catalogItemId: widget.catalogItemId,
        quantity: quantity,
        tenantId: tenantId,
      );

      if (mounted) {
        setState(() {
          _result = result;
          _isSubmitting = false;
        });
        if (variance == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Réception confirmée — aucun écart')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Réception confirmée — écart : $variance')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final received = int.tryParse(_quantityController.text) ?? 0;
    final variance = (received - widget.declaredQuantity).abs();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Confirmer la réception',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('Référence : ${widget.referenceId}'),
          Text('Qté déclarée : ${widget.declaredQuantity}'),
          const SizedBox(height: 16),

          // Quantity field pre-filled with declaredQuantity
          SizedBox(
            key: const Key('confirm_quantity_field'),
            child: TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Quantité reçue',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),

          // Variance label — shown after submit
          if (_result != null) ...[
            if (variance == 0)
              const Text(
                'Aucun écart',
                key: Key('variance_label_zero'),
                style: TextStyle(color: Colors.green),
              )
            else
              Text(
                'Écart : $variance',
                key: const Key('variance_label_nonzero'),
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 12),
          ],

          SizedBox(
            height: 48,
            child: ElevatedButton(
              key: const Key('confirm_submit_button'),
              onPressed: _canSubmit ? _submit : null,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirmer la réception'),
            ),
          ),
        ],
      ),
    );
  }
}
