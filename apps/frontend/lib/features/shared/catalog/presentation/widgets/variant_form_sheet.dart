import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/catalog/data/models/product_variant.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart';

/// Bottom sheet for creating or editing a [ProductVariant].
///
/// Pass [existingVariant] to open in edit mode.
class VariantFormSheet extends ConsumerStatefulWidget {
  final String catalogItemId;
  final ProductVariant? existingVariant;

  const VariantFormSheet({
    super.key,
    required this.catalogItemId,
    this.existingVariant,
  });

  @override
  ConsumerState<VariantFormSheet> createState() => _VariantFormSheetState();
}

class _VariantFormSheetState extends ConsumerState<VariantFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;

  // Free attributes: list of {key, value} pairs
  final List<Map<String, TextEditingController>> _attributes = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final v = widget.existingVariant;
    _skuController = TextEditingController(text: v?.sku ?? '');
    _barcodeController = TextEditingController(text: v?.barcode ?? '');
    _priceController = TextEditingController(text: v != null ? v.price.toString() : '');
    _stockController = TextEditingController(text: v != null ? v.stockQuantity.toString() : '0');

    if (v != null && v.attributes.isNotEmpty) {
      for (final entry in v.attributes.entries) {
        _attributes.add({
          'key': TextEditingController(text: entry.key),
          'value': TextEditingController(text: entry.value),
        });
      }
    }
  }

  @override
  void dispose() {
    _skuController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    for (final a in _attributes) {
      a['key']!.dispose();
      a['value']!.dispose();
    }
    super.dispose();
  }

  void _addAttribute() {
    setState(() => _attributes.add({
          'key': TextEditingController(),
          'value': TextEditingController(),
        }));
  }

  Map<String, String> _buildAttributes() {
    final result = <String, String>{};
    for (final a in _attributes) {
      final k = a['key']!.text.trim();
      final v = a['value']!.text.trim();
      if (k.isNotEmpty) result[k] = v;
    }
    return result;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId == null) return;

    setState(() => _submitting = true);
    try {
      final repo = ref.read(catalogRepositoryProvider);
      final body = {
        'sku': _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        'barcode': _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'stockQuantity': double.tryParse(_stockController.text.trim()) ?? 0,
        'attributes': _buildAttributes(),
      };

      if (widget.existingVariant == null) {
        await repo.createVariant(
          itemId: widget.catalogItemId,
          tenantId: tenantId,
          body: body,
        );
      } else {
        await repo.updateVariant(
          itemId: widget.catalogItemId,
          variantId: widget.existingVariant!.id,
          tenantId: tenantId,
          body: body,
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingVariant != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Modifier la variante' : 'Nouvelle variante',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('variant_price_field'),
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Prix *'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obligatoire';
                  if (double.tryParse(v) == null) return 'Nombre invalide';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('variant_stock_field'),
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock initial *'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obligatoire';
                  if (double.tryParse(v) == null) return 'Nombre invalide';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('variant_sku_field'),
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU (optionnel)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('variant_barcode_field'),
                controller: _barcodeController,
                decoration: const InputDecoration(labelText: 'Barcode (optionnel)'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Attributs', style: Theme.of(context).textTheme.bodyMedium),
                  TextButton.icon(
                    key: const Key('add_attribute_button'),
                    onPressed: _addAttribute,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              ..._attributes.asMap().entries.map((entry) {
                final i = entry.key;
                final a = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: Key('attr_key_$i'),
                          controller: a['key'],
                          decoration: const InputDecoration(
                            labelText: 'Label',
                            hintText: 'ex: Taille',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          key: Key('attr_value_$i'),
                          controller: a['value'],
                          decoration: const InputDecoration(
                            labelText: 'Valeur',
                            hintText: 'ex: XL',
                          ),
                        ),
                      ),
                      IconButton(
                        key: Key('remove_attr_$i'),
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _attributes.removeAt(i)),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('variant_submit_button'),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Modifier' : 'Créer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
