import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/cart_helpers.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/cart_price_level_sheet.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/discount_dialog.dart';

const _kSlate900 = Color(0xFF0F172A);
const _kSlate500 = Color(0xFF64748B);
const _kSlate200 = Color(0xFFE2E8F0);

class CartItemTile extends ConsumerWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.isManager,
  });

  final CartItem item;
  final int index;
  final bool isManager;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPromo = item.appliedPromoId != null && !item.isFreeItem;
    final hasDiscount = item.discountAmount > 0 && !hasPromo;
    final isPiece = item.product.unitType == 'piece';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onLongPress: isManager && !item.isFreeItem
                ? () => showCartPriceLevelSheet(context, ref, index, item)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Small avatar ────────────────────────────────────────
                  _ItemAvatar(name: item.product.name, imageUrl: item.product.imageUrl),
                  const SizedBox(width: 10),

                  // ── Info column ─────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name row + PROMO badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.isFreeItem
                                    ? '${item.product.name} (offert)'
                                    : item.product.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _kSlate900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasPromo)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'PROMO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 2),

                        // AC5 (Story 25-3) — variant label
                        if (item.variantLabel != null)
                          Text(
                            item.variantLabel!,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.blueGrey),
                          ),

                        // Price line
                        if (hasPromo)
                          Row(
                            children: [
                              Text(
                                item.product.unitType != 'piece'
                                    ? '${item.quantity} ${item.product.weightUnit ?? item.product.unitType} × ${fcfa(item.unitPrice)}'
                                    : '${item.quantity.toInt()} × ${fcfa(item.unitPrice)}',
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                fcfa(item.total),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            item.product.unitType != 'piece'
                                ? '${item.quantity} ${item.product.weightUnit ?? item.product.unitType} × ${fcfa(item.unitPrice)}'
                                : item.isFreeItem
                                    ? '${item.quantity.toInt()} × 0 FCFA'
                                    : '${item.quantity.toInt()} × ${fcfa(item.unitPrice)}',
                            style: const TextStyle(
                                fontSize: 11, color: _kSlate500),
                          ),

                        // Promo label
                        if (hasPromo && item.appliedPromoLabel != null)
                          Text(
                            item.appliedPromoLabel!,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.green),
                          ),

                        // AC3 (Story 25-5) — price level chip
                        if (item.appliedPriceLevelLabel != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Chip(
                              key: Key('price_level_chip_$index'),
                              label: Text(item.appliedPriceLevelLabel!),
                              labelStyle: const TextStyle(fontSize: 10),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              backgroundColor:
                                  Colors.blue.withAlpha(30),
                            ),
                          ),

                        if (hasDiscount)
                          Text(
                            'Remise : ${item.discountType == 'PERCENTAGE' ? '${item.discountAmount}%' : fcfa(item.discountAmount)}',
                            style: const TextStyle(
                                color: Colors.orange, fontSize: 11),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ── Controls column ─────────────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Total
                      Text(
                        item.isFreeItem ? '0 FCFA' : fcfa(item.total),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: item.isFreeItem
                              ? Colors.green
                              : _kSlate900,
                        ),
                      ),
                      const SizedBox(height: 6),

                      if (item.isFreeItem)
                        // Free items: no controls
                        const SizedBox.shrink()
                      else if (isPiece)
                        // Piece items: inline +/- qty controls
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isManager)
                              GestureDetector(
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (context) =>
                                      DiscountDialog(item: item),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.edit_note,
                                    size: 15,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            _QtyBtn(
                              icon: Icons.remove,
                              onTap: () => ref
                                  .read(cartProvider.notifier)
                                  .removeProduct(item.product),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: Text(
                                '${item.quantity.toInt()}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _kSlate900,
                                ),
                              ),
                            ),
                            _QtyBtn(
                              icon: Icons.add,
                              onTap: () => ref
                                  .read(cartProvider.notifier)
                                  .addProduct(item.product),
                            ),
                          ],
                        )
                      else
                        // Non-piece items: edit + remove icons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isManager)
                              GestureDetector(
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (context) =>
                                      DiscountDialog(item: item),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(
                                    Icons.edit_note,
                                    size: 18,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            GestureDetector(
                              onTap: () => ref
                                  .read(cartProvider.notifier)
                                  .removeProduct(item.product),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Qty button ────────────────────────────────────────────────────────────────

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _kSlate200, width: 1.5),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(icon, size: 12, color: const Color(0xFF374151)),
      ),
    );
  }
}

// ── Small item avatar ────────────────────────────────────────────────────────

class _ItemAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  const _ItemAvatar({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final colors = [
      Colors.teal, Colors.blue, Colors.orange,
      Colors.purple, Colors.green, Colors.red,
    ];
    final color = colors[name.codeUnitAt(0) % colors.length];

    Widget fallback = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );

    if (imageUrl == null) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl!,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }
}
