import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/retail/backoffice/presentation/screens/dashboard_screen.dart'
    show activeBreadcrumbSubLabel;
import 'package:frontend/features/shared/catalog/presentation/screens/product_detail_screen.dart';
import 'package:intl/intl.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Produits Screen — Figma 48:2
// Mobile: grid cards  ·  Desktop: sidebar + data table
// ══════════════════════════════════════════════════════════════════════════════

// ── Mock data — Figma 48:7 / 48:372 ────────────────────────────────────────

const _mockProducts = <Map<String, dynamic>>[
  {
    'name': 'Banane sucrée',
    'emoji': '🍌',
    'categoryName': 'Fruits',
    'retailPrice': 800,
    'wholesalePrice': 650,
    'unit': 'kg',
    'stockQuantity': 0,
    'maxStockLevel': 30,
    'minStockLevel': 5,
    'ean': '6151200001',
    'freshnessStatus': 'green',
    'gradientStart': 0xFFFEF3C7,
    'gradientEnd': 0xFFFDE68A,
    'emojiBg': 0xFFFEF3C7,
  },
  {
    'name': 'Tomate fraîche',
    'emoji': '🍅',
    'categoryName': 'Légumes',
    'retailPrice': 600,
    'wholesalePrice': 450,
    'unit': 'kg',
    'stockQuantity': 3,
    'maxStockLevel': 20,
    'minStockLevel': 5,
    'ean': '6151200012',
    'freshnessStatus': 'orange',
    'gradientStart': 0xFFFEE2E2,
    'gradientEnd': 0xFFFCA5A5,
    'emojiBg': 0xFFFEE2E2,
  },
  {
    'name': 'Salade laitue',
    'emoji': '🥬',
    'categoryName': 'Légumes',
    'retailPrice': 300,
    'wholesalePrice': null,
    'unit': 'pièce',
    'stockQuantity': 28,
    'maxStockLevel': 50,
    'minStockLevel': 10,
    'ean': '6151200023',
    'freshnessStatus': 'green',
    'gradientStart': 0xFFDCFCE7,
    'gradientEnd': 0xFF86EFAC,
    'emojiBg': 0xFFDCFCE7,
  },
  {
    'name': 'Lait Laiterie 1L',
    'emoji': '🥛',
    'categoryName': 'Frais',
    'retailPrice': 1200,
    'wholesalePrice': 1050,
    'unit': 'L',
    'stockQuantity': 8,
    'maxStockLevel': 30,
    'minStockLevel': 10,
    'ean': '6151200044',
    'freshnessStatus': 'red',
    'gradientStart': 0xFFDBEAFE,
    'gradientEnd': 0xFFBFDBFE,
    'emojiBg': 0xFFDBEAFE,
  },
  {
    'name': 'Papaye',
    'emoji': '🍠',
    'categoryName': 'Fruits',
    'retailPrice': 500,
    'wholesalePrice': null,
    'unit': 'pièce',
    'stockQuantity': 42,
    'maxStockLevel': 60,
    'minStockLevel': 10,
    'ean': '6151200055',
    'freshnessStatus': 'green',
    'gradientStart': 0xFFFED7AA,
    'gradientEnd': 0xFFFDBA74,
    'emojiBg': 0xFFFED7AA,
  },
  {
    'name': 'Mangue Kent',
    'emoji': '🥭',
    'categoryName': 'Fruits',
    'retailPrice': 400,
    'wholesalePrice': null,
    'unit': 'pièce',
    'stockQuantity': 85,
    'maxStockLevel': 100,
    'minStockLevel': 15,
    'ean': '6151200066',
    'freshnessStatus': 'green',
    'gradientStart': 0xFFFEF3C7,
    'gradientEnd': 0xFFFCD34D,
    'emojiBg': 0xFFFEF3C7,
  },
  {
    'name': 'Poisson Capitaine',
    'emoji': '🐟',
    'categoryName': 'Frais',
    'retailPrice': 3500,
    'wholesalePrice': 3100,
    'unit': 'kg',
    'stockQuantity': 5,
    'maxStockLevel': 15,
    'minStockLevel': 8,
    'ean': '6151200067',
    'freshnessStatus': 'red',
    'gradientStart': 0xFFCFFAFE,
    'gradientEnd': 0xFF67E8F9,
    'emojiBg': 0xFFCFFAFE,
  },
  {
    'name': 'Poulet bicyclette',
    'emoji': '🍗',
    'categoryName': 'Frais',
    'retailPrice': 2800,
    'wholesalePrice': 2500,
    'unit': 'kg',
    'stockQuantity': 22,
    'maxStockLevel': 30,
    'minStockLevel': 5,
    'ean': '6151200077',
    'freshnessStatus': 'green',
    'gradientStart': 0xFFFEF9C3,
    'gradientEnd': 0xFFFDE047,
    'emojiBg': 0xFFFEF9C3,
  },
];

// Hardcoded sidebar counts to match Figma display (142 total)
const _mockCategoryCountsFigma = <String, int>{
  'Toutes': 142,
  'Fruits': 38,
  'Légumes': 24,
  'Frais': 18,
  'Céréales': 12,
  'Épices': 22,
  'Conserves': 14,
  'Hygiène': 14,
};

const _mockQuickFilterCounts = <String, int>{
  'rupture': 2,
  'stock_bas': 4,
  'fraicheur': 2,
};

