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

/// Manual stock adjustment form.
/// Creates an ADJUSTMENT movement with a signed quantity:
///   - positive → stock increases (add)
///   - negative → stock decreases (remove)
class AdjustmentForm extends ConsumerStatefulWidget {
  final InventoryRepository repository;

  const AdjustmentForm({super.key, required this.repository});

  @override
  ConsumerState<AdjustmentForm> createState() => _AdjustmentFormState();
}

class _AdjustmentFormState extends ConsumerState<AdjustmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();

  Product? _selectedProduct;
  bool _isAdding = true; // true = add, false = remove
  int? _currentStock;
  bool _loadingStock = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  int get _qty => int.tryParse(_quantityController.text) ?? 0;

  int? get _newStock {
    if (_currentStock == null || _qty <= 0) return _currentStock;
    return _isAdding ? _currentStock! + _qty : _currentStock! - _qty;
  }

  bool get _canSubmit =>
      _selectedProduct != null &&
      _qty > 0 &&
      _reasonController.text.trim().isNotEmpty &&
      !_isSubmitting;

  // ── Product selection ─────────────────────────────────────────────────────

  Future<void> _onProductSelected(Product product) async {
    setState(() {
      _selectedProduct = product;
      _currentStock = null;
      _loadingStock = true;
    });

    final tenantId = ref.read(activeTenantProvider) ?? '';
    try {
      final stock = await widget.repository.getStock(
        catalogItemId: product.remoteId!,
        tenantId: tenantId,
      );
      if (mounted) setState(() => _currentStock = stock);
    } catch (_) {
      // Stock will show as unknown; submit is still allowed
    } finally {
      if (mounted) setState(() => _loadingStock = false);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final tenantId = ref.read(activeTenantProvider) ?? '';
    final signedQty = _isAdding ? _qty : -_qty;
    final reason = _reasonController.text.trim();

    // Offline-first: save locally first
    final movement = InventoryMovementLocal()
      ..type = 'ADJUSTMENT'
      ..catalogItemId = _selectedProduct!.remoteId!
      ..quantity = signedQty
      ..reason = reason
      ..tenantId = tenantId
      ..createdAt = DateTime.now()
      ..syncStatus = 'pending';
    await widget.repository.saveLocal(movement);

    void reset() {
      _selectedProduct = null;
      _currentStock = null;
      _quantityController.clear();
      _reasonController.clear();
      _isAdding = true;
      _isSubmitting = false;
    }

    try {
      final result = await widget.repository.createMovement(
        type: 'ADJUSTMENT',
        catalogItemId: _selectedProduct!.remoteId!,
        quantity: signedQty,
        reason: reason,
        tenantId: tenantId,
      );
      await widget.repository.markSynced(movement.id, result['id'] as String);

      if (mounted) {
        final oldStock = _currentStock;
        final newStk = _newStock;
        final productName = _selectedProduct!.name;
        final msg = (oldStock != null && newStk != null)
            ? 'Ajustement validé : $productName $oldStock → $newStk'
            : 'Ajustement validé';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        setState(reset);
      }
    } on SocketException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sauvegardé localement — sera synchronisé')),
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final paginatedAsync = ref.watch(paginatedProductListProvider);
    final products = paginatedAsync.maybeWhen(
      data: (data) => (data['items'] as List)
          .cast<Product>()
          .where((p) => p.itemType != 'service')
          .toList(),
      orElse: () => <Product>[],
    );

    final newStock = _newStock;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ajustement de stock',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Product autocomplete
            ProductAutocomplete(
              products: products,
              fieldKey: const Key('adjustment_product_field'),
              onSelected: _onProductSelected,
              validator: (_) =>
                  _selectedProduct == null ? 'Sélectionnez un produit' : null,
            ),
            const SizedBox(height: 12),

            // Current stock indicator
            if (_selectedProduct != null)
              _loadingStock
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Chargement du stock…',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            'Stock actuel : ',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          Text(
                            _currentStock != null ? '$_currentStock' : '—',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (newStock != null && newStock != _currentStock) ...[
                            const Text(' → ', style: TextStyle(color: AppColors.textSecondary)),
                            Text(
                              '$newStock',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isAdding ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

            const SizedBox(height: 12),

            // Add / Remove toggle
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Ajouter'),
                  icon: Icon(Icons.add),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Retirer'),
                  icon: Icon(Icons.remove),
                ),
              ],
              selected: {_isAdding},
              onSelectionChanged: (s) =>
                  setState(() => _isAdding = s.first),
            ),
            const SizedBox(height: 12),

            // Quantity
            TextFormField(
              key: const Key('adjustment_quantity_field'),
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Quantité *',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Quantité obligatoire';
                final n = int.tryParse(v);
                if (n == null || n <= 0) return 'Entier > 0';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Reason (mandatory)
            TextFormField(
              key: const Key('adjustment_reason_field'),
              controller: _reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Motif *',
                hintText: 'ex. Cadeau fournisseur, correction saisie…',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Motif obligatoire' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // Submit
            SizedBox(
              height: 48,
              child: ElevatedButton(
                key: const Key('adjustment_submit_button'),
                onPressed: _canSubmit ? _submit : null,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Valider l'ajustement"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
