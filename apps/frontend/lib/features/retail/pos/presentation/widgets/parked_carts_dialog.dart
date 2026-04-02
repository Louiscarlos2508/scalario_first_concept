import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/sheet_style.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class ParkedCartsDialog extends ConsumerWidget {
  const ParkedCartsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parked = ref.watch(parkedCartsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          SheetTitleRow(
            title: 'Ventes en attente',
            icon: Icons.pause_circle_outline,
            iconColor: kSheetAmber,
            trailing: parked.isEmpty
                ? null
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kSheetAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${parked.length}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kSheetAmber),
                    ),
                  ),
          ),
          const SheetDivider(),
          const SizedBox(height: 12),

          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: parked.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: kSheetSlate200),
                        const SizedBox(height: 12),
                        const Text('Aucune vente en attente',
                            style: TextStyle(color: kSheetSlate500, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: parked.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final cart = parked[index];
                      return GestureDetector(
                        onTap: () {
                          ref.read(cartProvider.notifier).replaceCart(cart);
                          ref
                              .read(parkedCartsProvider.notifier)
                              .removeParkedCart(cart);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: kSheetSlate50,
                            border:
                                Border.all(color: kSheetSlate200, width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: kSheetAmber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                    Icons.shopping_cart_outlined,
                                    color: kSheetAmber,
                                    size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cart.name ?? 'Sans référence',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: kSheetSlate900),
                                    ),
                                    Text(
                                      '${cart.items.length} article${cart.items.length > 1 ? 's' : ''}',
                                      style: const TextStyle(
                                          fontSize: 11, color: kSheetSlate500),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _fcfa(cart.totalAmount),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: kSheetSlate900),
                                  ),
                                  const Text(
                                    'Reprendre →',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: kSheetBlue,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