const _categoryEmojis = <String, String>{
  'Fruits': '🍎',
  'Légumes': '🥬',
  'Frais': '🥩',
  'Céréales': '🌾',
  'Épices': '🌶',
  'Conserves': '🥫',
  'Hygiène': '🧴',
};

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  int _chipIndex = 0; // 0=Tous, 1=Rupture, 2=Stock bas, 3=Fraîcheur, 4=Périmé
  String? _selectedCategory; // null = Toutes
  final _nf = NumberFormat('#,###', 'fr_FR');
  // Toggle mock data: true = Figma demo, false = empty state
  final bool _hasProducts = true;
  // Desktop: selected product for inline detail view (stays in shell)
  Map<String, dynamic>? _selectedProduct;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filter logic ──────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> items) {
    var result = items.toList();

    // Text search
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result
          .where((p) =>
              (p['name']?.toString() ?? '').toLowerCase().contains(q) ||
              (p['ean']?.toString() ?? '').contains(q) ||
              (p['categoryName']?.toString() ?? '').toLowerCase().contains(q))
          .toList();
    }

    // Category
    if (_selectedCategory != null) {
      result = result
          .where((p) => p['categoryName'] == _selectedCategory)
          .toList();
    }

    // Chip / quick filters
    switch (_chipIndex) {
      case 1: // Rupture
        result = result.where((p) {
          final stock = (p['stockQuantity'] as num?)?.toDouble() ?? 0;
          return stock <= 0;
        }).toList();
      case 2: // Stock bas
        result = result.where((p) {
          final stock = (p['stockQuantity'] as num?)?.toDouble() ?? 0;
          final min = (p['minStockLevel'] as num?)?.toDouble() ?? 0;
          return stock > 0 && min > 0 && stock < min;
        }).toList();
      case 3: // Fraîcheur
        result = result.where((p) {
          final fresh = p['freshnessStatus']?.toString();
          return fresh == 'red' || fresh == 'orange';
        }).toList();
      case 4: // Périmé
        result = result.where((p) {
          final fresh = p['freshnessStatus']?.toString();
          return fresh == 'expired';
        }).toList();
    }

    return result;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final allProducts =
        _hasProducts ? _mockProducts.toList() : <Map<String, dynamic>>[];
    final filtered = _filter(allProducts);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    // Listen for breadcrumb clicks: when sub-label is cleared externally
    // (e.g. clicking "Stock" in breadcrumb), go back to product list.
    ref.listen(activeBreadcrumbSubLabel, (prev, next) {
      if (prev != null && next == null && _selectedProduct != null && mounted) {
        setState(() => _selectedProduct = null);
      }
    });

    if (isDesktop) {
      if (_selectedProduct != null) {
        final product = _selectedProduct!;
        // Set breadcrumb sub-label to product name
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedProduct != null) {
            ref.read(activeBreadcrumbSubLabel.notifier).state =
                product['name']?.toString();
          }
        });
        return _buildDesktopDetail(product);
      } else {
        // Clear breadcrumb sub-label
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(activeBreadcrumbSubLabel.notifier).state = null;
          }
        });
      }
      return _buildDesktop(allProducts, filtered, _hasProducts);
    }
    return _buildMobile(allProducts, filtered, _hasProducts);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MOBILE — Figma 48:7
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMobile(List<Map<String, dynamic>> all,
      List<Map<String, dynamic>> filtered, bool hasProducts) {
    final isSearching = _search.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: ScalarioAppBar(
        title: 'Produits',
      ),
      body: Column(
        children: [
          // ── Search bar — Figma 48:22 / 48:272 (active) ──
          Container(
            height: 70.8,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      // Active: white bg + blue border. Inactive: grey bg
                      color: isSearching
                          ? Colors.white
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: isSearching
                          ? Border.all(
                              color: const Color(0xFF1565C0), width: 0.8)
                          : null,
                    ),
                    padding: const EdgeInsets.only(left: 14, right: 14),
                    child: Row(
                      children: [
                        Text('\uD83D\uDD0D',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSearching
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSearching
                                    ? const Color(0xFF1565C0)
                                    : const Color(0xFF64748B))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _search = v),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Rechercher un produit\u2026',
                              hintStyle: TextStyle(
                                  fontSize: 13, color: Color(0xFF64748B)),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (isSearching)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                            },
                            child: const Text('\u2715',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B))),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                      child: Text('\uD83D\uDCF7',
                          style: TextStyle(fontSize: 22))),
                ),
              ],
            ),
          ),

          // ── Search results or normal view ──
          if (isSearching)
            Expanded(child: _buildMobileSearchResults(all))
          else ...[
            // Filter chips — Figma 48:32
            if (hasProducts) _buildMobileChips(all),
            // Grid or empty
            Expanded(
              child: hasProducts
                  ? _buildMobileGrid(filtered)
                  : _buildMobileEmpty(),
            ),
          ],
        ],
      ),

      // ── FAB — Figma 48:257: 64x64, rounded=32, shadow, "+" 32px Light ──
      floatingActionButton: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
                color: Color(0x661565C0),
                blurRadius: 24,
                offset: Offset(0, 8)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: () => _showCreateProduct(),
            child: const Center(
                child: Text('+',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                        color: Colors.white))),
          ),
        ),
      ),
    );
  }

  // ── Mobile filter chips — Figma 48:32 ─────────────────────────────────────

  Widget _buildMobileChips(List<Map<String, dynamic>> all) {
    final chips = [
      _ChipData('Tous', _mockCategoryCountsFigma['Toutes']!, true),
      _ChipData('Rupture', _mockQuickFilterCounts['rupture']!, false),
      _ChipData('Stock bas', _mockQuickFilterCounts['stock_bas']!, false),
      _ChipData('Fraîcheur \uD83D\uDD34', _mockQuickFilterCounts['fraicheur']!, false),
      _ChipData('Périmé', null, false),
    ];

    return Container(
      height: 59,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
      ),
      clipBehavior: Clip.hardEdge,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, top: 14, bottom: 14),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final chip = chips[i];
          final isActive = _chipIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _chipIndex = i),
            child: Container(
              height: 31,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : (i == 0
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFFEF3C7)),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isActive
                      ? AppColors.primary
                      : (i == 0
                          ? Colors.transparent
                          : const Color(0xFFFDE68A)),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chip.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : (i == 0
                              ? const Color(0xFF64748B)
                              : const Color(0xFF92400E)),
                    ),
                  ),
                  if (chip.count != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withValues(alpha: 0.3)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${chip.count}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Mobile search results — Figma 48:264 ───────────────────────────────────

  Widget _buildMobileSearchResults(List<Map<String, dynamic>> all) {
    final q = _search.toLowerCase();
    final results = all
        .where((p) =>
            (p['name']?.toString() ?? '').toLowerCase().contains(q) ||
            (p['ean']?.toString() ?? '').contains(q) ||
            (p['categoryName']?.toString() ?? '').toLowerCase().contains(q))
        .toList();

    const recentSearches = ['salade', 'papaye', 'lait laiterie'];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results card
          if (results.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < results.length; i++)
                    _searchResultRow(results[i], q, i < results.length - 1),
                ],
              ),
            ),

          // Recent searches
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.only(left: 0),
            child: Text('RECHERCHES RÉCENTES',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B))),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: recentSearches
                .map((s) => GestureDetector(
                      onTap: () {
                        _searchCtrl.text = s;
                        setState(() => _search = s);
                      },
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.transparent, width: 0.8),
                        ),
                        child: Center(
                          child: Text(s,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B))),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _searchResultRow(
      Map<String, dynamic> p, String query, bool showBorder) {
    final name = p['name']?.toString() ?? '';
    final emoji = p['emoji']?.toString() ?? '\uD83D\uDCE6';
    final cat = p['categoryName']?.toString() ?? '';
    final price = (p['retailPrice'] as num?)?.toDouble() ?? 0;
    final unit = p['unit']?.toString() ?? '';
    final stock = (p['stockQuantity'] as num?)?.toDouble() ?? 0;

    return Container(
      height: 49.2,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: showBorder
            ? const Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8))
            : null,
      ),
      child: Row(
        children: [
          // Emoji — 18px
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          // Name + subtitle
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name with highlighted search term
                _highlightedText(name, query),
                const SizedBox(height: 2),
                // Subtitle: category · price · stock
                Text(
                  '$cat \u00B7 ${_nf.format(price)} F/$unit \u00B7 Stock ${stock.toInt()}',
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Highlights [query] occurrences in [text] with blue bold
  Widget _highlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: Colors.black));
    }
    final lower = text.toLowerCase();
    final qLower = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lower.indexOf(qLower, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: const TextStyle(
            fontWeight: FontWeight.w800, color: Color(0xFF1565C0)),
      ));
      start = idx + query.length;
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: Colors.black),
        children: spans,
      ),
    );
  }

  // ── Mobile product grid — Figma 48:60 ─────────────────────────────────────

  Widget _buildMobileGrid(List<Map<String, dynamic>> products) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Aucun produit ne correspond au filtre',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 220,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => _ProductCard(product: products[i], nf: _nf),
    );
  }

  // ── Mobile empty — Figma 48:334 ───────────────────────────────────────────

  Widget _buildMobileEmpty() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: const Color(0xFFE2E8F0), width: 1.6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Center(
                  child: Text('\uD83D\uDCE6',
                      style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 16),
            const Text('Aucun produit encore',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 6),
            const Text(
              'Créez votre premier produit pour démarrer votre catalogue. Vous pourrez ajouter photo, prix, stock, fraîcheur, vrac.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.5),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _showCreateProduct(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('+ Créer un produit',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DESKTOP — Figma 48:372
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktop(List<Map<String, dynamic>> all,
      List<Map<String, dynamic>> filtered, bool hasProducts) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title bar ──
          Container(
            height: 96,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Produits',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text(
                        'Catalogue complet \u00B7 ${_mockCategoryCountsFigma['Toutes']} produits \u00B7 valeur stock 1 240 600 F',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                // Actions
                _desktopAction('\u2913 Exporter', null),
                const SizedBox(width: 10),
                _desktopAction('\uD83D\uDCF7 Scan', null),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _showCreateProduct(),
                  child: Container(
                    height: 40.8,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Nouveau produit',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body: sidebar + content ──
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar
                Container(
                  width: 240,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        right:
                            BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
                  ),
                  child: _buildDesktopSidebar(all),
                ),
                // Main content
                Expanded(
                  child: hasProducts
                      ? _buildDesktopTable(filtered)
                      : _buildDesktopEmpty(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopAction(String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40.8,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A))),
        ),
      ),
    );
  }

  Widget _desktopSmallAction(String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38.8,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A))),
        ),
      ),
    );
  }

  // ── Desktop detail (inline in shell) — Figma 47:588 ────────────────────────

  Widget _buildDesktopDetail(Map<String, dynamic> product) {
    final name = product['name']?.toString() ?? '';
    final cat = product['categoryName']?.toString() ?? '';
    final emoji = product['emoji']?.toString() ?? '📦';
    final unit = product['unit']?.toString() ?? '';
    final retailPrice = (product['retailPrice'] as num?)?.toDouble() ?? 0;
    final wholesalePrice = (product['wholesalePrice'] as num?)?.toDouble();
    final purchasePrice = wholesalePrice ?? (retailPrice * 0.75);
    final stock = (product['stockQuantity'] as num?)?.toDouble() ?? 0;
    final minStock = (product['minStockLevel'] as num?)?.toDouble() ?? 0;
    final ean = product['ean']?.toString() ?? '';
    final freshStatus = product['freshnessStatus']?.toString() ?? 'green';
    final gradStart = Color(product['gradientStart'] as int? ?? 0xFFF1F5F9);
    final gradEnd = Color(product['gradientEnd'] as int? ?? 0xFFE2E8F0);

    final stockValue = (stock * retailPrice).toInt();
    final soldMonth = (stock * 5.25).toInt();

    // Stock KPI color
    Color stockKpiColor;
    if (stock <= 0) {
      stockKpiColor = AppColors.error;
    } else if (minStock > 0 && stock < minStock) {
      stockKpiColor = AppColors.warning;
    } else {
      stockKpiColor = const Color(0xFF0F172A);
    }

    // Freshness dot
    Color freshDot;
    switch (freshStatus) {
      case 'red':
      case 'expired':
        freshDot = AppColors.freshRed;
      case 'orange':
        freshDot = AppColors.freshOrange;
      default:
        freshDot = AppColors.freshGreen;
    }

    // Alert badges
    final badges = <Widget>[];
    if (stock <= 0) {
      badges.add(_dtBadge('RUPTURE', const Color(0xFFC62828), Colors.white));
    } else if (minStock > 0 && stock < minStock) {
      badges.add(
          _dtBadge('⚠ Stock bas', const Color(0xFFFEF3C7), const Color(0xFF92400E)));
    }
    if (freshStatus == 'orange') {
      badges.add(_dtBadge(
          '🔸 Fraîcheur orange', const Color(0xFFFECACA), const Color(0xFF991B1B)));
    } else if (freshStatus == 'red' || freshStatus == 'expired') {
      badges.add(_dtBadge(
          '🔴 Périmé · à retirer', const Color(0xFFC62828), Colors.white));
    }

    final alertThreshold = minStock > 0 ? minStock.toInt() : 15;
    final autonomy = stock > 0 ? '~${(stock / 1.4).toInt()} j' : '0 j';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title bar — Figma 47:633 ──
          Container(
            height: 102.8,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
            ),
            child: Row(
              children: [
                // Left: name + subtitle
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$name locale',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A))),
                      const SizedBox(height: 6),
                      Text('$cat · Frais · EAN ${_dtFormatEan(ean)}',
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                // Right: action buttons
                Row(
                  children: [
                    _dtOutlinedBtn('🖨 Imprimer étiquette'),
                    const SizedBox(width: 10),
                    _dtOutlinedBtn('📊 Mouvements'),
                    const SizedBox(width: 10),
                    // Réapprovisionner — yellow if stock bas
                    if (minStock > 0 && stock < minStock) ...[
                      _dtFilledBtn('⚠ Réapprovisionner',
                          const Color(0xFFF9A825), Colors.white),
                      const SizedBox(width: 10),
                    ],
                    _dtFilledBtn(
                        '✎ Éditer', AppColors.primary, Colors.white),
                  ],
                ),
              ],
            ),
          ),

          // ── Content — two columns ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
              child: IntrinsicHeight(
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Main card (left) ──
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFE2E8F0), width: 0.8),
                      ),
                      padding: const EdgeInsets.all(20.8),
                      child: Column(
                        children: [
                          // ── Hero row: image + info ──
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 240),
                            child: IntrinsicHeight(
                            child: Row(
                              children: [
                                // Gradient image
                                Container(
                                  width: 280,
                                  height: 240,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: LinearGradient(
                                      begin: const Alignment(-0.7, -0.7),
                                      end: const Alignment(0.7, 0.7),
                                      colors: [gradStart, gradEnd],
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(
                                          child: Text(emoji,
                                              style: const TextStyle(
                                                  fontSize: 110))),
                                      Positioned(
                                        right: 14,
                                        top: 14,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: freshDot,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: Colors.white,
                                                width: 2.4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Category
                                      Text('$cat · Frais · Local'
                                              .toUpperCase(),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF64748B),
                                              letterSpacing: 0.5)),
                                      const SizedBox(height: 6),
                                      // Name
                                      Text('$name locale',
                                          style: const TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF0F172A))),
                                      const SizedBox(height: 8),
                                      // EAN + supplier
                                      Text(
                                          'EAN ${_dtFormatEan(ean)} · Fournisseur Marché Sankaryaré',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'RobotoMono',
                                              color: Color(0xFF64748B))),
                                      if (badges.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Wrap(spacing: 6, children: badges),
                                      ],
                                      const Spacer(),
                                      // KPI cards row
                                      Row(
                                        children: [
                                          _dtKpiCard(
                                              '${stock.toInt()} $unit',
                                              'Stock actuel',
                                              stockKpiColor),
                                          const SizedBox(width: 12),
                                          _dtKpiCard(
                                              '${_nf.format(stockValue)} F',
                                              'Valeur stock',
                                              const Color(0xFF0F172A)),
                                          const SizedBox(width: 12),
                                          _dtKpiCard(
                                              '$soldMonth $unit',
                                              'Vendus 30j',
                                              const Color(0xFF0F172A)),
                                          const SizedBox(width: 12),
                                          _dtKpiCard('+33%',
                                              'Marge moyenne',
                                              const Color(0xFF0F172A)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ),
                          const SizedBox(height: 20),
                          // ── 2×2 section grid ──
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left column
                              Expanded(
                                child: Column(
                                  children: [
                                    _dtSectionCard(
                                      title: '💰 Prix',
                                      height: 194,
                                      rows: [
                                        _dtRow('Achat',
                                            '${_nf.format(purchasePrice.toInt())} F / $unit'),
                                        _dtRow('Détail',
                                            '${_nf.format(retailPrice.toInt())} F / $unit'),
                                        if (wholesalePrice != null)
                                          _dtRow('Gros (≥ 5 $unit)',
                                              '${_nf.format(wholesalePrice.toInt())} F / $unit'),
                                        _dtRowWidget('Marge', _dtMarginBadge()),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _dtSectionCard(
                                      title: '🌡️ Fraîcheur',
                                      height: 151.6,
                                      rows: [
                                        _dtRow('Durée de vie', '5 jours'),
                                        _dtRowColored('Lot ancien',
                                            _dtFreshText(freshStatus),
                                            _dtFreshColor(freshStatus)),
                                      ],
                                      bottom: _dtFreshnessBar(freshStatus),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Right column
                              Expanded(
                                child: Column(
                                  children: [
                                    _dtSectionCard(
                                      title: '📦 Stock & seuils',
                                      height: 194,
                                      rows: [
                                        _dtRowColored('Quantité',
                                            '${stock.toInt()} $unit',
                                            stockKpiColor),
                                        _dtRow('Seuil alerte',
                                            '$alertThreshold $unit'),
                                        _dtRow('Unité', unit),
                                        _dtRowColored('Autonomie',
                                            autonomy, stockKpiColor),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _dtSectionCard(
                                      title: '📉 Frotte',
                                      height: 151.6,
                                      rows: [
                                        _dtRow('Taux', '3.5%'),
                                        _dtRow('Cumul mois', '1.2 $unit'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // ── Movements sidebar (right) — Figma 47:816 ──
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFE2E8F0), width: 0.8),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Derniers mouvements',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A))),
                              Text('Voir tout →',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ..._dtMovements(unit),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Desktop detail helpers ────────────────────────────────────────────────

  Widget _dtOutlinedBtn(String label) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 43.2,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
      ),
    );
  }

  Widget _dtFilledBtn(String label, Color bg, Color fg) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 43.2,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: fg)),
      ),
    );
  }

  Widget _dtBadge(String text, Color bg, Color fg) {
    return Container(
      height: 22.8,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text.toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: 0.3)),
    );
  }

  Widget _dtKpiCard(String value, String label, Color valueColor) {
    return Expanded(
      child: Container(
        height: 110.4,
        padding: const EdgeInsets.fromLTRB(14.8, 14.8, 14.8, 14.8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'RobotoMono',
                      color: valueColor)),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 74,
              child: Text(label.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.3)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dtSectionCard({
    required String title,
    required double height,
    required List<Widget> rows,
    Widget? bottom,
  }) {
    return Container(
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5)),
          const SizedBox(height: 12),
          ...rows,
          if (bottom != null) ...[
            const SizedBox(height: 8),
            bottom,
          ],
        ],
      ),
    );
  }

  Widget _dtRow(String label, String value) {
    return _dtRowColored(label, value, const Color(0xFF0F172A));
  }

  Widget _dtRowColored(String label, String value, Color color) {
    return Container(
      height: 33.6,
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: Color(0xFFE2E8F0),
                width: 0.8,
                strokeAlign: BorderSide.strokeAlignInside)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'RobotoMono',
                  color: color)),
        ],
      ),
    );
  }

  Widget _dtRowWidget(String label, Widget trailing) {
    return SizedBox(
      height: 34.8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B))),
          trailing,
        ],
      ),
    );
  }

  Widget _dtMarginBadge() {
    return Container(
      height: 18.8,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Text('+33%',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF166534))),
    );
  }

  Widget _dtFreshnessBar(String status) {
    final daysLeft = status == 'red' ? 1 : (status == 'orange' ? 2 : 4);
    final labelColor = status == 'red' || status == 'expired'
        ? AppColors.freshRed
        : (status == 'orange' ? AppColors.freshRed : AppColors.freshGreen);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(flex: 1, child: Container(color: AppColors.freshGreen)),
                  Expanded(flex: 2, child: Container(color: AppColors.freshOrange)),
                  Expanded(flex: 1, child: Container(color: AppColors.freshRed)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('${daysLeft}j',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'RobotoMono',
                color: labelColor)),
      ],
    );
  }

  String _dtFreshText(String status) {
    switch (status) {
      case 'red':
      case 'expired':
        return 'Périmé';
      case 'orange':
        return 'Périme 2j';
      default:
        return 'OK — 4j';
    }
  }

  Color _dtFreshColor(String status) {
    switch (status) {
      case 'red':
      case 'expired':
        return AppColors.freshRed;
      case 'orange':
        return AppColors.error;
      default:
        return AppColors.freshGreen;
    }
  }

  List<Widget> _dtMovements(String unit) {
    const movements = [
      {'type': 'sale', 'label': 'Vente caisse', 'date': "Aujourd'hui 14:22 · Yempabou", 'qty': -2.0},
      {'type': 'sale', 'label': 'Vente caisse', 'date': "Aujourd'hui 11:08", 'qty': -3.0},
      {'type': 'reception', 'label': 'Réception', 'date': 'Hier 06:30 · Sankaryaré', 'qty': 15.0},
      {'type': 'loss', 'label': 'Frotte', 'date': 'Hier 18:00 · Blandine', 'qty': -0.4},
      {'type': 'sale', 'label': 'Vente caisse', 'date': 'Hier 16:45', 'qty': -4.0},
    ];
    return movements.map((m) {
      final type = m['type'] as String;
      final label = m['label'] as String;
      final date = m['date'] as String;
      final qty = m['qty'] as double;

      Color iconBg, iconFg;
      String iconText;
      if (type == 'reception') {
        iconBg = const Color(0xFFDCFCE7);
        iconFg = const Color(0xFF166534);
        iconText = '↑';
      } else if (type == 'loss') {
        iconBg = const Color(0xFFFEF3C7);
        iconFg = const Color(0xFF92400E);
        iconText = '≈';
      } else {
        iconBg = const Color(0xFFFEE2E2);
        iconFg = const Color(0xFF991B1B);
        iconText = '↓';
      }

      Color qtyColor;
      String qtyText;
      if (qty > 0) {
        qtyColor = AppColors.success;
        qtyText = '+${_dtFmtQty(qty)} $unit';
      } else if (type == 'loss') {
        qtyColor = AppColors.warning;
        qtyText = '−${_dtFmtQty(qty.abs())} $unit';
      } else {
        qtyColor = AppColors.error;
        qtyText = '−${_dtFmtQty(qty.abs())} $unit';
      }

      return Container(
        height: 56.8,
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 0.8,
                  strokeAlign: BorderSide.strokeAlignInside)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(iconText,
                  style: TextStyle(fontSize: 16, color: iconFg)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text(date,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B))),
                ],
              ),
            ),
            Text(qtyText,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'RobotoMono',
                    color: qtyColor)),
          ],
        ),
      );
    }).toList();
  }

  static String _dtFormatEan(String ean) {
    if (ean.length < 4) return ean;
    final buf = StringBuffer();
    for (var i = 0; i < ean.length; i++) {
      if (i > 0 && i % 3 == 0) buf.write(' ');
      buf.write(ean[i]);
    }
    return buf.toString();
  }

  static String _dtFmtQty(double qty) {
    if (qty == qty.toInt().toDouble()) return qty.toInt().toString();
    return qty.toStringAsFixed(1);
  }

  // ── Desktop sidebar — Figma 48:372 left ───────────────────────────────────

  Widget _buildDesktopSidebar(List<Map<String, dynamic>> all) {
    // Categories with Figma hardcoded counts
    const categories = [
      'Toutes',
      'Fruits',
      'Légumes',
      'Frais',
      'Céréales',
      'Épices',
      'Conserves',
      'Hygiène',
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        // CATÉGORIES section title
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Text('CATÉGORIES',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.4)),
        ),
        // Category rows
        ...categories.map((cat) {
          final isAll = cat == 'Toutes';
          final isActive = isAll
              ? _selectedCategory == null
              : _selectedCategory == cat;
          final count = _mockCategoryCountsFigma[cat] ?? 0;
          final emoji = isAll ? null : _categoryEmojis[cat];

          return _sidebarCategoryRow(
            emoji: emoji,
            label: cat,
            count: count,
            isActive: isActive,
            onTap: () => setState(
                () => _selectedCategory = isAll ? null : cat),
          );
        }),

        const SizedBox(height: 24),

        // FILTRES RAPIDES section title
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Text('FILTRES RAPIDES',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.4)),
        ),
        // Quick filter rows
        _sidebarQuickFilter(
          icon: '\u26A0',
          label: 'Rupture',
          count: _mockQuickFilterCounts['rupture'] ?? 0,
          color: const Color(0xFFC62828),
          isActive: _chipIndex == 1,
          onTap: () =>
              setState(() => _chipIndex = _chipIndex == 1 ? 0 : 1),
        ),
        _sidebarQuickFilter(
          icon: '\u26A0',
          label: 'Stock bas',
          count: _mockQuickFilterCounts['stock_bas'] ?? 0,
          color: const Color(0xFFF9A825),
          isActive: _chipIndex == 2,
          onTap: () =>
              setState(() => _chipIndex = _chipIndex == 2 ? 0 : 2),
        ),
        _sidebarQuickFilter(
          icon: '\uD83D\uDD34',
          label: 'Fraîcheur',
          count: _mockQuickFilterCounts['fraicheur'] ?? 0,
          color: const Color(0xFFDC2626),
          isActive: _chipIndex == 3,
          onTap: () =>
              setState(() => _chipIndex = _chipIndex == 3 ? 0 : 3),
        ),
      ],
    );
  }

  Widget _sidebarCategoryRow({
    String? emoji,
    required String label,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 33.2,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(emoji != null ? '$emoji $label' : label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? const Color(0xFF1565C0)
                          : const Color(0xFF0F172A))),
            ),
            Text('$count',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isActive
                        ? const Color(0xFF1565C0)
                        : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _sidebarQuickFilter({
    required String icon,
    required String label,
    required int count,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 33.2,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('$icon $label',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ),
            Text('$count',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  // ── Desktop table — Figma 48:372 right ────────────────────────────────────

  Widget _buildDesktopTable(List<Map<String, dynamic>> products) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 32, 24),
      child: Column(
        children: [
          // Search + sort
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38.8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Text('\uD83D\uDD0D',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF64748B))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _search = v),
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText:
                                'Rechercher un produit, code-barres, catégorie\u2026',
                            hintStyle: TextStyle(
                                fontSize: 13, color: Color(0xFF64748B)),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_search.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          },
                          child: const Icon(Icons.close,
                              size: 18, color: Color(0xFF64748B)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _desktopSmallAction('\u2195 Tri: Nom', null),
              const SizedBox(width: 8),
              _desktopSmallAction('\u25A6 Vue table', null),
            ],
          ),
          const SizedBox(height: 16),

          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      border: Border(
                          bottom: BorderSide(
                              color: Color(0xFFE2E8F0), width: 0.8)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 54), // emoji square space
                        Expanded(
                            flex: 3,
                            child: Text('PRODUIT',
                                style: _tableHeaderStyle)),
                        Expanded(
                            flex: 2,
                            child: Text('CATÉGORIE',
                                style: _tableHeaderStyle)),
                        Expanded(
                            flex: 2,
                            child: Text('PRIX DÉTAIL',
                                style: _tableHeaderStyle)),
                        Expanded(
                            flex: 2,
                            child: Text('PRIX GROS',
                                style: _tableHeaderStyle)),
                        Expanded(
                            flex: 2,
                            child: Text('STOCK',
                                style: _tableHeaderStyle)),
                        SizedBox(
                            width: 60,
                            child: Text('FRAÎCH.',
                                style: _tableHeaderStyle)),
                        Expanded(
                            flex: 2,
                            child: Text('VALEUR',
                                style: _tableHeaderStyle)),
                        Expanded(
                            flex: 2,
                            child: Text('ALERTES',
                                style: _tableHeaderStyle)),
                      ],
                    ),
                  ),
                  // Rows
                  Expanded(
                    child: products.isEmpty
                        ? const Center(
                            child: Text('Aucun produit ne correspond',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary)))
                        : ListView.builder(
                            itemCount: products.length,
                            itemBuilder: (_, i) =>
                                _buildTableRow(products[i], i),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> p, int index) {
    final name = p['name']?.toString() ?? '';
    final ean = p['ean']?.toString() ?? '';
    final cat = p['categoryName']?.toString() ?? '';
    final retailPrice = (p['retailPrice'] as num?)?.toDouble() ?? 0;
    final wholesalePrice = (p['wholesalePrice'] as num?)?.toDouble();
    final stock = (p['stockQuantity'] as num?)?.toDouble() ?? 0;
    final maxStock = (p['maxStockLevel'] as num?)?.toDouble() ?? 0;
    final minStock = (p['minStockLevel'] as num?)?.toDouble() ?? 0;
    final unit = p['unit']?.toString() ?? '';
    final emoji = p['emoji']?.toString() ?? '\uD83D\uDCE6';
    final emojiBg = Color(p['emojiBg'] as int? ?? 0xFFF1F5F9);
    final value = retailPrice * stock;
    final freshStatus = p['freshnessStatus']?.toString();

    // Stock color
    Color stockColor;
    if (stock <= 0) {
      stockColor = AppColors.error;
    } else if (minStock > 0 && stock < minStock) {
      stockColor = AppColors.warning;
    } else {
      stockColor = AppColors.success;
    }

    // Freshness dot color
    Color freshDot;
    switch (freshStatus) {
      case 'red':
      case 'expired':
        freshDot = AppColors.freshRed;
      case 'orange':
        freshDot = AppColors.freshOrange;
      default:
        freshDot = AppColors.freshGreen;
    }

    // Alert badge
    String? alertText;
    Color? alertBg;
    Color? alertColor;
    if (stock <= 0) {
      alertText = 'RUPTURE';
      alertBg = const Color(0xFFC62828);
      alertColor = Colors.white;
    } else if (minStock > 0 && stock < minStock) {
      alertText = 'STOCK BAS';
      alertBg = const Color(0xFFFEF3C7);
      alertColor = const Color(0xFF92400E);
    } else if (freshStatus == 'red' || freshStatus == 'expired') {
      alertText = 'FRAIS \uD83D\uDD34';
      alertBg = const Color(0xFFDC2626);
      alertColor = Colors.white;
    }

    return GestureDetector(
      onTap: () {
        final isDesktop = MediaQuery.sizeOf(context).width >= 900;
        if (isDesktop) {
          setState(() => _selectedProduct = p);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: p),
            ),
          );
        }
      },
      child: Container(
      height: 70.8,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
      ),
      child: Row(
        children: [
          // Emoji in colored bg square
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: emojiBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          // Name + EAN
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                if (ean.isNotEmpty)
                  Text('EAN $ean',
                      style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'RobotoMono',
                          color: Color(0xFF64748B))),
              ],
            ),
          ),
          // Category badge — all indigo per Figma
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(cat.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3730A3),
                        letterSpacing: 0.3)),
              ),
            ),
          ),
          // Retail price
          Expanded(
            flex: 2,
            child: Text('${_nf.format(retailPrice)} F/$unit',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'RobotoMono',
                    color: Color(0xFF0F172A))),
          ),
          // Wholesale price
          Expanded(
            flex: 2,
            child: wholesalePrice != null && wholesalePrice > 0
                ? Text('${_nf.format(wholesalePrice)} F/$unit',
                    style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'RobotoMono',
                        color: Color(0xFF0F172A)))
                : const Text('\u2013',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF9E9E9E))),
          ),
          // Stock
          Expanded(
            flex: 2,
            child: Text(
                '${stock.toInt()} / ${maxStock > 0 ? maxStock.toInt() : '\u2013'}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'RobotoMono',
                    color: stockColor)),
          ),
          // Freshness dot with border + shadow
          SizedBox(
            width: 60,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: freshDot,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: Colors.white, width: 1.6),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 3,
                        offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),
          ),
          // Value
          Expanded(
            flex: 2,
            child: Text('${_nf.format(value)} F',
                style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'RobotoMono',
                    color: Color(0xFF0F172A))),
          ),
          // Alert badge
          Expanded(
            flex: 2,
            child: alertText != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: alertBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(alertText,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: alertColor,
                              letterSpacing: 0.3)),
                    ),
                  )
                : const Text('\u2013',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF9E9E9E))),
          ),
        ],
      ),
    ),
    );
  }

  // ── Desktop empty ─────────────────────────────────────────────────────────

  Widget _buildDesktopEmpty() {
    return Center(
      child: Container(
        width: 480,
        margin: const EdgeInsets.symmetric(vertical: 64),
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Center(
                  child: Text('\uD83D\uDCE6',
                      style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 20),
            const Text('Aucun produit encore',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            const Text(
              'Créez votre premier produit pour démarrer votre catalogue. Vous pourrez ajouter photo, prix, stock, fraîcheur, vrac.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _showCreateProduct(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('+ Créer un produit',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Create product ────────────────────────────────────────────────────────

  void _showCreateProduct() {
    // TODO: navigate to product creation form
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Product Card — Figma 48:61
// ═══════════════════════════════════════════════════════════════════════════════

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.nf});
  final Map<String, dynamic> product;
  final NumberFormat nf;

  @override
  Widget build(BuildContext context) {
    final name = product['name']?.toString() ?? '';
    final cat = product['categoryName']?.toString() ?? '';
    final price = (product['retailPrice'] as num?)?.toDouble() ?? 0;
    final unit = product['unit']?.toString() ?? '';
    final stock = (product['stockQuantity'] as num?)?.toDouble() ?? 0;
    final maxStock = (product['maxStockLevel'] as num?)?.toDouble() ?? 0;
    final emoji = product['emoji']?.toString() ?? '\uD83D\uDCE6';
    final freshStatus = product['freshnessStatus']?.toString();

    final gradStart = Color(product['gradientStart'] as int? ?? 0xFFF1F5F9);
    final gradEnd = Color(product['gradientEnd'] as int? ?? 0xFFE2E8F0);

    // Stock color
    Color stockColor;
    if (stock <= 0) {
      stockColor = AppColors.error;
    } else if ((product['minStockLevel'] as num?)?.toDouble() != null &&
        (product['minStockLevel'] as num).toDouble() > 0 &&
        stock < (product['minStockLevel'] as num).toDouble()) {
      stockColor = AppColors.warning;
    } else {
      stockColor = AppColors.success;
    }

    // Freshness dot
    Color freshDot;
    switch (freshStatus) {
      case 'red':
      case 'expired':
        freshDot = AppColors.freshRed;
      case 'orange':
        freshDot = AppColors.freshOrange;
      default:
        freshDot = AppColors.freshGreen;
    }

    // Alert badge
    String? alertText;
    Color? alertBg;
    Color? alertTextColor;
    if (stock <= 0) {
      alertText = 'RUPTURE';
      alertBg = const Color(0xFFC62828);
      alertTextColor = Colors.white;
    } else if ((product['minStockLevel'] as num?)?.toDouble() != null &&
        (product['minStockLevel'] as num).toDouble() > 0 &&
        stock < (product['minStockLevel'] as num).toDouble()) {
      alertText = 'BAS';
      alertBg = const Color(0xFFFEF3C7);
      alertTextColor = const Color(0xFF92400E);
    } else if (freshStatus == 'red' || freshStatus == 'expired') {
      alertText = 'FRAIS \uD83D\uDD34';
      alertBg = const Color(0xFFDC2626);
      alertTextColor = Colors.white;
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Top — gradient + emoji + badges
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-0.7, -0.7),
                end: const Alignment(0.7, 0.7),
                colors: [gradStart, gradEnd],
              ),
            ),
            child: Stack(
              children: [
                Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 48))),
                // Freshness dot top-left
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: freshDot,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.white, width: 1.6),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 3,
                            offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ),
                // Alert badge top-right
                if (alertText != null)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: alertBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(alertText,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: alertTextColor,
                              letterSpacing: 0.3)),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom — info (Expanded to fill remaining card height)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name — 12px ExtraBold
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  // Category — 9px Bold uppercase
                  Text(cat.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.3)),
                  const Spacer(),
                  // Price + Stock row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Price — 13px Bold RobotoMono + unit 8px
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${nf.format(price)} F',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'RobotoMono',
                                  color: Color(0xFF0F172A),
                                  height: 1.2)),
                          Text('/$unit',
                              style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                  height: 1.2)),
                        ],
                      ),
                      Text(
                          '${stock.toInt()} / ${maxStock > 0 ? maxStock.toInt() : '\u2013'}',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'RobotoMono',
                              color: stockColor)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _ChipData {
  const _ChipData(this.label, this.count, this.isDefault);
  final String label;
  final int? count;
  final bool isDefault;
}

const _tableHeaderStyle = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w600,
  color: Color(0xFF64748B),
  letterSpacing: 0.5,
);
