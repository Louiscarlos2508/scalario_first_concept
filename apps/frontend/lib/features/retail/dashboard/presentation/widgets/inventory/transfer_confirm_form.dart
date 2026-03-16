import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/retail/dashboard/data/repositories/inventory_repository.dart';

class TransferConfirmForm extends ConsumerStatefulWidget {
  final InventoryRepository repository;
  final String referenceId;
  final String? catalogItemId;
  final int declaredQuantity;

  const TransferConfirmForm({
    super.key,
    required this.repository,
    required this.referenceId,
    this.catalogItemId,
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
      int.parse(_quantityController.text) >= 0 &&
      !_isSubmitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);

    final tenantId = ref.read(activeTenantProvider) ?? '';
    final received = int.parse(_quantityController.text);

    try {
      final result = await widget.repository.confirmTransfer(
        referenceId: widget.referenceId,
        catalogItemId: widget.catalogItemId,
        quantity: received,
        tenantId: tenantId,
      );

      if (mounted) {
        setState(() {
          _result = result;
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réception confirmée')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // After confirmation, show variance result
    if (_result != null) {
      return _VarianceResult(
        declared: widget.declaredQuantity,
        received: int.tryParse(_quantityController.text) ??
            widget.declaredQuantity,
        movement: _result!,
      );
    }

    final refShort = widget.referenceId.length > 8
        ? widget.referenceId.substring(0, 8)
        : widget.referenceId;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Confirmer la réception',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Réf. $refShort… · Qté déclarée : ${widget.declaredQuantity}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // Received quantity — pre-filled with declared
          TextFormField(
            key: const Key('confirm_quantity_field'),
            controller: _quantityController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Quantité effectivement reçue *',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

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
                  : const Text('Valider la réception'),
            ),
          ),
        ],
      ),
    );
  }
}

class _VarianceResult extends StatelessWidget {
  final int declared;
  final int received;
  final Map<String, dynamic> movement;

  const _VarianceResult({
    required this.declared,
    required this.received,
    required this.movement,
  });

  @override
  Widget build(BuildContext context) {
    final variance = declared - received;
    final hasVariance = variance != 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.success, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Réception confirmée',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          hasVariance
              ? Container(
                  key: const Key('variance_label_nonzero'),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    'Écart : ${variance > 0 ? '+$variance' : '$variance'} unité(s)',
                    style: const TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                )
              : Container(
                  key: const Key('variance_label_zero'),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: const Text(
                    'Aucun écart',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600),
                  ),
                ),
        ],
      ),
    );
  }
}
