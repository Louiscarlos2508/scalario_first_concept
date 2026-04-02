import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/sheet_style.dart';
import 'package:frontend/features/shared/catalog/data/models/product_variant.dart';

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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          SheetTitleRow(title: productName),
          const Text(
            'Sélectionnez une variante',
            style: TextStyle(fontSize: 12, color: kSheetSlate500),
          ),
          const SizedBox(height: 12),
          const SheetDivider(),
          const SizedBox(height: 12),

          // ── Variant tiles ────────────────────────────────────────────────
          if (variants.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 40, color: kSheetSlate200),
                    const SizedBox(height: 8),
                    const Text('Aucune variante disponible',
                        style: TextStyle(color: kSheetSlate500)),
                  ],
                ),
              ),
            )
          else
            ...variants.map((v) {
              final outOfStock = v.stockQuantity <= 0;
              final label =
                  v.attributes.entries.map((e) => '${e.key}: ${e.value}').join(' · ');
              final priceLabel = NumberFormat.currency(
                      locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
                  .format(v.price);

              return GestureDetector(
                onTap: outOfStock ? null : () => Navigator.of(context).pop(v),
                child: Opacity(
                  opacity: outOfStock ? 0.5 : 1.0,
                  child: Container(
                    key: Key('variant_tile_${v.id}'),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: outOfStock ? kSheetSlate50 : Colors.white,
                      border: Border.all(color: kSheetSlate200, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label.isEmpty ? 'Variante' : label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: outOfStock ? kSheetSlate500 : kSheetSlate900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (outOfStock)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kSheetRed.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Rupture de stock',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: kSheetRed),
                                  ),
                                )
                              else
                                Text(
                                  '${v.stockQuantity.toStringAsFixed(0)} en stock',
                                  style: const TextStyle(
                                      fontSize: 11, color: kSheetSlate500),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: outOfStock
                                ? kSheetSlate50
                                : kSheetBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: outOfStock
                                  ? kSheetSlate200
                                  : kSheetBlue.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            priceLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: outOfStock ? kSheetSlate500 : kSheetBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
