import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/inventory/presentation/screens/stock_movements_screen.dart';
import 'package:intl/intl.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Fiche Produit — Figma 47:2
// Mobile: scrollable card sections + bottom action bar
// ══════════════════════════════════════════════════════════════════════════════

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScalarioAppBar(
        title: product['name']?.toString() ?? 'Produit',
        actions: [
          IconButton(
            icon: const Text('⋮',
                style: TextStyle(fontSize: 22, color: Colors.white)),
            onPressed: () {},
          ),
        ],
      ),
      body: ProductDetailBody(product: product),
    );
  }
}

class ProductDetailBody extends StatelessWidget {
  const ProductDetailBody({super.key, required this.product});
  final Map<String, dynamic> product;

  static final _nf = NumberFormat('#,###', 'fr_FR');

  @override
  Widget build(BuildContext context) {
    final name = product['name']?.toString() ?? '';
    final cat = product['categoryName']?.toString() ?? '';
    final emoji = product['emoji']?.toString() ?? '📦';
    final unit = product['unit']?.toString() ?? '';
    final retailPrice = (product['retailPrice'] as num?)?.toDouble() ?? 0;
    final wholesalePrice = (product['wholesalePrice'] as num?)?.toDouble();
    final purchasePrice = wholesalePrice ?? (retailPrice * 0.75);
    final stock = (product['stockQuantity'] as num?)?.toDouble() ?? 0;
    final minStock =
        (product['minStockLevel'] as num?)?.toDouble() ?? 0;
    final ean = product['ean']?.toString() ?? '';
    final freshStatus = product['freshnessStatus']?.toString() ?? 'green';

    final gradStart = Color(product['gradientStart'] as int? ?? 0xFFF1F5F9);
    final gradEnd = Color(product['gradientEnd'] as int? ?? 0xFFE2E8F0);

    // Compute mock values from Figma
    final stockValue = (stock * retailPrice).toInt();
    final soldMonth = (stock * 5.25).toInt(); // mock
    final margin = '+33%'; // Figma value
    final alertThreshold = minStock > 0 ? minStock.toInt() : 15;
    final autonomy = stock > 0
        ? '~${(stock / 1.4).toInt()} jours'
        : '0 jours';

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

    // Alert badges
    final badges = <Widget>[];
    if (stock <= 0) {
      badges.add(_alertBadge('RUPTURE', const Color(0xFFC62828), Colors.white));
    } else if (minStock > 0 && stock < minStock) {
      badges.add(_alertBadge(
          '⚠ Stock bas', const Color(0xFFFEF3C7), const Color(0xFF92400E)));
    }
    if (freshStatus == 'orange') {
      badges.add(_alertBadge(
          '🔸 Fraîcheur orange', const Color(0xFFFECACA), const Color(0xFF991B1B)));
    } else if (freshStatus == 'red' || freshStatus == 'expired') {
      badges.add(_alertBadge(
          '🔴 Périmé · à retirer', const Color(0xFFC62828), Colors.white));
    }

    // Stock KPI color
    Color stockKpiColor;
    if (stock <= 0) {
      stockKpiColor = AppColors.error;
    } else if (minStock > 0 && stock < minStock) {
      stockKpiColor = AppColors.warning;
    } else {
      stockKpiColor = const Color(0xFF0F172A);
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ── Hero image section ──
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // Gradient + emoji + freshness dot
                    Container(
                      height: 200,
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
                                  style: const TextStyle(fontSize: 96))),
                          // Freshness dot top-right
                          Positioned(
                            right: 14,
                            top: 14,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: freshDot,
                                borderRadius: BorderRadius.circular(9),
                                border:
                                    Border.all(color: Colors.white, width: 2.4),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x40000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 2)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Product info
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category
                          Text('$cat · Frais'.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          // Product name
                          Text('$name locale',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  height: 1.15)),
                          const SizedBox(height: 8),
                          // EAN
                          Text('EAN ${_formatEan(ean)}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'RobotoMono',
                                  color: Color(0xFF64748B))),
                          if (badges.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(spacing: 6, children: badges),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const _SectionDivider(),

              // ── KPI row — Figma 47:40 ──
              Container(
                color: Colors.white,
                height: 62,
                child: Row(
                  children: [
                    _kpiCell(
                      '${stock.toInt()} $unit',
                      'Stock',
                      stockKpiColor,
                      hasBorder: true,
                    ),
                    _kpiCell(
                      '${_nf.format(stockValue)} F',
                      'Valeur',
                      const Color(0xFF0F172A),
                      hasBorder: true,
                    ),
                    _kpiCell(
                      '$soldMonth $unit',
                      'Vendus 30j',
                      const Color(0xFF0F172A),
                      hasBorder: true,
                    ),
                    _kpiCell(
                      margin,
                      'Marge',
                      AppColors.success,
                      hasBorder: false,
                    ),
                  ],
                ),
              ),

              const _SectionDivider(),

              // ── Prix — Figma 47:69 ──
              _section(
                icon: '💰',
                title: 'Prix',
                children: [
                  _infoRow("Prix d'achat",
                      '${_nf.format(purchasePrice.toInt())} F / $unit'),
                  _infoRow('Prix détail',
                      '${_nf.format(retailPrice.toInt())} F / $unit'),
                  if (wholesalePrice != null)
                    _infoRow('Prix gros (≥ 5 $unit)',
                        '${_nf.format(wholesalePrice.toInt())} F / $unit'),
                  _infoRowWidget('Marge moyenne', _marginBadge(margin)),
                ],
              ),

              const _SectionDivider(),

              // ── Stock & seuils — Figma 47:104 ──
              _section(
                icon: '📦',
                title: 'Stock & seuils',
                children: [
                  _infoRowColored('Quantité actuelle',
                      '${stock.toInt()} $unit', stockKpiColor),
                  _infoRow('Seuil alerte', '$alertThreshold $unit'),
                  _infoRow('Unité de vente', unit),
                  _infoRowColored('Autonomie estimée', autonomy,
                      stockKpiColor),
                ],
              ),

              const _SectionDivider(),

              // ── Fraîcheur — Figma 47:139 ──
              _section(
                icon: '🌡️',
                title: 'Fraîcheur',
                children: [
                  _infoRow('Durée de vie', '5 jours'),
                  _infoRowColored('Lot le plus ancien', _freshLotText(freshStatus),
                      _freshLotColor(freshStatus)),
                  const SizedBox(height: 8),
                  _freshnessBar(freshStatus),
                ],
              ),

              const _SectionDivider(),

              // ── Frotte (pertes) — Figma 47:168 ──
              _section(
                icon: '📉',
                title: 'Frotte (taux casse/perte)',
                children: [
                  _infoRow('Taux activé', '3.5%'),
                  _infoRow('Frotte cumulée mois', '1.2 $unit'),
                ],
              ),

              const _SectionDivider(),

              // ── Derniers mouvements — Figma 47:189 ──
              _movementsSection(unit),

              // Bottom padding for action bar
              const SizedBox(height: 16),
            ],
          ),
        ),

        // ── Bottom action bar — Figma 47:261 ──
        _bottomActionBar(context),
      ],
    );
  }

  // ── Section builder ──

  Widget _section({
    required String icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(title.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.6)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // ── Info rows ──

  Widget _infoRow(String label, String value) {
    return _infoRowColored(label, value, const Color(0xFF0F172A));
  }

  Widget _infoRowColored(String label, String value, Color valueColor) {
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
                  color: valueColor)),
        ],
      ),
    );
  }

  Widget _infoRowWidget(String label, Widget trailing) {
    return Container(
      height: 34.8,
      alignment: Alignment.centerLeft,
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

  // ── KPI cell ──

  Widget _kpiCell(String value, String label, Color valueColor,
      {required bool hasBorder}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.only(top: 14),
        decoration: BoxDecoration(
          border: hasBorder
              ? const Border(
                  right: BorderSide(color: Color(0xFFE2E8F0), width: 0.8))
              : null,
        ),
        child: Column(
          children: [
            Text(value,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'RobotoMono',
                    color: valueColor)),
            const SizedBox(height: 3),
            Text(label.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }

  // ── Alert badge ──

  Widget _alertBadge(String text, Color bg, Color fg) {
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

  // ── Margin badge ──

  Widget _marginBadge(String value) {
    return Container(
      height: 18.8,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(value,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF166534))),
    );
  }

  // ── Freshness bar — Figma 47:160 ──

  Widget _freshnessBar(String status) {
    final daysLeft = status == 'red' ? 1 : (status == 'orange' ? 2 : 4);
    final label = '${daysLeft}j';
    final labelColor =
        status == 'red' || status == 'expired'
            ? AppColors.freshRed
            : (status == 'orange' ? AppColors.freshOrange : AppColors.freshGreen);

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                      flex: 1,
                      child: Container(color: AppColors.freshGreen)),
                  Expanded(
                      flex: 2,
                      child: Container(color: AppColors.freshOrange)),
                  Expanded(
                      flex: 1,
                      child: Container(color: AppColors.freshRed)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'RobotoMono',
                color: labelColor)),
      ],
    );
  }

  String _freshLotText(String status) {
    switch (status) {
      case 'red':
      case 'expired':
        return 'Périmé · retirer';
      case 'orange':
        return 'Périme dans 2j';
      default:
        return 'OK — 4j restants';
    }
  }

  Color _freshLotColor(String status) {
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

  // ── Movements section — Figma 47:189 ──

  Widget _movementsSection(String unit) {
    const movements = [
      {
        'type': 'sale',
        'label': 'Vente caisse',
        'date': "Aujourd'hui 14:22 · Yempabou",
        'qty': -2,
      },
      {
        'type': 'sale',
        'label': 'Vente caisse',
        'date': "Aujourd'hui 11:08 · Yempabou",
        'qty': -3,
      },
      {
        'type': 'reception',
        'label': 'Réception fournisseur',
        'date': 'Hier 06:30 · Marché Sankaryaré',
        'qty': 15,
      },
      {
        'type': 'loss',
        'label': 'Frotte / casse',
        'date': 'Hier 18:00 · Blandine',
        'qty': -0.4,
      },
      {
        'type': 'sale',
        'label': 'Vente caisse',
        'date': 'Hier 16:45 · Yempabou',
        'qty': -4,
      },
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with "Voir tout" link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Derniers mouvements'.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.6)),
              Text('Voir tout →'.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.6)),
            ],
          ),
          const SizedBox(height: 12),
          ...movements.map((m) => _movementRow(m, unit)),
        ],
      ),
    );
  }

  Widget _movementRow(Map<String, dynamic> m, String unit) {
    final type = m['type'] as String;
    final label = m['label'] as String;
    final date = m['date'] as String;
    final qty = (m['qty'] as num).toDouble();

    // Icon circle
    Color iconBg;
    Color iconFg;
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

    // Quantity color
    Color qtyColor;
    String qtyText;
    if (qty > 0) {
      qtyColor = AppColors.success;
      qtyText = '+${_formatQty(qty)} $unit';
    } else if (type == 'loss') {
      qtyColor = AppColors.warning;
      qtyText = '−${_formatQty(qty.abs())} $unit';
    } else {
      qtyColor = AppColors.error;
      qtyText = '−${_formatQty(qty.abs())} $unit';
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
          // Icon circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(iconText,
                style: TextStyle(
                    fontSize: 16, color: iconFg)),
          ),
          const SizedBox(width: 12),
          // Label + date
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
          // Quantity
          Text(qtyText,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'RobotoMono',
                  color: qtyColor)),
        ],
      ),
    );
  }

  // ── Bottom action bar — Figma 47:261 ──

  Widget _bottomActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12.8, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
        boxShadow: [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _actionButton('📊 Mouvements', const Color(0xFFF1F5F9),
                const Color(0xFF0F172A), onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StockMovementsScreen(
                    productName: product['name']?.toString(),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            _actionButton('🖨 Imprimer', const Color(0xFFF1F5F9),
                const Color(0xFF0F172A)),
            const SizedBox(width: 8),
            _actionButton(
                '✎ Éditer', AppColors.primary, Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color bg, Color fg, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap ?? () {},
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: fg)),
        ),
      ),
    );
  }

  // ── Helpers ──

  static String _formatEan(String ean) {
    if (ean.length < 4) return ean;
    final buf = StringBuffer();
    for (var i = 0; i < ean.length; i++) {
      if (i > 0 && i % 3 == 0) buf.write(' ');
      buf.write(ean[i]);
    }
    return buf.toString();
  }

  static String _formatQty(double qty) {
    if (qty == qty.toInt().toDouble()) return qty.toInt().toString();
    return qty.toStringAsFixed(1);
  }
}

// ── Section divider ──

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      color: const Color(0xFFF1F5F9),
    );
  }
}
