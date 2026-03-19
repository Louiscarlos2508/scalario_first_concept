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
  late TextEditingController _unitLabelController;
  late TextEditingController _conversionRateController;
  late TextEditingController _minStockController;
  String _selectedUnitType = 'piece';
  bool _isSubmitting = false;

  // Epic 23 — Reconditionnement (parent-child)
  bool _isChildItem = false;
  String? _selectedParentItemId;
  String? _selectedParentName;
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _childItems = [];

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
    _selectedUnitType = widget.product?.unitType ?? 'piece';
    _unitLabelController = TextEditingController(
      text: widget.product?.weightUnit ?? '',
    );
    _conversionRateController = TextEditingController(
      text: widget.product?.conversionRate?.toString() ?? '',
    );
    _minStockController = TextEditingController(
      text: widget.product?.minStockLevel?.toString() ?? '',
    );
    _isChildItem = widget.product?.parentItemId != null;
    _selectedParentItemId = widget.product?.parentItemId;
    if (widget.submitToCatalog) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadCatalogItems());
    }
  }

  Future<void> _loadCatalogItems() async {
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId == null) return;
    final repo = ref.read(catalogRepositoryProvider);
    try {
      final items = await repo.listItems(tenantId: tenantId);
      if (mounted) setState(() => _allItems = items);

      // If editing a parent item, load its children
      if (widget.product?.remoteId != null) {
        final children = await repo.getChildren(
          id: widget.product!.remoteId!,
          tenantId: tenantId,
        );
        if (mounted) setState(() => _childItems = children);
      }

      // Resolve parent name for display
      if (_selectedParentItemId != null) {
        final parent = items.firstWhere(
          (i) => i['id'] == _selectedParentItemId,
          orElse: () => {},
        );
        if (mounted && parent.isNotEmpty) {
          setState(() => _selectedParentName = parent['name'] as String?);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    _stockController.dispose();
    _unitLabelController.dispose();
    _conversionRateController.dispose();
    _minStockController.dispose();
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
              DropdownButtonFormField<String>(
                key: const Key('product_unit_type_field'),
                value: _selectedUnitType,
                decoration: const InputDecoration(labelText: "Type d'unité"),
                items: const [
                  DropdownMenuItem(value: 'piece', child: Text('Pièce')),
                  DropdownMenuItem(value: 'weight', child: Text('Poids')),
                  DropdownMenuItem(value: 'volume', child: Text('Volume')),
                  DropdownMenuItem(value: 'length', child: Text('Longueur')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedUnitType = val);
                },
              ),
              if (_selectedUnitType != 'piece') ...[
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('product_unit_label_field'),
                  controller: _unitLabelController,
                  decoration: const InputDecoration(
                    labelText: 'Label unité *',
                    hintText: 'ex: kg, g, L, m',
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Obligatoire' : null,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('product_price_field'),
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: _selectedUnitType != 'piece'
                            ? 'Prix par ${_unitLabelController.text.isNotEmpty ? _unitLabelController.text : "unité"} *'
                            : 'Prix *',
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
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('product_min_stock_field'),
                controller: _minStockController,
                decoration: const InputDecoration(
                  labelText: 'Alerte si stock ≤',
                  hintText: 'Désactivé',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (double.tryParse(value) == null) return 'Nombre invalide';
                  return null;
                },
              ),
              // Epic 23 — Reconditionnement section
              const SizedBox(height: 16),
              SwitchListTile(
                key: const Key('product_is_child_item_toggle'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Cet article est un détail d\'un article vrac'),
                value: _isChildItem,
                onChanged: (val) => setState(() {
                  _isChildItem = val;
                  if (!val) {
                    _selectedParentItemId = null;
                    _selectedParentName = null;
                    _conversionRateController.clear();
                  }
                }),
              ),
              if (_isChildItem) ...[
                const SizedBox(height: 8),
                // Parent item autocomplete
                Autocomplete<Map<String, dynamic>>(
                  displayStringForOption: (opt) =>
                      '${opt['name']} (${opt['unitType'] ?? 'piece'})',
                  initialValue: _selectedParentName != null
                      ? TextEditingValue(text: _selectedParentName!)
                      : null,
                  optionsBuilder: (textEditingValue) {
                    final q = textEditingValue.text.toLowerCase();
                    if (q.length < 2) return const [];
                    return _allItems.where((item) {
                      final isNotChild = item['parentItemId'] == null;
                      final isNotSelf =
                          item['id'] != widget.product?.remoteId;
                      final matchesQuery = (item['name'] as String? ?? '')
                          .toLowerCase()
                          .contains(q);
                      return isNotChild && isNotSelf && matchesQuery;
                    }).toList();
                  },
                  onSelected: (opt) => setState(() {
                    _selectedParentItemId = opt['id'] as String?;
                    _selectedParentName = opt['name'] as String?;
                  }),
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) =>
                          TextFormField(
                    key: const Key('product_parent_item_field'),
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Article parent (≥ 2 car. pour chercher)',
                    ),
                    validator: (_) => _isChildItem &&
                            _selectedParentItemId == null
                        ? 'Sélectionnez un article parent'
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('product_child_conversion_rate_field'),
                  controller: _conversionRateController,
                  decoration: InputDecoration(
                    labelText: 'Facteur de conversion *',
                    helperText: _conversionRateController.text.isNotEmpty &&
                            _selectedParentName != null
                        ? 'Vendre 1 ${_nameController.text.isNotEmpty ? _nameController.text : "article"} '
                            'décrémente ${_conversionRateController.text} '
                            '${_selectedParentName ?? "parent"}'
                        : 'Ex: 0.02 si 1 sachet = 0.02 unité vrac',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (!_isChildItem) return null;
                    if (value == null || value.isEmpty) return 'Obligatoire';
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0 || parsed > 1) {
                      return 'Doit être un nombre > 0 et ≤ 1';
                    }
                    return null;
                  },
                ),
              ],
              // Advanced weight conversion settings (hidden for child items)
              if (_selectedUnitType != 'piece' && !_isChildItem) ...[
                const SizedBox(height: 8),
                ExpansionTile(
                  key: const Key('product_advanced_settings'),
                  title: const Text('Paramètres avancés'),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    TextFormField(
                      key: const Key('product_conversion_rate_field'),
                      controller: _conversionRateController,
                      decoration: const InputDecoration(
                        labelText: 'Facteur de conversion (optionnel)',
                        helperText: 'Ex: 0.5 si 1 sachet 500g = 0.5 kg stock',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final parsed = double.tryParse(value);
                        if (parsed == null || parsed <= 0) {
                          return 'Doit être un nombre décimal > 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ],
              // AC5 — Children list when editing a parent item
              if (widget.product != null && _childItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const Text(
                  'Articles détail liés',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ..._childItems.map(
                  (child) => ListTile(
                    key: Key('child_item_${child['id']}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(child['name'] as String? ?? ''),
                    subtitle: Text(
                      'Facteur: ${child['conversionRate'] ?? '—'} · ${child['unitType'] ?? 'piece'}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (_) => ProductFormDialog(
                          product: Product.fromJson(child),
                          submitToCatalog: widget.submitToCatalog,
                        ),
                      );
                    },
                  ),
                ),
              ],
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
      final conversionRate = _conversionRateController.text.trim().isEmpty
          ? null
          : double.tryParse(_conversionRateController.text.trim());

      final minStockLevel = _minStockController.text.trim().isEmpty
          ? null
          : double.tryParse(_minStockController.text.trim());

      if (widget.product != null && widget.product!.remoteId != null) {
        // Edit existing product
        await catalogRepo.updateItem(
          id: widget.product!.remoteId!,
          name: name,
          price: price,
          tenantId: tenantId,
          categoryId: _selectedCategoryId,
          barcode: barcode,
          unitType: _selectedUnitType,
          conversionRate: conversionRate,
          minStockLevel: minStockLevel,
          parentItemId: _isChildItem ? _selectedParentItemId : null,
          clearParent: !_isChildItem &&
              widget.product!.parentItemId != null,
        );
      } else {
        // Create new product
        final result = await catalogRepo.createItem(
          name: name,
          price: price,
          tenantId: tenantId,
          categoryId: _selectedCategoryId,
          barcode: barcode,
          unitType: _selectedUnitType,
          conversionRate: conversionRate,
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
    product.unitType = _selectedUnitType;
    product.weightUnit = _selectedUnitType != 'piece' &&
            _unitLabelController.text.isNotEmpty
        ? _unitLabelController.text
        : null;
    product.conversionRate = _conversionRateController.text.isEmpty
        ? null
        : double.tryParse(_conversionRateController.text);
    product.minStockLevel = _minStockController.text.isEmpty
        ? null
        : double.tryParse(_minStockController.text);
    product.parentItemId = _isChildItem ? _selectedParentItemId : null;
    if (widget.product == null) {
      product.stockQuantity = double.tryParse(_stockController.text) ?? 0;
    }
    Navigator.of(context).pop(product);
  }
}
