import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/product_autocomplete.dart';
import 'package:frontend/features/shared/business_type/data/business_type_config_repository.dart';
import 'package:frontend/features/shared/inventory/data/models/inventory_movement_local.dart';
import 'package:frontend/features/shared/inventory/data/repositories/inventory_repository.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

/// Stores the referenceId of the most recently declared TRANSFER_OUT.
/// Used by TransferPendingScreen / TransferConfirmForm to pre-populate.
final transferPendingReferenceIdProvider = StateProvider<String?>((ref) => null);

/// Autocomplete suggestions for destination — built from previously used values
/// in this session (Option A: texte libre avec suggestions).
final transferDestinationSuggestionsProvider =
    StateProvider<List<String>>((ref) => []);

class TransferOutForm extends ConsumerStatefulWidget {
  final InventoryRepository repository;
  final BusinessTypeConfig? config;

  const TransferOutForm({
    super.key,
    required this.repository,
    this.config,
  });

  @override
  ConsumerState<TransferOutForm> createState() => _TransferOutFormState();
}

class _TransferOutFormState extends ConsumerState<TransferOutForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _fromController = TextEditingController();
  final _destinationController = TextEditingController();
  final _notesController = TextEditingController();

  Product? _selectedProduct;
  List<String> _destSuggestions = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _fromController.dispose();
    _destinationController.dispose();
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
    final source = _fromController.text.trim();
    final destination = _destinationController.text.trim();
    final notes = _notesController.text.trim();
    final locationPart = source.isNotEmpty && destination.isNotEmpty
        ? '$source → $destination'
        : source.isNotEmpty
            ? source
            : destination.isNotEmpty
                ? '→ $destination'
                : '';
    final reason = [
      if (locationPart.isNotEmpty) locationPart,
      if (notes.isNotEmpty) notes,
    ].join(' · ');

    // Save locally first (offline-first outbox pattern)
    final movement = InventoryMovementLocal()
      ..type = 'TRANSFER_OUT'
      ..catalogItemId = _selectedProduct!.remoteId!
      ..quantity = quantity
      ..reason = reason.isEmpty ? null : reason
      ..tenantId = tenantId
      ..createdAt = DateTime.now()
      ..syncStatus = 'pending';
    await widget.repository.saveLocal(movement);

    void reset() {
      _selectedProduct = null;
      _quantityController.clear();
      _fromController.clear();
      _destinationController.clear();
      _notesController.clear();
      _isSubmitting = false;
    }

    try {
      final result = await widget.repository.createMovement(
        type: 'TRANSFER_OUT',
        catalogItemId: _selectedProduct!.remoteId!,
        quantity: quantity,
        reason: reason.isEmpty ? null : reason,
        tenantId: tenantId,
        fromLocation: source.isNotEmpty ? source : null,
        toLocation: destination.isNotEmpty ? destination : null,
      );
      await widget.repository.markSynced(movement.id, result['id'] as String);

      // Store referenceId for the confirmation step
      final referenceId = result['referenceId'] as String?;
      ref.read(transferPendingReferenceIdProvider.notifier).state = referenceId;

      // Persist destination as autocomplete suggestion
      if (destination.isNotEmpty) {
        final current = ref.read(transferDestinationSuggestionsProvider);
        if (!current.contains(destination)) {
          ref.read(transferDestinationSuggestionsProvider.notifier).state = [
            destination,
            ...current,
          ];
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.config?.sendAction ?? 'Envoi de stock'} enregistré${referenceId != null ? ' — Réf. ${referenceId.substring(0, 8)}…' : ''}',
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
    final suggestions = ref.watch(transferDestinationSuggestionsProvider);
    final config = widget.config ?? BusinessTypeConfig.fallback;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              config.sendAction,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Product autocomplete
            ProductAutocomplete(
              products: products,
              fieldKey: const Key('transfer_out_product_field'),
              onSelected: (product) =>
                  setState(() => _selectedProduct = product),
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
                labelText: 'Quantité *',
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

            // Source (fromLabel — texte libre, optionnel)
            TextFormField(
              key: const Key('transfer_from_field'),
              controller: _fromController,
              decoration: InputDecoration(
                labelText: config.fromLabel,
                hintText: config.fromLabel,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Destination (toLabel — texte libre avec suggestions de session)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    labelText: config.toLabel,
                    hintText: 'ex. Rayon 1, Comptoir…',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    final q = v.toLowerCase();
                    setState(() {
                      _destSuggestions = q.isEmpty
                          ? suggestions
                          : suggestions
                              .where((s) => s.toLowerCase().contains(q))
                              .toList();
                    });
                  },
                  onTap: () {
                    if (_destSuggestions.isEmpty && suggestions.isNotEmpty) {
                      setState(() => _destSuggestions = suggestions);
                    }
                  },
                ),
                if (_destSuggestions.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 160),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black12),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(8)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 3)),
                      ],
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _destSuggestions.length,
                      itemBuilder: (_, i) => InkWell(
                        onTap: () => setState(() {
                          _destinationController.text = _destSuggestions[i];
                          _destSuggestions = [];
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Text(_destSuggestions[i],
                              style: const TextStyle(fontSize: 14)),
                        ),
                      ),
                    ),
                  ),
              ],
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
                    : Text(config.sendButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
