import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  const ClientOrderLineFormWidget({
    super.key,
    required this.products,
    required this.onRemove,
    required this.onChange,
  });

  @override
  State<ClientOrderLineFormWidget> createState() =>
      _ClientOrderLineFormWidgetState();
}

class _ClientOrderLineFormWidgetState extends State<ClientOrderLineFormWidget> {
  Product? _product;
  ProductVariant? _variant;
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();

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
    widget.onChange(
      ClientOrderLineValue(
        catalogItemId: _product!.remoteId ?? _product!.id.toString(),
        variantId: _variant?.id,
        quantity: qty,
        unitPrice: price,
      ),
    );
  }

  void _onProductSelected(Product p) {
    setState(() {
      _product = p;
      _variant = null;
      _priceController.text = p.price.toStringAsFixed(0);
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final hasVariants =
        _product?.hasVariants == true &&
        (_product?.variants.isNotEmpty ?? false);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ProductAutocomplete(
                    products: widget.products,
                    onSelected: _onProductSelected,
                    labelText: 'Article *',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: widget.onRemove,
                  tooltip: 'Supprimer la ligne',
                ),
              ],
            ),
            if (hasVariants) ...[
              const SizedBox(height: 6),
              DropdownButtonFormField<ProductVariant>(
                initialValue: _variant,
                decoration: const InputDecoration(
                  labelText: 'Variante *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _product!.variants
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(
                          v.sku ??
                              v.attributes.entries
                                  .map((e) => '${e.key}: ${e.value}')
                                  .join(', '),
                        ),
                      ),
                    )
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
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyController,
                    decoration: const InputDecoration(
                      labelText: 'Qté *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (_) => _notify(),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Quantité > 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Prix unitaire *',
                      suffixText: 'FCFA',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (_) => _notify(),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Prix > 0';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
