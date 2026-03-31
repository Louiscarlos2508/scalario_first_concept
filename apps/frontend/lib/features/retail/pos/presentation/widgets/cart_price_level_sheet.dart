import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';
import 'package:frontend/features/shared/catalog/data/models/price_level.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart';

void showCartPriceLevelSheet(
    BuildContext context, WidgetRef ref, int index, CartItem item) {
  final tenantId = ref.read(activeTenantProvider);
  final itemId = item.product.remoteId;
  if (tenantId == null || itemId == null) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(catalogRepositoryProvider).getPriceLevels(
            itemId: itemId,
            tenantId: tenantId,
          ),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()));
        }
        final levels =
            (snapshot.data ?? []).map(PriceLevel.fromJson).toList();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Changer le niveau de prix',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const Divider(height: 20),
              if (levels.isEmpty)
                const Text('Aucun niveau configuré pour cet article.'),
              ...levels.map((pl) => ListTile(
                    title: Text(pl.label),
                    subtitle: Text(
                        '${pl.price.toStringAsFixed(0)} FCFA${pl.minQty != null ? ' · min ${pl.minQty}' : ''}'),
                    onTap: () {
                      ref
                          .read(cartProvider.notifier)
                          .applyPriceLevel(index, pl);
                      Navigator.of(ctx).pop();
                    },
                  )),
            ],
          ),
        );
      },
    ),
  );
}
