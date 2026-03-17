import 'package:flutter/material.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';

/// Reusable product autocomplete widget.
/// Filters a [products] list by name, calls [onSelected] when user picks a product.
class ProductAutocomplete extends StatelessWidget {
  final List<Product> products;
  final void Function(Product) onSelected;
  final String labelText;
  final Key? fieldKey;
  final FormFieldValidator<String>? validator;

  const ProductAutocomplete({
    super.key,
    required this.products,
    required this.onSelected,
    this.labelText = 'Produit *',
    this.fieldKey,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Product>(
      displayStringForOption: (p) => p.name,
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return products;
        final query = textEditingValue.text.toLowerCase();
        return products.where(
          (p) => p.name.toLowerCase().contains(query),
        );
      },
      onSelected: onSelected,
      fieldViewBuilder: (ctx, ctrl, focusNode, _) => TextFormField(
        key: fieldKey,
        controller: ctrl,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: 'Rechercher un produit...',
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }
}
