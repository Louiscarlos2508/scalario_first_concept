import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/product_autocomplete.dart';
import 'package:frontend/features/retail/inventory/data/models/inventory_movement_local.dart';
import 'package:frontend/features/retail/inventory/data/repositories/inventory_repository.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

/// Stores the referenceId of the most recently declared TRANSFER_OUT.
/// Used by TransferPendingScreen / TransferConfirmForm to pre-populate.
final transferPendingReferenceIdProvider = StateProvider<String?>((ref) => null);

class TransferOutForm extends ConsumerStatefulWidget {
  final InventoryRepository repository;

  const TransferOutForm({super.key, required this.repository});

  @override
  ConsumerState<TransferOutForm> createState() => _TransferOutFormState();
}

class _TransferOutFormState extends ConsumerState<TransferOutForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  Product? _selectedProduct;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selectedProduct != null &&
      _quantityController.text.isNotEmpty &&
      int.tryParse(_quantityController.text) != null &&
      int.parse(_quantityController.text) > 0 &&
      !_isSubmitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final tenantId = ref.read(activeTenantProvider) ?? '';
    final quantity = int.parse(_quantityController.text);
    final notes = _notesController.text.trim();

    // Save locally first (offline-first outbox pattern)
    final movement = InventoryMovementLocal()
      ..type = 'TRANSFER_OUT'
      ..catalogItemId = _selectedProduct!.remoteId!
      ..quantity = quantity
      ..reason = notes.isEmpty ? null : notes
      ..tenantId = tenantId
      ..createdAt = DateTime.now()
      ..syncStatus = 'pending';
    await widget.repository.saveLocal(movement);

    void reset() {
      _selectedProduct = null;
      _quantityController.clear();
      _notesController.clear();
      _isSubmitting = false;
    }

    try {
      final result = await widget.repository.createMovement(
        type: 'TRANSFER_OUT',
        catalogItemId: _selectedProduct!.remoteId!,
        quantity: quantity,
        reason: notes.isEmpty ? null : notes,
        tenantId: tenantId,
      );
      await widget.repository.markSynced(movement.id, result['id'] as String);

      // Store referenceId for the confirmation step
      final referenceId = result['referenceId'] as String?;
      ref.read(transferPendingReferenceIdProvider.notifier).state = referenceId;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sortie déclarée${referenceId != null ? ' — Réf. ${referenceId.substring(0, 8)}…' : ''}',
            ),
          ),
        );
        setState(reset);
      }
    } on SocketException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sauvegardé localement — sera synchronisé'),
          ),
        );
        setState(reset);
      }
    } catch (e) {
      await widget.repository.markFailed(movement.id, e.toString());
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
    final paginatedAsync = ref.watch(paginatedProductListProvider);
    final products = paginatedAsync.maybeWhen(
      data: (data) => (data['items'] as List).cast<Product>(),
      orElse: () => <Product>[],
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Déclarer une sortie de stock',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Product autocomplete
            ProductAutocomplete(
              products: products,
              fieldKey: const Key('transfer_out_product_field'),
              onSelected: (product) => setState(() => _selectedProduct = product),
              validator: (_) =>
                  _selectedProduct == null ? 'Sélectionnez un produit' : null,
            ),
            const SizedBox(height: 12),

            // Quantity
            TextFormField(
              key: const Key('transfer_out_quantity_field'),
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Quantité déclarée *',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Quantité obligatoire';
                final n = int.tryParse(v);
                if (n == null || n <= 0) return 'Quantité invalide (entier > 0)';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Notes (optional)
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                key: const Key('transfer_out_submit_button'),
                onPressed: _canSubmit ? _submit : null,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Déclarer la sortie'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
