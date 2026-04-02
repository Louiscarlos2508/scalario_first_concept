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

String _unitLabel(String unitType) {
  switch (unitType) {
    case 'piece': return 'Unité';
    case 'kg':    return 'Au kg';
    case 'g':     return 'Au gramme';
    case 'litre': return 'Au litre';
    case 'ml':    return 'Au ml';
    case 'metre': return 'Au mètre';
    default:      return unitType;
  }
}

/// Meta line: variant count, vrac, or unit label.
String _productMeta(Product product) {
  if (product.hasVariants) {
    final count = product.variants.length;
    if (count > 1) return '$count options · ${_unitLabel(product.unitType)}';
    return 'Plusieurs options';
  }
  if (product.hasChildren) return 'Vrac · ${_unitLabel(product.unitType)}';
  return _unitLabel(product.unitType);
}

/// Price line: "Dès X" for variants with known prices, else unit price.
String _productPrice(Product product) {
  if (product.hasVariants && product.variants.isNotEmpty) {
    final prices = product.variants.map((v) => v.price);
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    return 'Dès ${_fcfa(minPrice)}';
  }
  if (product.unitType == 'piece') return _fcfa(product.price);
  return '${_fcfa(product.price)} / ${product.weightUnit ?? _unitLabel(product.unitType)}';
}

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

