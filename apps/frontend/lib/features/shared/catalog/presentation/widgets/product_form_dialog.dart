import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

class ProductFormDialog extends ConsumerStatefulWidget {
  final Product? product;

  /// When [submitToCatalog] is true, the dialog calls [CatalogRepository.createItem]
  /// and [InventoryRepository.createMovement] directly on submit (backoffice flow).
  /// When false (default), the dialog pops with the modified [Product] and the
  /// caller is responsible for persisting (POS/inventory flow).
  final bool submitToCatalog;

  const ProductFormDialog({super.key, this.product, this.submitToCatalog = false});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  String? _selectedCategoryId;
  late TextEditingController _barcodeController;
  late TextEditingController _stockController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    _selectedCategoryId = widget.product?.categoryId;
    _barcodeController = TextEditingController(
      text: widget.product?.barcode ?? '',
    );
    _stockController = TextEditingController(
      text: widget.product?.stockQuantity.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier le produit' : 'Nouveau produit'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('product_name_field'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom du produit *'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('product_price_field'),
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Prix *',
                        suffixText: 'FCFA',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Obligatoire';
                        if (double.tryParse(value) == null) {
                          return 'Nombre invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                  // Stock initial only shown when creating (not editing)
                  if (!(widget.submitToCatalog && widget.product != null)) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        key: const Key('product_stock_field'),
                        controller: _stockController,
                        decoration: const InputDecoration(
                          labelText: 'Stock initial',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              double.tryParse(value) == null) {
                            return 'Nombre invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final categoriesAsync = ref.watch(categoriesProvider);
                  return categoriesAsync.when(
                    data: (categories) => DropdownButtonFormField<String>(
                      key: const Key('product_category_field'),
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Catégorie'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Aucune'),
                        ),
                        ...categories.map(
                          (c) => DropdownMenuItem(
                            value: c.remoteId,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                        });
                      },
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const Text('Erreur de chargement'),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('product_barcode_field'),
                controller: _barcodeController,
                decoration: const InputDecoration(labelText: 'Code-barres'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          key: const Key('product_submit_button'),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.product != null ? 'Modifier' : 'Créer'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.submitToCatalog) {
      await _submitToCatalogApi();
    } else {
      _submitLocal();
    }
  }

  // ── Backoffice catalog create/update flow ─────────────────────────────────

  Future<void> _submitToCatalogApi() async {
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId == null) return;

    setState(() => _isSubmitting = true);
    try {
      final catalogRepo = ref.read(catalogRepositoryProvider);
      final name = _nameController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final barcode = _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim();

      if (widget.product != null && widget.product!.remoteId != null) {
        // Edit existing product
        await catalogRepo.updateItem(
          id: widget.product!.remoteId!,
          name: name,
          price: price,
          tenantId: tenantId,
          categoryId: _selectedCategoryId,
          barcode: barcode,
        );
      } else {
        // Create new product
        final result = await catalogRepo.createItem(
          name: name,
          price: price,
          tenantId: tenantId,
          categoryId: _selectedCategoryId,
          barcode: barcode,
        );
        final initialStock = double.tryParse(_stockController.text.trim()) ?? 0;
        if (initialStock > 0) {
          final inventoryRepo = ref.read(inventoryRepositoryProvider);
          await inventoryRepo.createMovement(
            type: 'DELIVERY',
            catalogItemId: result['id'] as String,
            quantity: initialStock.toInt(),
            tenantId: tenantId,
          );
        }
      }

      ref.invalidate(catalogProvider);

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        final isEdit = widget.product != null;
        messenger.showSnackBar(
          SnackBar(
            key: Key(isEdit ? 'snackbar_product_updated' : 'snackbar_product_created'),
            content: Text(isEdit ? 'Produit modifié' : 'Produit ajouté'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const Key('snackbar_product_error'),
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── POS / inventory local flow (existing behaviour) ───────────────────────

  void _submitLocal() {
    final product = widget.product ?? Product();
    product.name = _nameController.text;
    product.price = double.parse(_priceController.text);
    product.categoryId = _selectedCategoryId;
    product.barcode =
        _barcodeController.text.isEmpty ? null : _barcodeController.text;
    if (widget.product == null) {
      product.stockQuantity = double.tryParse(_stockController.text) ?? 0;
    }
    Navigator.of(context).pop(product);
  }
}
