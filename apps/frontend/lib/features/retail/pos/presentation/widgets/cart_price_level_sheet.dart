import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/sheet_style.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';
import 'package:frontend/features/shared/catalog/data/models/price_level.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart';
import 'package:intl/intl.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

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
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final levels =
            (snapshot.data ?? []).map(PriceLevel.fromJson).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SheetTitleRow(
                title: 'Niveau de prix',
                icon: Icons.layers_outlined,
                trailing: Text(
                  item.product.name,
                  style: const TextStyle(fontSize: 11, color: kSheetSlate500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SheetDivider(),
              const SizedBox(height: 12),

              if (levels.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Aucun niveau de prix configuré.',
                        style: TextStyle(color: kSheetSlate500)),
                  ),
                )
              else
                ...levels.map((pl) {
                  final isActive = item.appliedPriceLevelLabel == pl.label;
                  return GestureDetector(
                    onTap: () {
                      ref
                          .read(cartProvider.notifier)
                          .applyPriceLevel(index, pl);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: isActive
                            ? kSheetBlue.withValues(alpha: 0.05)
                            : Colors.white,
                        border: Border.all(
                          color: isActive ? kSheetBlue : kSheetSlate200,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pl.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? kSheetBlue
                                        : kSheetSlate900,
                                  ),
                                ),
                                if (pl.minQty != null)
                                  Text(
                                    'Quantité min : ${pl.minQty}',
                                    style: const TextStyle(
                                        fontSize: 11, color: kSheetSlate500),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: kSheetBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _fcfa(pl.price),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kSheetBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    ),
  );
}
