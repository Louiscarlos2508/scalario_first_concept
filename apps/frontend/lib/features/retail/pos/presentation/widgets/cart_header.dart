import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/parked_carts_dialog.dart';

class CartHeader extends ConsumerWidget {
  const CartHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider).items;
    final parkedCount = ref.watch(parkedCartsProvider).length;

    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Title
          const Text(
            'Panier',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          // Item count badge
          if (cartItems.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${cartItems.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],

          const Spacer(),

          // Parked carts button
          if (parkedCount > 0)
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    showDragHandle: true,
                    builder: (context) => const ParkedCartsDialog(),
                  ),
                  icon: const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF1A73E8),
                    size: 20,
                  ),
                  tooltip: 'Ventes en attente',
                  visualDensity: VisualDensity.compact,
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFCC00),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$parkedCount',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            IconButton(
              onPressed: null,
              icon: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFFCBD5E1),
                size: 20,
              ),
              visualDensity: VisualDensity.compact,
            ),

          // Clear cart button
          IconButton(
            onPressed: cartItems.isEmpty
                ? null
                : () => ref.read(cartProvider.notifier).clearCart(),
            icon: Icon(
              Icons.delete_outline,
              color: cartItems.isEmpty
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF94A3B8),
              size: 20,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
