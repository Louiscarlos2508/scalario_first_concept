import 'package:flutter/material.dart';
import 'package:frontend/features/shared/catalog/data/models/product_variant.dart';

/// Bottom sheet displayed when a product with [hasVariants] is tapped.
/// Pops with the selected [ProductVariant].
class VariantSelectorSheet extends StatelessWidget {
  final String productName;
  final List<ProductVariant> variants;

  const VariantSelectorSheet({
    super.key,
    required this.productName,
    required this.variants,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            productName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Sélectionnez une variante',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Divider(height: 20),
          ...variants.map((v) {
            final outOfStock = v.stockQuantity <= 0;
            final label = v.attributes.entries.map((e) => '${e.key} ${e.value}').join(' · ');
            return ListTile(
              key: Key('variant_tile_${v.id}'),
              enabled: !outOfStock,
              title: Text(label.isEmpty ? 'Variante' : label),
              subtitle: Text('${v.stockQuantity.toStringAsFixed(0)} en stock'),
              trailing: Text(
                '${v.price.toStringAsFixed(0)} FCFA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: outOfStock ? Colors.grey : null,
                ),
              ),
              onTap: outOfStock ? null : () => Navigator.of(context).pop(v),
            );
          }),
          if (variants.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('Aucune variante disponible')),
            ),
        ],
      ),
    );
  }
}
