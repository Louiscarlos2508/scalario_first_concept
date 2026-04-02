import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/theme/sheet_style.dart';
import 'package:frontend/core/widgets/product_autocomplete.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/shared/catalog/data/models/product_variant.dart';

class ClientOrderLineValue {
  final String catalogItemId;
  final String? variantId;
  final double quantity;
  final double unitPrice;

  const ClientOrderLineValue({
    required this.catalogItemId,
    this.variantId,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() => {
        'catalogItemId': catalogItemId,
        if (variantId != null) 'variantId': variantId,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
}

class ClientOrderLineFormWidget extends StatefulWidget {
  final List<Product> products;
  final VoidCallback onRemove;
  final void Function(ClientOrderLineValue?) onChange;
  final ClientOrderLineValue? initialValue;

  const ClientOrderLineFormWidget({
    super.key,
    required this.products,
    required this.onRemove,
    required this.onChange,
    this.initialValue,
  });

  @override
  State<ClientOrderLineFormWidget> createState() =>
      _ClientOrderLineFormWidgetState();
}

class _ClientOrderLineFormWidgetState
    extends State<ClientOrderLineFormWidget> {
  Product? _product;
  ProductVariant? _variant;
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final init = widget.initialValue;
    if (init != null) {
      _qtyController.text =
          init.quantity.toStringAsFixed(init.quantity % 1 == 0 ? 0 : 2);
      _priceController.text = init.unitPrice.toStringAsFixed(0);
      try {
        _product = widget.products
            .firstWhere((p) => p.remoteId == init.catalogItemId);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _notify() {
    final qty = double.tryParse(_qtyController.text);
    final price = double.tryParse(_priceController.text);
    if (_product == null ||
        qty == null ||
        qty <= 0 ||
        price == null ||
        price <= 0) {
      widget.onChange(null);
      return;
    }
    if (_product!.hasVariants &&
        _product!.variants.isNotEmpty &&
        _variant == null) {
      widget.onChange(null);
      return;
    }
    widget.onChange(ClientOrderLineValue(
      catalogItemId: _product!.remoteId ?? _product!.id.toString(),
      variantId: _variant?.id,
      quantity: qty,
      unitPrice: price,
    ));
  }

  void _onProductSelected(Product p) {
    setState(() {
      _product = p;
      _variant = null;
      _priceController.text = p.price.toStringAsFixed(0);
    });
    _notify();
  }

  // Subtotal for this line
  double get _lineTotal {
    final qty = double.tryParse(_qtyController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return qty * price;
  }

  @override
  Widget build(BuildContext context) {
    final hasVariants = _product?.hasVariants == true &&
        (_product?.variants.isNotEmpty ?? false);
    final isComplete = _product != null &&
        (double.tryParse(_qtyController.text) ?? 0) > 0 &&
        (double.tryParse(_priceController.text) ?? 0) > 0 &&
        (!hasVariants || _variant != null);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isComplete
            ? kSheetBlue.withValues(alpha: 0.03)
            : kSheetSlate50,
        border: Border.all(
          color: isComplete ? kSheetBlue.withValues(alpha: 0.2) : kSheetSlate200,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product search + remove ────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ProductAutocomplete(
                    products: widget.products,
                    onSelected: _onProductSelected,
                    labelText: 'Article *',
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onRemove,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: kSheetRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline,
                        size: 16, color: kSheetRed),
                  ),
                ),
              ],
            ),

            // ── Variant selector ───────────────────────────────────────
            if (hasVariants) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<ProductVariant>(
                initialValue: _variant,
                decoration: sheetInputDecoration(label: 'Variante *'),
                items: _product!.variants
                    .map((v) => DropdownMenuItem(
                          value: v,
                          child: Text(
                            v.sku ??
                                v.attributes.entries
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join(' · '),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _variant = v;
                    if (v != null) {
                      _priceController.text = v.price.toStringAsFixed(0);
                    }
                  });
                  _notify();
                },
              ),
            ],

            const SizedBox(height: 8),

            // ── Qty + Price row ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyController,
                    decoration: sheetInputDecoration(label: 'Qté *'),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (_) {
                      setState(() {});
                      _notify();
                    },
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Qté > 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    decoration:
                        sheetInputDecoration(label: 'Prix unitaire *', suffix: 'FCFA'),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (_) {
                      setState(() {});
                      _notify();
                    },
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Prix > 0';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            // ── Line subtotal ──────────────────────────────────────────
            if (isComplete) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kSheetBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '= ${_lineTotal.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kSheetBlue,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
