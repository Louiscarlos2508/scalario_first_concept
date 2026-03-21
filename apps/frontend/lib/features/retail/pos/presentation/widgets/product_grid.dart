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
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class ProductGrid extends ConsumerStatefulWidget {
  const ProductGrid({super.key});

  @override
  ConsumerState<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends ConsumerState<ProductGrid> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final urgentOnly = ref.watch(urgentOnlyFilterProvider);
    final thresholds = ref.watch(freshnessThresholdsProvider);
    final config = ref.watch(businessTypeConfigProvider).valueOrNull;
    final showFreshness = config == null || config.visibleSections.contains('freshness');
    final searchQuery = ref.watch(posSearchQueryProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un produit...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(posSearchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
            onChanged: (v) => ref.read(posSearchQueryProvider.notifier).state = v,
          ),
        ),
        const SizedBox(height: 4),
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
                // AC4 (Story 24-2) — "Articles urgents" toggle (épicerie only)
                if (showFreshness)
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
              // Filter by search query
              final q = searchQuery.trim().toLowerCase();
              var products = q.isEmpty
                  ? allProducts
                  : allProducts.where((p) =>
                      p.name.toLowerCase().contains(q) ||
                      (p.barcode?.toLowerCase().contains(q) ?? false)).toList();

              // AC4 — filter to urgent only (orange or red freshness)
              if (urgentOnly) {
                products = products
                    .where((p) => _freshnessPriority(p, thresholds) <= 1)
                    .toList();
              }

              // AC3 — sort within category: red → orange → green → none
              final sorted = List<Product>.from(products)
                ..sort((a, b) =>
                    _freshnessPriority(a, thresholds)
                        .compareTo(_freshnessPriority(b, thresholds)));

              if (sorted.isEmpty) {
                return const Center(child: Text('Aucun produit trouvé.'));
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final cols = w < 600 ? 2 : w < 900 ? 3 : 4;
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                  final product = sorted[index];
                  final isCritical = product.minStockLevel != null &&
                      product.stockQuantity <= product.minStockLevel!;
                  final isBulkParent = product.hasChildren;
                  final hasFreshness = showFreshness &&
                      product.nearestExpiryDate != null &&
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
                              if (product.imageUrl != null)
                                SizedBox(
                                  height: 72,
                                  width: double.infinity,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                    child: Image.network(
                                      product.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, st) =>
                                          _ProductAvatar(name: product.name),
                                    ),
                                  ),
                                )
                              else
                                _ProductAvatar(name: product.name),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  product.name,
                                  style: Theme.of(context).textTheme.titleSmall,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                product.unitType == 'piece'
                                    ? _fcfa(product.price)
                                    : '${_fcfa(product.price)}/${product.weightUnit ?? product.unitType}',
                                style: Theme.of(context).textTheme.bodySmall,
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
        const SnackBar(content: Text('Ce produit n\'a pas de code-barres')),
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
                  const Padding(padding: EdgeInsets.all(16), child: Text('Aucune autre succursale ne dispose de ce produit.')),
                ...stocks.map((s) => ListTile(
                  title: Text(s['tenant']['name']),
                  trailing: Text(
                    '${s['stockQuantity']} restant(s)',
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

class _ProductAvatar extends StatelessWidget {
  final String name;
  const _ProductAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final colors = [
      Colors.teal, Colors.blue, Colors.orange,
      Colors.purple, Colors.green, Colors.red,
    ];
    final color = colors[name.codeUnitAt(0) % colors.length];
    return SizedBox(
      height: 72,
      width: double.infinity,
      child: ColoredBox(
        color: color.withValues(alpha: 0.15),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
