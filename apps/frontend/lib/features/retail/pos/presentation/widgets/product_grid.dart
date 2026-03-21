import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/quantity_input_dialog.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/variant_selector_sheet.dart';
import 'package:frontend/features/shared/catalog/data/models/product_variant.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart';
import 'package:frontend/features/shared/catalog/presentation/widgets/freshness_chip.dart';
import 'package:frontend/features/shared/promotions/presentation/providers/promotions_providers.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class ProductGrid extends ConsumerWidget {
  const ProductGrid({super.key});

  /// AC3 (Story 24-2) — Freshness priority for sorting: 0=red, 1=orange, 2=green, 3=none.
  int _freshnessPriority(Product product, FreshnessThresholds thresholds) {
    if (product.nearestExpiryDate == null || product.expiryDays == null) return 3;
    final expiryDays = product.expiryDays!;
    if (expiryDays <= 0) return 3;
    final remainingHours = product.nearestExpiryDate!.difference(DateTime.now()).inHours;
    final percent = (remainingHours / 24.0 / expiryDays * 100).clamp(0.0, 100.0);
    if (percent < thresholds.orangeThreshold) return 0; // red — most urgent
    if (percent < thresholds.greenThreshold) return 1; // orange
    return 2; // green
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final urgentOnly = ref.watch(urgentOnlyFilterProvider);
    final thresholds = ref.watch(freshnessThresholdsProvider);

    return Column(
      children: [
        // Category + urgent filter bar
        SizedBox(
          height: 60,
          child: categoriesAsync.when(
            data: (categories) => ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: const Text('Tout'),
                    selected: selectedCategoryId == null,
                    onSelected: (_) {
                      ref.read(selectedCategoryIdProvider.notifier).state = null;
                    },
                  ),
                ),
                ...categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(c.name),
                        selected: selectedCategoryId == c.remoteId,
                        onSelected: (selected) {
                          ref.read(selectedCategoryIdProvider.notifier).state =
                              selected ? c.remoteId : null;
                        },
                      ),
                    )),
                // AC4 (Story 24-2) — "Articles urgents" toggle
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    key: const Key('filter_urgent'),
                    avatar: const Icon(Icons.warning_amber_rounded, size: 16),
                    label: const Text('Urgents'),
                    selected: urgentOnly,
                    selectedColor: Colors.orange.shade100,
                    onSelected: (val) =>
                        ref.read(urgentOnlyFilterProvider.notifier).state = val,
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: LinearProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: productsAsync.when(
            data: (allProducts) {
              // AC4 — filter to urgent only (orange or red freshness)
              var products = urgentOnly
                  ? allProducts
                      .where((p) => _freshnessPriority(p, thresholds) <= 1)
                      .toList()
                  : allProducts;

              // AC3 — sort within category: red → orange → green → none
              final sorted = List<Product>.from(products)
                ..sort((a, b) =>
                    _freshnessPriority(a, thresholds)
                        .compareTo(_freshnessPriority(b, thresholds)));

              if (sorted.isEmpty) {
                return const Center(child: Text('Aucun produit trouvé.'));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final product = sorted[index];
                  final isCritical = product.minStockLevel != null &&
                      product.stockQuantity <= product.minStockLevel!;
                  final isBulkParent = product.hasChildren;
                  final hasFreshness = product.nearestExpiryDate != null &&
                      product.expiryDays != null;

                  return Stack(
                    children: [
                      Card(
                        elevation: 2,
                        child: InkWell(
                          onTap: () async {
                            // AC1 (Story 25-3) — Variant selector
                            if (product.hasVariants) {
                              final tenantId = ref.read(activeTenantProvider);
                              List<ProductVariant> variants = List.from(product.variants);
                              if (variants.isEmpty && tenantId != null && product.remoteId != null) {
                                try {
                                  final raw = await ref.read(catalogRepositoryProvider).getVariants(
                                    itemId: product.remoteId!,
                                    tenantId: tenantId,
                                  );
                                  variants = raw.map(ProductVariant.fromJson).toList();
                                } catch (_) {}
                              }
                              if (!context.mounted) return;
                              final variant = await showModalBottomSheet<ProductVariant>(
                                context: context,
                                builder: (_) => VariantSelectorSheet(
                                  productName: product.name,
                                  variants: variants,
                                ),
                              );
                              if (variant != null) {
                                ref.read(cartProvider.notifier).addProductWithVariant(product, variant);
                              }
                              return;
                            }
                            if (product.unitType != 'piece') {
                              final qty = await showDialog<double>(
                                context: context,
                                builder: (_) =>
                                    QuantityInputDialog(product: product),
                              );
                              if (qty != null) {
                                ref
                                    .read(cartProvider.notifier)
                                    .addProductWithQuantity(product, qty);
                              }
                            } else {
                              // AC3 (Story 25-7) — check for active promotion before adding
                              final tenantId = ref.read(activeTenantProvider);
                              if (tenantId != null && product.remoteId != null) {
                                final promo = await ref
                                    .read(promotionsRepositoryProvider)
                                    .getActivePromotion(tenantId, product.remoteId!);
                                if (promo != null) {
                                  ref.read(cartProvider.notifier).addProductWithPromo(product, promo);
                                  return;
                                }
                              }
                              ref
                                  .read(cartProvider.notifier)
                                  .addProduct(product);
                            }
                          },
                          onLongPress: () =>
                              _showBranchStock(context, ref, product),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory_2,
                                  size: 48, color: Colors.teal),
                              const SizedBox(height: 8),
                              Text(
                                product.name,
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                product.unitType == 'piece'
                                    ? _fcfa(product.price)
                                    : '${_fcfa(product.price)}/${product.weightUnit ?? product.unitType}',
                                style:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // AC1 (Story 24-2) — FreshnessChip overlay (bottom-left)
                      if (hasFreshness)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: FreshnessChip(
                            key: Key('freshness_${product.remoteId}'),
                            expiresAt: product.nearestExpiryDate!,
                            expiryDays: product.expiryDays!,
                            greenThreshold: thresholds.greenThreshold,
                            orangeThreshold: thresholds.orangeThreshold,
                          ),
                        ),
                      if (isCritical)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Tooltip(
                            message:
                                'Stock critique : ${product.stockQuantity} restants',
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.warning,
                              size: 18,
                            ),
                          ),
                        ),
                      // AC3 — Badge "VRAC" for parent bulk items
                      if (isBulkParent)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            key: Key('badge_vrac_${product.remoteId}'),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.brown.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'VRAC',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      // AC5 (Story 26-6) — Badge "UNIQUE" for isUnique items
                      if (product.isUnique)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            key: Key('badge_unique_${product.remoteId}'),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade600,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'UNIQUE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      // Badge "VAR" for products with variants
                      if (product.hasVariants)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            key: Key('badge_var_${product.remoteId}'),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'VAR',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Erreur : $err')),
          ),
        ),
      ],
    );
  }

  void _showBranchStock(BuildContext context, WidgetRef ref, dynamic product) async {
    if (product.barcode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product has no barcode for lookup')),
      );
      return;
    }

    final user = ref.read(userProfileProvider).value;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => FutureBuilder<List<dynamic>>(
        future: ref.read(productRepositoryProvider).getStockAcrossBranches(product.barcode!, user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final stocks = snapshot.data ?? [];

          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Stock en magasins : ${product.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                if (stocks.isEmpty)
                  const Padding(padding: EdgeInsets.all(16), child: Text('No other branches found with this product.')),
                ...stocks.map((s) => ListTile(
                  title: Text(s['tenant']['name']),
                  trailing: Text(
                    '${s['stockQuantity']} left',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: (s['stockQuantity'] as num) > 5 ? Colors.green : Colors.red,
                    ),
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}
