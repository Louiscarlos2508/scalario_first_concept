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
import 'package:frontend/features/shared/catalog/data/models/product_variant.dart';
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
  // Dépôt-vente (isUnique) extra fields
  final _consignantController = TextEditingController();
  final _agreedPriceController = TextEditingController();
  final _commissionController = TextEditingController();

  Product? _selectedProduct;
  ProductVariant? _selectedVariant;
  final List<TextEditingController> _serialControllers = [];
  DateTime? _bestBeforeDate;
  DateTime? _expiryDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    _productSearchController.dispose();
    _consignantController.dispose();
    _agreedPriceController.dispose();
    _commissionController.dispose();
    for (final c in _serialControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Computed helpers ──────────────────────────────────────────────────────

  bool get _hasVariants =>
      _selectedProduct?.hasVariants == true &&
      (_selectedProduct?.variants.isNotEmpty ?? false);

  bool get _trackSerials => _selectedProduct?.trackSerialNumbers == true;

  bool get _hasExpiry => _selectedProduct?.expiryDays != null;

  bool get _isUnique => _selectedProduct?.isUnique == true;

  int get _currentQty => int.tryParse(_quantityController.text) ?? 0;

  bool get _serialsComplete {
    if (!_trackSerials) return true;
    if (_serialControllers.length != _currentQty) return false;
    return _serialControllers.every((c) => c.text.trim().isNotEmpty);
  }

  bool get _canSubmit =>
      _selectedProduct != null &&
      _quantityController.text.isNotEmpty &&
      _currentQty > 0 &&
      (!_hasVariants || _selectedVariant != null) &&
      _serialsComplete &&
      !_isSubmitting;

  // ─── Serial controllers sync ───────────────────────────────────────────────

  void _syncSerialControllers(int count) {
    setState(() {
      while (_serialControllers.length > count) {
        _serialControllers.removeLast().dispose();
      }
      while (_serialControllers.length < count) {
        _serialControllers.add(TextEditingController());
      }
    });
  }

  // ─── Product selection ─────────────────────────────────────────────────────

  void _onProductSelected(Product product) {
    setState(() {
      _selectedProduct = product;
      _selectedVariant = null;
      _expiryDate = null;
      _bestBeforeDate = null;
      // Pre-fill expiry date from expiryDays
      if (product.expiryDays != null) {
        _expiryDate =
            DateTime.now().add(Duration(days: product.expiryDays!));
      }
      // Lock quantity to 1 for unique (dépôt-vente) items
      if (product.isUnique) {
        _quantityController.text = '1';
        _syncSerialControllers(0);
      } else {
        // Reset serial controllers based on current qty
        _syncSerialControllers(
            _trackSerials ? _currentQty.clamp(0, 200) : 0);
      }
    });
  }

  // ─── Reason builder (notes + dépôt-vente meta) ────────────────────────────

  String? _buildReason() {
    final parts = <String>[];
    if (_notesController.text.trim().isNotEmpty) {
      parts.add(_notesController.text.trim());
    }
    if (_isUnique) {
      if (_consignantController.text.trim().isNotEmpty) {
        parts.add('Consignant: ${_consignantController.text.trim()}');
      }
      if (_agreedPriceController.text.trim().isNotEmpty) {
        parts.add('Prix: ${_agreedPriceController.text.trim()} FCFA');
      }
      if (_commissionController.text.trim().isNotEmpty) {
        parts.add('Commission: ${_commissionController.text.trim()}%');
      }
    }
    return parts.isEmpty ? null : parts.join(' | ');
  }

  // ─── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final tenantId = ref.read(activeTenantProvider) ?? '';
    final quantity = _currentQty;
    final reason = _buildReason();
    final serials =
        _serialControllers.map((c) => c.text.trim()).toList();

    final movement = InventoryMovementLocal()
      ..type = 'DELIVERY'
      ..catalogItemId = _selectedProduct!.remoteId!
      ..quantity = quantity
      ..reason = reason
      ..tenantId = tenantId
      ..createdAt = DateTime.now()
      ..syncStatus = 'pending';
    await widget.repository.saveLocal(movement);

    void reset() {
      _selectedProduct = null;
      _selectedVariant = null;
      _productSearchController.clear();
      _quantityController.clear();
      _notesController.clear();
      _consignantController.clear();
      _agreedPriceController.clear();
      _commissionController.clear();
      _expiryDate = null;
      _bestBeforeDate = null;
      for (final c in _serialControllers) {
        c.dispose();
      }
      _serialControllers.clear();
      _isSubmitting = false;
    }

    try {
      final result = await widget.repository.createMovement(
        type: 'DELIVERY',
        catalogItemId: _selectedProduct!.remoteId!,
        quantity: quantity,
        reason: reason,
        variantId: _selectedVariant?.id,
        serialNumbers: serials.isEmpty ? null : serials,
        expiresAt: _expiryDate,
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

  // ─── Build ─────────────────────────────────────────────────────────────────

  String _variantLabel(ProductVariant v) {
    if (v.sku?.isNotEmpty == true) return v.sku!;
    final label = v.attributes.values.join(' ');
    return label.isNotEmpty ? label : 'Variante';
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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

            // Product search
            ProductAutocomplete(
              products: products,
              fieldKey: const Key('delivery_product_field'),
              onSelected: _onProductSelected,
              validator: (_) =>
                  _selectedProduct == null ? 'Sélectionnez un produit' : null,
            ),
            const SizedBox(height: 12),

            // CONDITIONAL — variant dropdown
            if (_hasVariants) ...[
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Variante *',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedVariant?.id,
                    isDense: true,
                    isExpanded: true,
                    hint: const Text('Sélectionner une variante'),
                    items: _selectedProduct!.variants
                        .map((v) => DropdownMenuItem<String>(
                              value: v.id,
                              child: Text(_variantLabel(v)),
                            ))
                        .toList(),
                    onChanged: (id) {
                      setState(() {
                        _selectedVariant = _selectedProduct!.variants
                            .where((v) => v.id == id)
                            .firstOrNull;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Quantity field (locked to 1 for isUnique)
            TextFormField(
              key: const Key('delivery_quantity_field'),
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: !_isUnique,
              readOnly: _isUnique,
              decoration: InputDecoration(
                labelText: 'Quantité reçue *',
                hintText: _isUnique ? null : 'ex. 50',
                border: const OutlineInputBorder(),
                suffixIcon: _isUnique
                    ? const Tooltip(
                        message: 'Article unique — quantité verrouillée à 1',
                        child: Icon(Icons.lock_outline, size: 18),
                      )
                    : null,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Quantité obligatoire';
                final n = int.tryParse(v);
                if (n == null || n <= 0) return 'Quantité invalide (entier > 0)';
                return null;
              },
              onChanged: (v) {
                if (_trackSerials) {
                  _syncSerialControllers(
                      (int.tryParse(v) ?? 0).clamp(0, 200));
                } else {
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 12),

            // CONDITIONAL — serial number fields
            if (_trackSerials && _serialControllers.isNotEmpty) ...[
              const Text(
                'Numéros de série',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              ..._serialControllers.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: TextField(
                      key: Key('delivery_serial_${e.key}'),
                      controller: e.value,
                      decoration: InputDecoration(
                        labelText: 'N° série ${e.key + 1}',
                        hintText: 'ex. IMEI 123456789',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  )),
              const SizedBox(height: 8),
            ],

            // CONDITIONAL — expiry date picker
            if (_hasExpiry) ...[
              ListTile(
                key: const Key('delivery_expiry_field'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _expiryDate == null
                      ? "Date d'expiration *"
                      : "Expiration : ${_fmtDate(_expiryDate!)}",
                  style: TextStyle(
                    color: _expiryDate == null ? AppColors.error : null,
                  ),
                ),
                trailing: const Icon(Icons.calendar_today_outlined, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate ??
                        DateTime.now().add(Duration(
                            days: _selectedProduct!.expiryDays!)),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) setState(() => _expiryDate = picked);
                },
              ),
              const SizedBox(height: 4),
            ],

            // Best-before date (always shown, optional)
            const SizedBox(height: 4),
            ListTile(
              key: const Key('delivery_best_before_field'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                _bestBeforeDate == null
                    ? 'Date de garde optimale (optionnel)'
                    : 'Garde optimale : ${_fmtDate(_bestBeforeDate!)}',
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
                      onPressed: () =>
                          setState(() => _bestBeforeDate = null),
                    ),
                  const Icon(Icons.calendar_today_outlined, size: 18),
                ],
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _bestBeforeDate ??
                      DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate:
                      DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) setState(() => _bestBeforeDate = picked);
              },
            ),
            const SizedBox(height: 4),

            // CONDITIONAL — dépôt-vente fields (isUnique)
            if (_isUnique) ...[
              const SizedBox(height: 8),
              const Divider(),
              Text(
                'Dépôt-vente',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('delivery_consignant_field'),
                controller: _consignantController,
                decoration: const InputDecoration(
                  labelText: 'Consignant (optionnel)',
                  hintText: 'ex. Jean Dupont',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('delivery_agreed_price_field'),
                      controller: _agreedPriceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Prix convenu FCFA (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      key: const Key('delivery_commission_field'),
                      controller: _commissionController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'))
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Commission % (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Notes
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

            // Submit button
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
