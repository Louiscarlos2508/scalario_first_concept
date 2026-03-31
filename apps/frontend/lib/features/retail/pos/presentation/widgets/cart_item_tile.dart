import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/cart_helpers.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/cart_price_level_sheet.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/discount_dialog.dart';

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

    return ListTile(
      onLongPress: isManager && !item.isFreeItem
          ? () => showCartPriceLevelSheet(context, ref, index, item)
          : null,
      title: Row(
        children: [
          Expanded(
              child: Text(item.isFreeItem
                  ? '${item.product.name} (offert)'
                  : item.product.name)),
          // AC3 (Story 25-7) — PROMO badge
          if (hasPromo)
            Container(
              margin: const EdgeInsets.only(left: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PROMO',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AC5 (Story 25-3) — variant label
          if (item.variantLabel != null)
            Text(item.variantLabel!,
                style: const TextStyle(
                    fontSize: 11, color: Colors.blueGrey)),
          // Price line — strikethrough original + green discounted
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
                      fontSize: 12),
                ),
                const SizedBox(width: 6),
                Text(fcfa(item.total),
                    style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ],
            )
          else
            Text(item.product.unitType != 'piece'
                ? '${item.quantity} ${item.product.weightUnit ?? item.product.unitType} × ${fcfa(item.unitPrice)}'
                : item.isFreeItem
                    ? '${item.quantity.toInt()} × 0 FCFA'
                    : '${item.quantity.toInt()} × ${fcfa(item.unitPrice)}'),
          // Promo label
          if (hasPromo && item.appliedPromoLabel != null)
            Text(item.appliedPromoLabel!,
                style:
                    const TextStyle(fontSize: 11, color: Colors.green)),
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
                backgroundColor: Colors.blue.withAlpha(30),
              ),
            ),
          if (hasDiscount)
            Text(
              'Remise : ${item.discountType == 'PERCENTAGE' ? '${item.discountAmount}%' : fcfa(item.discountAmount)}',
              style:
                  const TextStyle(color: Colors.orange, fontSize: 12),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.isFreeItem ? '0 FCFA' : fcfa(item.total),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: item.isFreeItem ? Colors.green : null),
          ),
          if (!item.isFreeItem) ...[
            IconButton(
              icon: const Icon(Icons.edit_note),
              onPressed: isManager
                  ? () => showDialog(
                        context: context,
                        builder: (context) =>
                            DiscountDialog(item: item),
                      )
                  : null,
              tooltip: 'Appliquer une remise',
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => ref
                  .read(cartProvider.notifier)
                  .removeProduct(item.product),
            ),
          ],
        ],
      ),
    );
  }
}
