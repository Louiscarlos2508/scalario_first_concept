import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/product_autocomplete.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/providers/purchase_orders_providers.dart';

class _PoLine {
  Product? product;
  final TextEditingController qtyCtrl;
  _PoLine() : qtyCtrl = TextEditingController();
}

class CreatePurchaseOrderSheet extends ConsumerStatefulWidget {
  const CreatePurchaseOrderSheet({super.key});

  @override
  ConsumerState<CreatePurchaseOrderSheet> createState() =>
      _CreatePurchaseOrderSheetState();
}

class _CreatePurchaseOrderSheetState
    extends ConsumerState<CreatePurchaseOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();

  String? _selectedSupplierId;
  DateTime? _expectedDate;
  final List<_PoLine> _lines = [_PoLine()];
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _suppliersCache = [];
  bool _suppliersLoaded = false;
  final _supplierCtrl = TextEditingController();
  List<Map<String, dynamic>> _supplierSuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId == null) return;
    try {
      final repo = ref.read(purchaseOrdersRepositoryProvider);
      final list = await repo.listSuppliers(tenantId);
      if (mounted) {
        setState(() {
          _suppliersCache = list;
          _suppliersLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _suppliersLoaded = true);
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _supplierCtrl.dispose();
    for (final l in _lines) {
      l.qtyCtrl.dispose();
    }
    super.dispose();
  }

  bool get _canSubmit =>
      !_isSubmitting &&
      _selectedSupplierId != null &&
      _lines.isNotEmpty &&
      _lines.every((l) => l.product != null && l.qtyCtrl.text.isNotEmpty);

  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final tenantId = ref.read(activeTenantProvider) ?? '';

    final linePayloads = _lines
        .where((l) => l.product != null)
        .map((l) => {
              'catalogItemId': l.product!.remoteId!,
              'expectedQuantity': double.tryParse(l.qtyCtrl.text) ?? 1.0,
            })
        .toList();

    try {
      final repo = ref.read(purchaseOrdersRepositoryProvider);
      await repo.createOrder(
        tenantId: tenantId,
        supplierId: _selectedSupplierId,
        expectedDate: _expectedDate,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        lines: linePayloads,
      );

      if (mounted) {
        ref.invalidate(purchaseOrdersProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            key: Key('snackbar_po_created'),
            content: Text('Commande créée'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDate ?? DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _expectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final paginatedAsync = ref.watch(paginatedProductListProvider);
    final products = paginatedAsync.maybeWhen(
      data: (data) => (data['items'] as List).cast<Product>(),
      orElse: () => <Product>[],
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('Nouvelle commande',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Supplier autocomplete
              if (!_suppliersLoaded)
                const LinearProgressIndicator()
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const Key('po_supplier_field'),
                      controller: _supplierCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Fournisseur *',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        final q = v.toLowerCase();
                        setState(() {
                          _supplierSuggestions = q.isEmpty
                              ? _suppliersCache
                              : _suppliersCache
                                  .where((s) => (s['name']?.toString() ?? '')
                                      .toLowerCase()
                                      .contains(q))
                                  .toList();
                          if (v.isEmpty) _selectedSupplierId = null;
                        });
                      },
                      onTap: () {
                        if (_supplierSuggestions.isEmpty) {
                          setState(() => _supplierSuggestions = _suppliersCache);
                        }
                      },
                      validator: (_) => _selectedSupplierId == null
                          ? 'Sélectionnez un fournisseur'
                          : null,
                    ),
                    if (_supplierSuggestions.isNotEmpty)
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
                          itemCount: _supplierSuggestions.length,
                          itemBuilder: (_, i) {
                            final s = _supplierSuggestions[i];
                            return InkWell(
                              onTap: () => setState(() {
                                _supplierCtrl.text =
                                    s['name']?.toString() ?? '';
                                _selectedSupplierId = s['id']?.toString();
                                _supplierSuggestions = [];
                              }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                child: Text(s['name']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 14)),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),

              const SizedBox(height: 12),

              // Expected date picker
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date de livraison prévue (optionnel)',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _expectedDate != null
                        ? '${_expectedDate!.day.toString().padLeft(2, '0')}/${_expectedDate!.month.toString().padLeft(2, '0')}/${_expectedDate!.year}'
                        : 'Choisir une date',
                    style: TextStyle(
                      color: _expectedDate != null
                          ? null
                          : Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Notes
              TextFormField(
                key: const Key('po_notes_field'),
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              Text('Articles commandés',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),

              // Lines list
              ..._lines.asMap().entries.map((entry) {
                final idx = entry.key;
                final line = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ProductAutocomplete(
                          products: products,
                          fieldKey: Key('po_line_product_$idx'),
                          labelText: 'Produit *',
                          onSelected: (p) =>
                              setState(() => line.product = p),
                          validator: (_) =>
                              line.product == null ? 'Requis' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          key: Key('po_line_qty_$idx'),
                          controller: line.qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Qté *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requis';
                            final n = double.tryParse(v);
                            if (n == null || n <= 0) return 'Invalide';
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error),
                        onPressed: _lines.length > 1
                            ? () => setState(() {
                                  line.qtyCtrl.dispose();
                                  _lines.removeAt(idx);
                                })
                            : null,
                      ),
                    ],
                  ),
                );
              }),

              TextButton.icon(
                key: const Key('po_add_line_button'),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un article'),
                onPressed: () => setState(() => _lines.add(_PoLine())),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  key: const Key('po_submit_button'),
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Créer la commande'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
