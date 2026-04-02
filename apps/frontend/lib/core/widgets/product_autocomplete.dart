import 'package:flutter/material.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';

/// Product search field with inline suggestions — no Overlay usage.
///
/// Works correctly inside dialogs and bottom sheets (avoids z-order issues
/// caused by Flutter's [Autocomplete] inserting into the root Overlay).
class ProductAutocomplete extends StatefulWidget {
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
  State<ProductAutocomplete> createState() => _ProductAutocompleteState();
}

class _ProductAutocompleteState extends State<ProductAutocomplete> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  List<Product> _suggestions = [];
  bool _selected = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _selected = false;
    final query = value.toLowerCase();
    setState(() {
      _suggestions = query.isEmpty
          ? widget.products
          : widget.products
              .where((p) => p.name.toLowerCase().contains(query))
              .toList();
    });
  }

  void _pick(Product product) {
    _selected = true;
    _ctrl.text = product.name;
    setState(() => _suggestions = []);
    _focusNode.unfocus();
    widget.onSelected(product);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: widget.fieldKey,
          controller: _ctrl,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: 'Rechercher un produit...',
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _ctrl.clear();
                      setState(() => _suggestions = []);
                    },
                  )
                : null,
          ),
          onChanged: _onChanged,
          onTap: () {
            if (_suggestions.isEmpty && !_selected) {
              setState(() => _suggestions = widget.products);
            }
          },
          validator: widget.validator,
        ),
        if (_suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: Colors.black12),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (_, i) {
                final p = _suggestions[i];
                return InkWell(
                  onTap: () => _pick(p),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Text(p.name,
                        style: const TextStyle(fontSize: 14)),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
