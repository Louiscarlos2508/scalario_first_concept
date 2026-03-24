import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/inventory/data/repositories/inventory_repository.dart';

/// Form to confirm receipt of a TRANSFER_OUT movement.
/// Allows receiver to enter actual received quantity and records variance.
class TransferConfirmForm extends ConsumerStatefulWidget {
  final InventoryRepository repository;
  final String referenceId;
  final String? catalogItemId;
  final int declaredQuantity;
  /// Called after a successful confirmation so the caller can close the sheet.
  final VoidCallback? onSuccess;
  /// Label for the confirm button (from business type config).
  final String confirmButton;

  const TransferConfirmForm({
    super.key,
    required this.repository,
    required this.referenceId,
    required this.catalogItemId,
    required this.declaredQuantity,
    this.onSuccess,
    this.confirmButton = 'Confirmer la réception',
  });

  @override
  ConsumerState<TransferConfirmForm> createState() =>
      _TransferConfirmFormState();
}

class _TransferConfirmFormState extends ConsumerState<TransferConfirmForm> {
  late final TextEditingController _quantityController;
  bool _isSubmitting = false;

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
      await widget.repository.confirmTransfer(
        referenceId: widget.referenceId,
        catalogItemId: widget.catalogItemId,
        quantity: quantity,
        tenantId: tenantId,
      );

      if (mounted) {
        final msg = variance == 0
            ? 'Réception confirmée — aucun écart'
            : 'Réception confirmée — écart : $variance';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        widget.onSuccess?.call();
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
                  : Text(widget.confirmButton),
            ),
          ),
        ],
      ),
    );
  }
}