// Palette
const _kSlate900 = Color(0xFF0F172A);
const _kSlate500 = Color(0xFF64748B);
const _kSlate200 = Color(0xFFE2E8F0);
const _kBlue     = Color(0xFF1A73E8);
const _kGreen    = Color(0xFF34A853);
const _kAmber    = Color(0xFFFBBF24);
const _kRed      = Color(0xFFEA4335);
const _kGreenBg  = Color(0xFFF0FDF4);

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
    final cartItems = ref.watch(cartProvider).items;

    return Column(
      children: [
        // ── Search bar ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un produit...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(posSearchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kSlate200, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kSlate200, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kBlue, width: 1.5),
              ),
            ),
            onChanged: (v) => ref.read(posSearchQueryProvider.notifier).state = v,
          ),
        ),

        // ── Category + urgent filter bar ─────────────────────────────────────
        SizedBox(
          height: 52,
          child: categoriesAsync.when(
            data: (categories) => ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _FilterChip(
                    label: 'Tout',
                    selected: selectedCategoryId == null,
                    onTap: () => ref.read(selectedCategoryIdProvider.notifier).state = null,
                  ),
                ),
                ...categories.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _FilterChip(
                    label: c.name,
                    selected: selectedCategoryId == c.remoteId,
                    onTap: () => ref.read(selectedCategoryIdProvider.notifier).state =
                        selectedCategoryId == c.remoteId ? null : c.remoteId,
                  ),
                )),
                // AC4 (Story 24-2) — "Articles urgents" toggle (épicerie only)
                if (showFreshness)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _FilterChip(
                      key: const Key('filter_urgent'),
                      label: 'Urgents',
                      icon: Icons.warning_amber_rounded,
                      selected: urgentOnly,
                      selectedColor: const Color(0xFFFFF7ED),
                      selectedBorderColor: _kAmber,
                      selectedLabelColor: const Color(0xFFF59E0B),
                      onTap: () => ref.read(urgentOnlyFilterProvider.notifier).state = !urgentOnly,
                    ),
                  ),
              ],
            ),
            loading: () => const Center(child: LinearProgressIndicator()),
            error: (_, _) => const SizedBox(),
          ),
        ),

        Container(height: 1, color: _kSlate200),

        // ── Product grid ──────────────────────────────────────────────────────
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
                return const Center(
                  child: Text(
                    'Aucun produit trouvé.',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final cols = w < 600 ? 2 : w < 900 ? 3 : 4;
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisExtent: 192,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final product = sorted[index];
                      final isCritical = product.minStockLevel != null &&
                          product.stockQuantity <= product.minStockLevel!;
                      final isLowStock = !isCritical &&
                          product.minStockLevel != null &&
                          product.stockQuantity <= product.minStockLevel! * 1.5;
                      final isBulkParent = product.hasChildren;
                      final hasFreshness = showFreshness &&
                          product.nearestExpiryDate != null &&
                          product.expiryDays != null;

                      // In-cart state
                      final cartEntry = cartItems
                          .where((ci) => ci.product.id == product.id)
                          .toList();
                      final isInCart = cartEntry.isNotEmpty;
                      final cartQty = cartEntry.fold(
                          0.0, (sum, ci) => sum + ci.quantity);

                      // Stock level display
                      Color stockColor = _kSlate500;
                      String stockText = '${product.stockQuantity.toInt()} en stock';
                      if (isCritical) {
                        stockColor = _kRed;
                        stockText = 'Critique: ${product.stockQuantity.toInt()}';
                      } else if (isLowStock) {
                        stockColor = const Color(0xFFF59E0B);
                        stockText = 'Stock bas: ${product.stockQuantity.toInt()}';
                      }

                      // Border color
                      final borderColor = isInCart
                          ? _kGreen
                          : isCritical
                              ? _kRed
                              : isLowStock
                                  ? _kAmber
                                  : _kSlate200;

                      return Stack(
                        children: [
                          // ── Card ──────────────────────────────────────────
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isInCart ? _kGreenBg : Colors.white,
                                border: Border.all(color: borderColor, width: 1.5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Material(
                                color: Colors.transparent,
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
                                        isScrollControlled: true,
                                        useSafeArea: true,
                                        showDragHandle: true,
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // ── Photo / placeholder (top, full width) ──
                                      SizedBox(
                                        height: 72,
                                        width: double.infinity,
                                        child: product.imageUrl != null
                                            ? Image.network(
                                                product.imageUrl!,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: 72,
                                                loadingBuilder: (_, child, progress) =>
                                                    progress == null
                                                        ? child
                                                        : _ProductImagePlaceholder(name: product.name),
                                                errorBuilder: (_, _, _) =>
                                                    _ProductImagePlaceholder(name: product.name),
                                              )
                                            : _ProductImagePlaceholder(name: product.name),
                                      ),
                                      // ── Text content (fills remaining height) ─
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Name
                                              Text(
                                                product.name,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: _kSlate900,
                                                  height: 1.25,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              // Meta: variants / vrac / unit
                                              Text(
                                                _productMeta(product),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const Spacer(),
                                              // Price — pinned to bottom
                                              Text(
                                                _productPrice(product),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: _kSlate900,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              // Stock level
                                              Text(
                                                stockText,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: stockColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ── In-cart badge OR critical warning (top-right) ─
                          if (isInCart)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                key: Key('badge_incart_${product.remoteId}'),
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: _kGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    cartQty > 9 ? '9+' : cartQty.toInt().toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else if (isCritical)
                            Positioned(
                              top: 6,
                              right: 6,
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

                          // AC1 (Story 24-2) — FreshnessChip overlay (bottom-left)
                          if (hasFreshness)
                            Positioned(
                              bottom: 6,
                              left: 6,
                              child: FreshnessChip(
                                key: Key('freshness_${product.remoteId}'),
                                expiresAt: product.nearestExpiryDate!,
                                expiryDays: product.expiryDays!,
                                greenThreshold: thresholds.greenThreshold,
                                orangeThreshold: thresholds.orangeThreshold,
                              ),
                            ),

                          // AC3 — Badge "VRAC" for parent bulk items
                          if (isBulkParent)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                key: Key('badge_vrac_${product.remoteId}'),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
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
                              top: 6,
                              left: 6,
                              child: Container(
                                key: Key('badge_unique_${product.remoteId}'),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
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
                              bottom: 6,
                              right: 6,
                              child: Container(
                                key: Key('badge_var_${product.remoteId}'),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
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
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
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

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? selectedColor;
  final Color? selectedBorderColor;
  final Color? selectedLabelColor;

  const _FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.selectedColor,
    this.selectedBorderColor,
    this.selectedLabelColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = selectedColor ?? const Color(0xFFEFF6FF);
    final activeBorder = selectedBorderColor ?? const Color(0xFF1A73E8);
    final activeLabel = selectedLabelColor ?? const Color(0xFF1A73E8);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeBg : Colors.white,
          border: Border.all(
            color: selected ? activeBorder : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: selected ? activeLabel : const Color(0xFF64748B)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? activeLabel : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product image placeholder (full-width colored strip) ─────────────────────

class _ProductImagePlaceholder extends StatelessWidget {
  final String name;
  const _ProductImagePlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final colors = [
      Colors.teal, Colors.blue, Colors.orange,
      Colors.purple, Colors.green, Colors.red,
    ];
    final color = colors[name.codeUnitAt(0) % colors.length];
    return ColoredBox(
      color: color.withValues(alpha: 0.10),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}
