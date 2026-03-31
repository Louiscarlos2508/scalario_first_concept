import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/cart_item_tile.dart';

class CartItemList extends ConsumerWidget {
  const CartItemList({super.key, required this.isManager});

  final bool isManager;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider).items;

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => CartItemTile(
        item: items[index],
        index: index,
        isManager: isManager,
      ),
    );
  }
}
