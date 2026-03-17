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

const List<String> _lossReasons = [
  'Casse',
  'Péremption',
  'Vol',
  'Frotte',
  'Autre',
];

class LossDeclarationForm extends ConsumerStatefulWidget {
  final InventoryRepository repository;

  const LossDeclarationForm({super.key, required this.repository});

  @override
  ConsumerState<LossDeclarationForm> createState() =>
      _LossDeclarationFormState();
}

class _LossDeclarationFormState extends ConsumerState<LossDeclarationForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _autreController = TextEditingController();

  Product? _selectedProduct;
  String? _selectedReason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _autreController.dispose();
    super.dispose();
  }

  bool get _isAutre => _selectedReason == 'Autre';

  bool get _canSubmit {
    if (_selectedProduct == null) return false;
    final qty = int.tryParse(_quantityController.text);
    if (qty == null || qty <= 0) return false;
    if (_selectedReason == null) return false;
    if (_isAutre && _autreController.text.trim().isEmpty) return false;
    return !_isSubmitting;
  }

  String get _reasonLabel {
    if (_isAutre) return 'Autre : ${_autreController.text.trim()}';
    return _selectedReason!;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final tenantId = ref.read(activeTenantProvider) ?? '';
    final quantity = int.parse(_quantityController.text);

    // Save locally first (offline-first outbox pattern)
    final movement = InventoryMovementLocal()
      ..type = 'LOSS'
      ..catalogItemId = _selectedProduct!.remoteId!
      ..quantity = quantity
      ..reason = _reasonLabel
      ..tenantId = tenantId
      ..createdAt = DateTime.now()
      ..syncStatus = 'pending';
    await widget.repository.saveLocal(movement);

    void reset() {
      _selectedProduct = null;
      _selectedReason = null;
      _quantityController.clear();
      _autreController.clear();
      _isSubmitting = false;
    }

    try {
      final result = await widget.repository.createMovement(
        type: 'LOSS',
        catalogItemId: _selectedProduct!.remoteId!,
        quantity: quantity,
        reason: _reasonLabel,
        tenantId: tenantId,
      );
      await widget.repository.markSynced(movement.id, result['id'] as String);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perte déclarée')),
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
              'Déclarer une perte',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Product autocomplete
            ProductAutocomplete(
              products: products,
              fieldKey: const Key('loss_product_field'),
              onSelected: (p) => setState(() => _selectedProduct = p),
              validator: (_) =>
                  _selectedProduct == null ? 'Sélectionnez un produit' : null,
            ),
            const SizedBox(height: 12),

            // Quantity
            TextFormField(
              key: const Key('loss_quantity_field'),
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Quantité perdue *',
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

            // Reason dropdown
            DropdownButtonFormField<String>(
              key: const Key('loss_reason_dropdown'),
              initialValue: _selectedReason,
              decoration: const InputDecoration(
                labelText: 'Motif *',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Sélectionner un motif'),
              items: _lossReasons
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedReason = v;
                if (v != 'Autre') _autreController.clear();
              }),
              validator: (v) =>
                  v == null ? 'Motif obligatoire' : null,
            ),

            // Conditional "Autre" precision field
            if (_isAutre) ...[
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('loss_reason_autre_field'),
                controller: _autreController,
                decoration: const InputDecoration(
                  labelText: 'Précisez le motif *',
                  hintText: 'ex. Chute lors du transport',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Veuillez préciser le motif'
                        : null,
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 20),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                key: const Key('loss_submit_button'),
                onPressed: _canSubmit ? _submit : null,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Déclarer la perte'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
