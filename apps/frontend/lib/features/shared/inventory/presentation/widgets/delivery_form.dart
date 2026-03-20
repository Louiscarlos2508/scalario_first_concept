import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/product_autocomplete.dart';
import 'package:frontend/features/shared/inventory/data/models/inventory_movement_local.dart';
import 'package:frontend/features/shared/inventory/data/repositories/inventory_repository.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

class DeliveryForm extends ConsumerStatefulWidget {
  final InventoryRepository repository;

  const DeliveryForm({super.key, required this.repository});

  @override
  ConsumerState<DeliveryForm> createState() => _DeliveryFormState();
}

class _DeliveryFormState extends ConsumerState<DeliveryForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _productSearchController = TextEditingController();

  Product? _selectedProduct;
  bool _isSubmitting = false;
  // Epic 26 — AC2 (Story 26-4)
  DateTime? _bestBeforeDate;

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    _productSearchController.dispose();
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
      ..type = 'DELIVERY'
      ..catalogItemId = _selectedProduct!.remoteId!
      ..quantity = quantity
      ..reason = notes.isEmpty ? null : notes
      ..tenantId = tenantId
      ..createdAt = DateTime.now()
      ..syncStatus = 'pending';
    await widget.repository.saveLocal(movement);

    void reset() {
      _selectedProduct = null;
      _productSearchController.clear();
      _quantityController.clear();
      _notesController.clear();
      _isSubmitting = false;
    }

    try {
      final result = await widget.repository.createMovement(
        type: 'DELIVERY',
        catalogItemId: _selectedProduct!.remoteId!,
        quantity: quantity,
        reason: notes.isEmpty ? null : notes,
        tenantId: tenantId,
        bestBeforeDate: _bestBeforeDate,
      );
      await widget.repository.markSynced(movement.id, result['id'] as String);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réception enregistrée')),
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
              'Réception livraison fournisseur',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Product search (Autocomplete)
            ProductAutocomplete(
              products: products,
              fieldKey: const Key('delivery_product_field'),
              onSelected: (product) {
                setState(() => _selectedProduct = product);
                _productSearchController.text = product.name;
              },
              validator: (_) =>
                  _selectedProduct == null ? 'Sélectionnez un produit' : null,
            ),
            const SizedBox(height: 12),

            // Quantity field (auto-focused)
            TextFormField(
              key: const Key('delivery_quantity_field'),
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Quantité reçue *',
                hintText: 'ex. 50',
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

            // Epic 26 — AC2: Best-before date (optional)
            const SizedBox(height: 12),
            ListTile(
              key: const Key('delivery_best_before_field'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                _bestBeforeDate == null
                    ? 'Date de garde optimale (optionnel)'
                    : 'Garde optimale : ${_bestBeforeDate!.day.toString().padLeft(2, '0')}/${_bestBeforeDate!.month.toString().padLeft(2, '0')}/${_bestBeforeDate!.year}',
                style: TextStyle(
                  color: _bestBeforeDate == null ? Colors.grey : null,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_bestBeforeDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _bestBeforeDate = null),
                    ),
                  const Icon(Icons.calendar_today_outlined, size: 18),
                ],
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) setState(() => _bestBeforeDate = picked);
              },
            ),
            const SizedBox(height: 12),

            // Notes (optional)
            TextFormField(
              key: const Key('delivery_notes_field'),
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes / variance (optionnel)',
                hintText: 'ex. 3 caisses abîmées',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Submit button — Fitts ≥ 48dp
            SizedBox(
              height: 48,
              child: ElevatedButton(
                key: const Key('delivery_submit_button'),
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
      ),
    );
  }
}
