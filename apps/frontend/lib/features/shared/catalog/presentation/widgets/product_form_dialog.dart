import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/business_type/data/business_type_config_repository.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/catalog/data/models/price_level.dart';
import 'package:frontend/features/shared/catalog/data/models/product_variant.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart';
import 'package:frontend/features/shared/catalog/presentation/widgets/variant_form_sheet.dart';
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

  // Epic 25 — Variantes
  bool _hasVariants = false;
  List<ProductVariant> _variants = [];
  // Epic 25 — Niveaux de prix
  List<PriceLevel> _priceLevels = [];

  // Epic 26 — Traçabilité
  bool _trackSerialNumbers = false;
  bool _hasWarranty = false;
  late TextEditingController _warrantyMonthsController;
  bool _requiresPrescription = false;
  bool _dynamicPricing = false;
  late TextEditingController _priceReasonController;
  bool _isUnique = false;

  // Epic 23 — Reconditionnement (parent-child)
  bool _isChildItem = false;
  String? _selectedParentItemId;
  String? _selectedParentName;
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _childItems = [];
  final _parentItemCtrl = TextEditingController();
  List<Map<String, dynamic>> _parentSuggestions = [];

  // Photo produit
  Uint8List? _selectedImageBytes;
  String? _existingImageUrl;
  bool _clearImage = false;

  // Epic 29 — Adaptive form (businessType)
  bool _showAdvanced = false;
  bool _defaultsApplied = false;

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
    _hasVariants = widget.product?.hasVariants ?? false;
    _variants = List.from(widget.product?.variants ?? []);
    _trackSerialNumbers = widget.product?.trackSerialNumbers ?? false;
    _requiresPrescription = widget.product?.requiresPrescription ?? false;
    _dynamicPricing = widget.product?.dynamicPricing ?? false;
    _isUnique = widget.product?.isUnique ?? false;
    _existingImageUrl = widget.product?.imageUrl;
    _priceReasonController = TextEditingController();
    final wm = widget.product?.warrantyMonths;
    _hasWarranty = wm != null && wm > 0;
    _warrantyMonthsController = TextEditingController(text: wm != null && wm > 0 ? wm.toString() : '');
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

      // Load price levels if editing an existing item
      if (widget.product?.remoteId != null) {
        final rawPriceLevels = await repo.getPriceLevels(
          itemId: widget.product!.remoteId!,
          tenantId: tenantId,
        );
        if (mounted) {
          setState(() => _priceLevels = rawPriceLevels.map(PriceLevel.fromJson).toList());
        }
      }

      // Load variants if editing an item with hasVariants
      if (widget.product?.hasVariants == true && widget.product?.remoteId != null) {
        final rawVariants = await repo.getVariants(
          itemId: widget.product!.remoteId!,
          tenantId: tenantId,
        );
        if (mounted) {
          setState(() {
            _variants = rawVariants.map(ProductVariant.fromJson).toList();
          });
        }
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

  Future<void> _openVariantSheet({ProductVariant? existing}) async {
    final itemId = widget.product?.remoteId;
    if (itemId == null) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => VariantFormSheet(
        catalogItemId: itemId,
        existingVariant: existing,
      ),
    );
    if (result == true) {
      // Reload variants
      final tenantId = ref.read(activeTenantProvider);
      if (tenantId == null) return;
      try {
        final rawVariants = await ref.read(catalogRepositoryProvider).getVariants(
          itemId: itemId,
          tenantId: tenantId,
        );
        if (mounted) setState(() => _variants = rawVariants.map(ProductVariant.fromJson).toList());
      } catch (_) {}
    }
  }

  Future<void> _openAddPriceLevelDialog() async {
    final itemId = widget.product?.remoteId;
    final tenantId = ref.read(activeTenantProvider);
    if (itemId == null || tenantId == null) return;

    final codeCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final minQtyCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter un niveau de prix'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code (ex: GROS)')),
            TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label (ex: Prix gros)')),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Prix *'), keyboardType: TextInputType.number),
            TextField(controller: minQtyCtrl, decoration: const InputDecoration(labelText: 'Qté min (optionnel)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Créer')),
        ],
      ),
    );

    if (confirmed == true && priceCtrl.text.trim().isNotEmpty) {
      try {
        await ref.read(catalogRepositoryProvider).createPriceLevel(
          itemId: itemId,
          tenantId: tenantId,
          body: {
            'levelCode': codeCtrl.text.trim().toUpperCase(),
            'label': labelCtrl.text.trim(),
            'price': double.tryParse(priceCtrl.text.trim()) ?? 0,
            if (minQtyCtrl.text.trim().isNotEmpty) 'minQty': int.tryParse(minQtyCtrl.text.trim()),
          },
        );
        // Reload price levels
        final raw = await ref.read(catalogRepositoryProvider).getPriceLevels(
          itemId: itemId,
          tenantId: tenantId,
        );
        if (mounted) setState(() => _priceLevels = raw.map(PriceLevel.fromJson).toList());
      } catch (_) {}
    }
    codeCtrl.dispose();
    labelCtrl.dispose();
    priceCtrl.dispose();
    minQtyCtrl.dispose();
  }

  bool _showSection(String section, List<String> visibleSections) {
    return _showAdvanced || visibleSections.isEmpty || visibleSections.contains(section);
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
    _warrantyMonthsController.dispose();
    _priceReasonController.dispose();
    _parentItemCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    // Epic 29 — Load businessType config and apply defaults on creation
    final configAsync = ref.watch(businessTypeConfigProvider);
    ref.listen<AsyncValue<BusinessTypeConfig>>(businessTypeConfigProvider,
        (prev, next) {
      if (!_defaultsApplied && widget.product == null) {
        next.whenData((config) {
          setState(() {
            _defaultsApplied = true;
            final flags = config.defaultFlags;
            _hasVariants = flags['hasVariants'] as bool? ?? false;
            _trackSerialNumbers = flags['trackSerialNumbers'] as bool? ?? false;
            final wm = flags['warrantyMonths'] as int?;
            if (wm != null && wm > 0) {
              _hasWarranty = true;
              _warrantyMonthsController.text = wm.toString();
            }
          });
        });
      }
    });
    final visibleSections = configAsync.maybeWhen(
      data: (config) => config.visibleSections,
      orElse: () => <String>[],
    );

    return AlertDialog(
      title: Text(isEditing ? 'Modifier le produit' : 'Nouveau produit'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Photo produit ──────────────────────────────────────────────
              _ImagePickerSection(
                imageBytes: _selectedImageBytes,
                imageUrl: _clearImage ? null : _existingImageUrl,
                onPick: _pickImage,
                onClear: () => setState(() {
                  _selectedImageBytes = null;
                  _clearImage = true;
                }),
              ),
              const SizedBox(height: 16),
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
                initialValue: _selectedUnitType,
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
                          if (_isUnique) {
                            final qty = double.tryParse(value ?? '') ?? 0;
                            if (qty > 1) return 'Article unique : stock limité à 1';
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
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const Key('product_parent_item_field'),
                      controller: _parentItemCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Article parent (≥ 2 car. pour chercher)',
                      ),
                      onChanged: (v) {
                        final q = v.toLowerCase();
                        setState(() {
                          _selectedParentItemId = null;
                          _selectedParentName = null;
                          _parentSuggestions = q.length < 2
                              ? []
                              : _allItems.where((item) {
                                  final isNotChild =
                                      item['parentItemId'] == null;
                                  final isNotSelf =
                                      item['id'] != widget.product?.remoteId;
                                  final matchesQuery =
                                      (item['name'] as String? ?? '')
                                          .toLowerCase()
                                          .contains(q);
                                  return isNotChild && isNotSelf && matchesQuery;
                                }).toList();
                        });
                      },
                      validator: (_) =>
                          _isChildItem && _selectedParentItemId == null
                              ? 'Sélectionnez un article parent'
                              : null,
                    ),
                    if (_parentSuggestions.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
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
                          itemCount: _parentSuggestions.length,
                          itemBuilder: (_, i) {
                            final opt = _parentSuggestions[i];
                            final label =
                                '${opt['name']} (${opt['unitType'] ?? 'piece'})';
                            return InkWell(
                              onTap: () => setState(() {
                                _parentItemCtrl.text = label;
                                _selectedParentItemId =
                                    opt['id'] as String?;
                                _selectedParentName =
                                    opt['name'] as String?;
                                _parentSuggestions = [];
                              }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                child: Text(label,
                                    style:
                                        const TextStyle(fontSize: 14)),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
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
              // Epic 29 — Toggle "Afficher plus d'options"
              if (widget.submitToCatalog) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
                    icon: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more),
                    label: Text(_showAdvanced
                        ? 'Masquer les options avancées'
                        : 'Afficher plus d\'options'),
                  ),
                ),
              ],
              // Epic 26 — Traçabilité (serial number tracking toggle)
              if (widget.submitToCatalog) ...[
                const SizedBox(height: 16),
                const Divider(),
                if (_showSection('serial', visibleSections))
                  SwitchListTile(
                    key: const Key('track_serial_numbers_toggle'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Traçabilité par numéro de série'),
                    subtitle: const Text('Demande un n° de série à la vente', style: TextStyle(fontSize: 12)),
                    value: _trackSerialNumbers,
                    onChanged: (v) => setState(() => _trackSerialNumbers = v),
                  ),
                SwitchListTile(
                  key: const Key('dynamic_pricing_toggle'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Prix dynamique'),
                  subtitle: const Text('Historique des prix enregistré à chaque modification', style: TextStyle(fontSize: 12)),
                  value: _dynamicPricing,
                  onChanged: (v) => setState(() => _dynamicPricing = v),
                ),
                if (_dynamicPricing && widget.product != null) ...[
                  TextFormField(
                    key: const Key('price_reason_field'),
                    controller: _priceReasonController,
                    decoration: const InputDecoration(
                      labelText: 'Motif de la modification (optionnel)',
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_showSection('prescription', visibleSections))
                  SwitchListTile(
                    key: const Key('requires_prescription_toggle'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Requiert une ordonnance'),
                    subtitle: const Text('Le caissier devra saisir un n° d\'ordonnance à chaque vente', style: TextStyle(fontSize: 12)),
                    value: _requiresPrescription,
                    onChanged: (v) => setState(() => _requiresPrescription = v),
                  ),
                if (_showSection('warranty', visibleSections)) ...[
                  SwitchListTile(
                    key: const Key('has_warranty_toggle'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Durée de garantie'),
                    subtitle: const Text('Un certificat sera généré automatiquement à chaque vente', style: TextStyle(fontSize: 12)),
                    value: _hasWarranty,
                    onChanged: (v) => setState(() {
                      _hasWarranty = v;
                      if (!v) _warrantyMonthsController.clear();
                    }),
                  ),
                  if (_hasWarranty) ...[
                    TextFormField(
                      key: const Key('warranty_months_field'),
                      controller: _warrantyMonthsController,
                      decoration: const InputDecoration(
                        labelText: 'Durée de garantie (mois) *',
                        hintText: 'Ex: 12',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (!_hasWarranty) return null;
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Nombre de mois invalide (> 0)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
                SwitchListTile(
                  key: const Key('is_unique_toggle'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Article unique'),
                  subtitle: const Text('Stock limité à 1 — archivé automatiquement après vente', style: TextStyle(fontSize: 12)),
                  value: _isUnique,
                  onChanged: (v) => setState(() => _isUnique = v),
                ),
                // Dupliquer button (edit mode only)
                if (widget.product?.remoteId != null)
                  TextButton.icon(
                    key: const Key('duplicate_item_button'),
                    onPressed: _isSubmitting ? null : _duplicateItem,
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Dupliquer cet article'),
                  ),
              ],
              // AC1 (Story 25-2) — Variants toggle + section
              if (widget.submitToCatalog && _showSection('variants', visibleSections)) ...[
                const SizedBox(height: 16),
                const Divider(),
                SwitchListTile(
                  key: const Key('has_variants_toggle'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cet article a des variantes'),
                  value: _hasVariants,
                  onChanged: (v) => setState(() => _hasVariants = v),
                ),
                if (_hasVariants) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Le prix et le stock de l\'article seront gérés par variante',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // AC3 — Variants table with total stock header
                  if (_variants.isNotEmpty) ...[
                    Row(
                      children: [
                        const Text('Variantes', style: TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(
                          'Stock total : ${_variants.fold<double>(0, (s, v) => s + v.stockQuantity).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ..._variants.map(
                      (v) => ListTile(
                        key: Key('variant_${v.id}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          v.attributes.entries.map((e) => '${e.key}: ${e.value}').join(' · '),
                        ),
                        subtitle: Text('${v.price.toStringAsFixed(0)} FCFA · Stock: ${v.stockQuantity.toStringAsFixed(0)}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openVariantSheet(existing: v),
                      ),
                    ),
                  ],
                  TextButton.icon(
                    key: const Key('add_variant_button'),
                    onPressed: widget.product?.remoteId != null ? () => _openVariantSheet() : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une variante'),
                  ),
                ],
              ],
              // AC1 (Story 25-5) — Tarification (price levels) section
              if (widget.submitToCatalog && widget.product?.remoteId != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  children: [
                    const Text('Tarification', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton.icon(
                      key: const Key('add_price_level_button'),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Ajouter'),
                      onPressed: () => _openAddPriceLevelDialog(),
                    ),
                  ],
                ),
                if (_priceLevels.isEmpty)
                  const Text('Aucun niveau configuré.', style: TextStyle(fontSize: 12)),
                ..._priceLevels.map(
                  (pl) => ListTile(
                    key: Key('price_level_${pl.id}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text('${pl.label} (${pl.levelCode})'),
                    subtitle: Text(
                      '${pl.price.toStringAsFixed(0)} FCFA${pl.minQty != null ? ' · min ${pl.minQty}' : ''}',
                    ),
                  ),
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

  Future<void> _duplicateItem() async {
    final id = widget.product?.remoteId;
    final tenantId = ref.read(activeTenantProvider);
    if (id == null || tenantId == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(catalogRepositoryProvider).duplicateItem(id: id, tenantId: tenantId);
      ref.invalidate(catalogProvider);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Article dupliqué')),
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
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 70,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) setState(() { _selectedImageBytes = bytes; _clearImage = false; });
  }

  Future<String?> _uploadImage(String tenantId) async {
    if (_selectedImageBytes == null) return null;
    final storage = Supabase.instance.client.storage;
    const bucket = 'product-images';
    final path = '$tenantId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await storage.from(bucket).uploadBinary(
      path,
      _selectedImageBytes!,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );
    return storage.from(bucket).getPublicUrl(path);
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

      final uploadedUrl = await _uploadImage(tenantId);
      final imageUrl = _clearImage ? null : (uploadedUrl ?? _existingImageUrl);

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
          clearParent: !_isChildItem && widget.product!.parentItemId != null,
          trackSerialNumbers: _trackSerialNumbers,
          warrantyMonths: _hasWarranty
              ? int.tryParse(_warrantyMonthsController.text.trim())
              : null,
          requiresPrescription: _requiresPrescription,
          dynamicPricing: _dynamicPricing,
          priceReason: _priceReasonController.text.trim().isNotEmpty
              ? _priceReasonController.text.trim()
              : null,
          isUnique: _isUnique,
          imageUrl: imageUrl,
          clearImage: _clearImage,
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
          trackSerialNumbers: _trackSerialNumbers,
          warrantyMonths: _hasWarranty
              ? int.tryParse(_warrantyMonthsController.text.trim())
              : null,
          requiresPrescription: _requiresPrescription,
          isUnique: _isUnique,
          imageUrl: imageUrl,
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

class _ImagePickerSection extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? imageUrl;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _ImagePickerSection({
    required this.imageBytes,
    required this.imageUrl,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null || imageUrl != null;
    return Row(
      children: [
        GestureDetector(
          onTap: onPick,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade100,
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: imageBytes != null
                        ? Image.memory(imageBytes!, fit: BoxFit.cover)
                        : Image.network(imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (ctx, e, st) =>
                                const Icon(Icons.broken_image, size: 40)),
                  )
                : const Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: Text(hasImage ? 'Changer la photo' : 'Ajouter une photo'),
            ),
            if (hasImage)
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              ),
            const Text(
              'Max 400×400 px · qualité 70%',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}
