import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/retail/backoffice/presentation/screens/dashboard_screen.dart'
    show activeBreadcrumbSubLabel;
import 'package:intl/intl.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Alertes stock — Figma 51:2 / 51:470
// Mobile  : KPI header + cards avec bande couleur
// Desktop : KPI row + tab filters + data table
// ══════════════════════════════════════════════════════════════════════════════

// ── Alert type enum ──────────────────────────────────────────────────────────

enum AlertType { perime, rupture, fraicheur, stockBas }

// ── Mock data — matches Figma 51:470 ─────────────────────────────────────────

class _AlertData {
  final String name;
  final String emoji;
  final String category;
  final int emojiBg;
  final AlertType type;
  final String detailMobile;
  final String detailDesktop;
  final int valeur;
  final String suggestion;
  final String actionEmoji;
  final String actionLabel;
  final int actionColor;
  // Mobile card
  final int borderColor;
  final String? extraInfo;

  const _AlertData({
    required this.name,
    required this.emoji,
    required this.category,
    required this.emojiBg,
    required this.type,
    required this.detailMobile,
    required this.detailDesktop,
    required this.valeur,
    required this.suggestion,
    required this.actionEmoji,
    required this.actionLabel,
    required this.actionColor,
    required this.borderColor,
    this.extraInfo,
  });
}

const _kRed = 0xFFDC2626;
const _kAmber = 0xFFF59E0B;
const _kBlue = 0xFF1565C0;
const _kDark = 0xFF0F172A;

final _mockAlerts = <_AlertData>[
  _AlertData(
    name: 'Lait laiterie 1L',
    emoji: '🥛',
    category: 'FRAIS · LAITERIE',
    emojiBg: 0xFFDBEAFE,
    type: AlertType.perime,
    detailMobile: '4 u · DLC 05/04 · objectif stock 12 · valeur 3 200 F',
    detailDesktop: '4 u · DLC 05/04',
    valeur: 3200,
    suggestion: 'Retirer du rayon',
    actionEmoji: '🗑',
    actionLabel: 'Retirer',
    actionColor: _kRed,
    borderColor: _kRed,
    extraInfo: 'Manque à gagner réel : 14 060 F',
  ),
  _AlertData(
    name: 'Banane sucrée locale',
    emoji: '🍌',
    category: 'FRUITS',
    emojiBg: 0xFFFEF3C7,
    type: AlertType.rupture,
    detailMobile: 'Stock 0 / 25 kg · rupture depuis 14h',
    detailDesktop: '0 / 20 kg · hier',
    valeur: -14000,
    suggestion: 'Réappro 25 kg',
    actionEmoji: '🔄',
    actionLabel: 'Réappro',
    actionColor: _kAmber,
    borderColor: _kRed,
  ),
  _AlertData(
    name: 'Poisson capitaine frais',
    emoji: '🐟',
    category: 'FRAIS · POISSONNERIE',
    emojiBg: 0xFFCFFAFE,
    type: AlertType.fraicheur,
    detailMobile: 'DLC périmée depuis 1 jour · stock résiduel 6 480 F',
    detailDesktop: '3 kg · périme 1j',
    valeur: 9000,
    suggestion: 'Promo -30%',
    actionEmoji: '🔥',
    actionLabel: 'Promo',
    actionColor: _kDark,
    borderColor: _kRed,
  ),
  _AlertData(
    name: 'Tomate fraîche locale',
    emoji: '🍅',
    category: 'LÉGUMES · FRAIS',
    emojiBg: 0xFFFEE2E2,
    type: AlertType.stockBas,
    detailMobile: 'Stock 8 / 15 kg · seuil remonté automatiquement +21',
    detailDesktop: '8 / 15 kg · 2j',
    valeur: 4800,
    suggestion: 'Réappro 15 kg',
    actionEmoji: '🔄',
    actionLabel: 'Réappro',
    actionColor: _kAmber,
    borderColor: _kAmber,
  ),
  _AlertData(
    name: 'Viande de bœuf 1er choix',
    emoji: '🥩',
    category: 'BOUCHERIE',
    emojiBg: 0xFFFEE2E2,
    type: AlertType.rupture,
    detailMobile: 'Frais expire dans 3 jours',
    detailDesktop: '0 kg · 2 jours',
    valeur: -22000,
    suggestion: 'Commander urgent',
    actionEmoji: '📦',
    actionLabel: 'Commander',
    actionColor: _kBlue,
    borderColor: _kAmber,
  ),
  _AlertData(
    name: 'Yaourt nature 500g',
    emoji: '🥛',
    category: 'FRAIS · LAITERIE',
    emojiBg: 0xFFFEF3C7,
    type: AlertType.fraicheur,
    detailMobile: '8 unités · périme dans 2 jours',
    detailDesktop: '8 u · périme 2j',
    valeur: 5600,
    suggestion: 'Promo -20%',
    actionEmoji: '🔥',
    actionLabel: 'Promo',
    actionColor: _kDark,
    borderColor: _kAmber,
  ),
  _AlertData(
    name: 'Mangue Kent',
    emoji: '🥭',
    category: 'FRUITS · FRAIS',
    emojiBg: 0xFFFED7AA,
    type: AlertType.stockBas,
    detailMobile: 'Stock 4 / 18 kg · seuil automatique +5kg',
    detailDesktop: '4 / 10 kg · 3j',
    valeur: 3200,
    suggestion: 'Réappro 10 kg',
    actionEmoji: '🔄',
    actionLabel: 'Réappro',
    actionColor: _kAmber,
    borderColor: _kAmber,
  ),
  _AlertData(
    name: 'Salade laitue',
    emoji: '🥬',
    category: 'LÉGUMES · FRAIS',
    emojiBg: 0xFFDCFCE7,
    type: AlertType.stockBas,
    detailMobile: 'Stock 8 / 10 unités · seuil atteint',
    detailDesktop: '8 / 10 u · 1j',
    valeur: 2400,
    suggestion: 'Réappro',
    actionEmoji: '🔄',
    actionLabel: 'Réappro',
    actionColor: _kAmber,
    borderColor: _kAmber,
  ),
];

// ── Screen ───────────────────────────────────────────────────────────────────

class StockAlertsScreen extends ConsumerStatefulWidget {
  const StockAlertsScreen({super.key});

  @override
  ConsumerState<StockAlertsScreen> createState() => _StockAlertsScreenState();
}

class _StockAlertsScreenState extends ConsumerState<StockAlertsScreen> {
  int _chipIndex = 0;
  final _nf = NumberFormat('#,###', 'fr_FR');

  int _countType(AlertType t) =>
      _mockAlerts.where((a) => a.type == t).length;

  List<_AlertData> get _filtered {
    switch (_chipIndex) {
      case 1:
        return _mockAlerts.where((a) => a.type == AlertType.rupture).toList();
      case 2:
        return _mockAlerts.where((a) => a.type == AlertType.stockBas).toList();
      case 3:
        return _mockAlerts
            .where((a) => a.type == AlertType.fraicheur)
            .toList();
      case 4:
        return _mockAlerts.where((a) => a.type == AlertType.perime).toList();
      default:
        return _mockAlerts.toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    if (isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(activeBreadcrumbSubLabel.notifier).state = 'Alertes';
        }
      });
    }

    return isDesktop ? _buildDesktop() : _buildMobile();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MOBILE — Figma 51:3
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMobile() {
    final alerts = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: ScalarioAppBar(
        titleWidget: Column(
          children: [
            const Text('Alertes stock',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            Text(
              _chipIndex == 0
                  ? 'Boutique Frais Ouaga · ${_mockAlerts.length} actives'
                  : 'Filtre : ${['Toutes', 'Rupture', 'Stock bas', 'Fraîcheur', 'Périmés'][_chipIndex]}',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.file_download_outlined,
                color: Colors.white, size: 22),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMobileKpiHeader(),
          _buildMobileChips(),
          Expanded(
            child: alerts.isEmpty
                ? _buildMobileEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: alerts.length,
                    itemBuilder: (_, i) => _buildMobileCard(alerts[i]),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Gradient banner — Figma 51:22 (red) / 51:424 (green when 0) ──
  Widget _buildMobileKpiHeader() {
    final total = _mockAlerts.length;
    final isEmpty = total == 0;

    return Column(
      children: [
        // ── Gradient banner ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-0.8, -0.6),
              end: Alignment.bottomRight,
              colors: isEmpty
                  ? [const Color(0xFFDCFCE7), const Color(0xFF86EFAC)]
                  : [const Color(0xFFFEE2E2), const Color(0xFFFECACA)],
            ),
            border: const Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
            ),
          ),
          child: Column(
            children: [
              Text(
                '$total',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: isEmpty
                      ? const Color(0xFF166534)
                      : const Color(0xFF991B1B),
                  fontFamily: 'RobotoMono',
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isEmpty ? 'AUCUNE ALERTE' : 'ALERTES ACTIVES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isEmpty
                      ? const Color(0xFF14532D)
                      : const Color(0xFF7F1D1D),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),

        // ── Mini KPI row — 4 columns with vertical dividers ──
        Container(
          height: 64,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
            ),
          ),
          child: Row(
            children: [
              _miniKpiCell(
                '${_countType(AlertType.rupture)}',
                'RUPTURE',
                isEmpty ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                showRightBorder: true,
              ),
              _miniKpiCell(
                '${_countType(AlertType.stockBas)}',
                'STOCK BAS',
                isEmpty ? const Color(0xFF2E7D32) : const Color(0xFFF9A825),
                showRightBorder: true,
              ),
              _miniKpiCell(
                '${_countType(AlertType.fraicheur)}',
                'FRAÎCHEUR',
                isEmpty ? const Color(0xFF2E7D32) : const Color(0xFFDC2626),
                showRightBorder: true,
              ),
              _miniKpiCell(
                '${_countType(AlertType.perime)}',
                isEmpty ? 'PÉRIMÉS' : 'PÉRIMÉ',
                isEmpty ? const Color(0xFF2E7D32) : const Color(0xFF7F1D1D),
                showRightBorder: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniKpiCell(
    String value,
    String label,
    Color valueColor, {
    required bool showRightBorder,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: showRightBorder
              ? const Border(
                  right: BorderSide(color: Color(0xFFE2E8F0), width: 0.8))
              : null,
        ),
        padding: const EdgeInsets.only(top: 13),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                    fontFamily: 'RobotoMono')),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }

  // ── Underline tab filters — Figma 51:58 ──
  Widget _buildMobileChips() {
    final tabs = [
      ('Toutes', _mockAlerts.length),
      ('Rupture', _countType(AlertType.rupture)),
      ('Stock bas', _countType(AlertType.stockBas)),
      ('Fraîcheur', _countType(AlertType.fraicheur)),
      ('Périmés', _countType(AlertType.perime)),
    ];

    return Container(
      height: 61,
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 4),
        itemCount: tabs.length,
        itemBuilder: (_, i) {
          final (label, count) = tabs[i];
          final isActive = _chipIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _chipIndex = i),
            child: Container(
              padding: const EdgeInsets.only(left: 14, right: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive
                        ? const Color(0xFF1565C0)
                        : Colors.transparent,
                    width: 2.4,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      '$label ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? const Color(0xFF1565C0)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFDBEAFE)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isActive
                              ? const Color(0xFF1E40AF)
                              : const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileCard(_AlertData alert) {
    final borderColor = Color(alert.borderColor);
    final badge = _typeBadge(alert.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: borderColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _emojiCircle(alert.emoji, Color(alert.emojiBg), 36),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(alert.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 3),
                              Text(alert.detailMobile,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                      height: 1.3),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        badge,
                      ],
                    ),
                    if (alert.extraInfo != null) ...[
                      const SizedBox(height: 6),
                      Text(alert.extraInfo!,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w500)),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: const Text('Fiche',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B))),
                        ),
                        const Spacer(),
                        _actionButton(
                          alert.actionEmoji,
                          alert.actionLabel,
                          Color(alert.actionColor),
                        ),
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

  Widget _buildMobileEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Center(
                child: Icon(Icons.check, size: 40, color: Color(0xFF16A34A))),
          ),
          const SizedBox(height: 4),
          const Text('0',
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'RobotoMono',
                  color: Color(0xFF16A34A))),
          const Text('AUCUNE ALERTE',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 1)),
          const SizedBox(height: 24),
          const Text('Tout est OK',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          const Text(
            'Aucune alerte active. Tous tes produits sont au-\ndessus du seuil et frais. Continue comme ça !',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DESKTOP — Figma 51:470
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktop() {
    final alerts = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title bar ──
        Container(
          height: 102.8,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alertes stock',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            height: 1.1)),
                    const SizedBox(height: 6),
                    Text(
                      '${_mockAlerts.length} alertes actives · valeur immobilisée 12 200 F · dernière mise à jour il y a 3 min',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _dtOutlinedBtn('↓ Exporter'),
              const SizedBox(width: 10),
              _dtOutlinedBtn('🔔 Configurer seuils'),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {},
                child: Container(
                  height: 40.8,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🔄 Tout réapprovisionner',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── KPI cards row — Figma 51:533 ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              _desktopKpiCard(
                value: '${_mockAlerts.length}',
                label: 'TOTAL ALERTES',
                accentColor: const Color(0xFF0F172A),
              ),
              const SizedBox(width: 12),
              _desktopKpiCard(
                value: '${_countType(AlertType.rupture)}',
                label: 'RUPTURE',
                accentColor: const Color(0xFFDC2626),
              ),
              const SizedBox(width: 12),
              _desktopKpiCard(
                value: '${_countType(AlertType.stockBas)}',
                label: 'STOCK BAS',
                accentColor: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 12),
              _desktopKpiCard(
                value: '${_countType(AlertType.fraicheur)}',
                label: 'FRAÎCHEUR 🔴',
                accentColor: const Color(0xFFEA580C),
              ),
              const SizedBox(width: 12),
              _desktopKpiCard(
                value: '${_countType(AlertType.perime)}',
                label: 'PÉRIMÉ',
                accentColor: const Color(0xFFDC2626),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Tab-style filter chips — Figma 51:470 ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _buildDesktopTabs(),
        ),
        const SizedBox(height: 16),

        // ── Data table ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  _tableHeader(),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  Expanded(
                    child: ListView.separated(
                      itemCount: alerts.length,
                      separatorBuilder: (_, _) => const Divider(
                          height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (_, i) => _tableRow(alerts[i]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Desktop KPI card — Figma 51:533 ──
  // White bg, thick left border in accent color, number in accent color
  Widget _desktopKpiCard({
    required String value,
    required String label,
    required Color accentColor,
  }) {
    return Expanded(
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          children: [
            // Thick left accent border
            Container(width: 4, color: accentColor),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(value,
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                            fontFamily: 'RobotoMono',
                            height: 1)),
                    Text(label,
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Desktop tab-style filters ──
  Widget _buildDesktopTabs() {
    final tabs = [
      ('Toutes', _mockAlerts.length),
      ('Rupture', _countType(AlertType.rupture)),
      ('Stock bas', _countType(AlertType.stockBas)),
      ('Fraîcheur', _countType(AlertType.fraicheur)),
      ('Périmés', _countType(AlertType.perime)),
    ];

    return Row(
      children: tabs.asMap().entries.map((e) {
        final i = e.key;
        final (label, count) = e.value;
        final isActive = _chipIndex == i;
        return Padding(
          padding: const EdgeInsets.only(right: 24),
          child: GestureDetector(
            onTap: () => setState(() => _chipIndex = i),
            child: Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF94A3B8))),
                  const SizedBox(width: 6),
                  if (i == 0 && isActive)
                    // Blue pill badge for "Toutes" when active
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$count',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    )
                  else
                    Text('$count',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? const Color(0xFF475569)
                                : const Color(0xFFCBD5E1))),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Table header ──
  Widget _tableHeader() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: const Color(0xFFFAFAFA),
      child: const Row(
        children: [
          Expanded(flex: 5, child: _ColLabel('PRODUIT')),
          Expanded(flex: 2, child: _ColLabel('TYPE')),
          Expanded(flex: 3, child: _ColLabel('DÉTAIL')),
          Expanded(flex: 2, child: _ColLabel('VALEUR')),
          Expanded(flex: 3, child: _ColLabel('SUGGESTION')),
          Expanded(flex: 3, child: _ColLabel('ACTIONS')),
        ],
      ),
    );
  }

  // ── Table row — Figma 51:470 ──
  Widget _tableRow(_AlertData alert) {
    final valeur = alert.valeur;
    final badge = _typeBadge(alert.type);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // PRODUIT — emoji circle + name + category
          Expanded(
            flex: 5,
            child: Row(
              children: [
                _emojiCircle(alert.emoji, Color(alert.emojiBg), 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert.name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(alert.category,
                          style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.3),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // TYPE badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: badge,
            ),
          ),
          // DÉTAIL
          Expanded(
            flex: 3,
            child: Text(alert.detailDesktop,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF475569)),
                overflow: TextOverflow.ellipsis),
          ),
          // VALEUR
          Expanded(
            flex: 2,
            child: Text(
              '${valeur < 0 ? "-" : ""}${_nf.format(valeur.abs())} F',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'RobotoMono',
                color: valeur < 0
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF0F172A),
              ),
            ),
          ),
          // SUGGESTION
          Expanded(
            flex: 3,
            child: Text(alert.suggestion,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF64748B))),
          ),
          // ACTIONS
          Expanded(
            flex: 3,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: const Text('Fiche',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8))),
                ),
                const SizedBox(width: 12),
                _actionButton(
                  alert.actionEmoji,
                  alert.actionLabel,
                  Color(alert.actionColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  /// Emoji in a colored circle — used in both mobile cards and desktop table
  Widget _emojiCircle(String emoji, Color bg, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
      ),
    );
  }

  /// Type badge — colored pill matching Figma
  Widget _typeBadge(AlertType type) {
    switch (type) {
      case AlertType.perime:
        return _badge('PÉRIMÉ', const Color(0xFFDC2626), Colors.white);
      case AlertType.rupture:
        return _badge('RUPTURE', const Color(0xFFDC2626), Colors.white);
      case AlertType.fraicheur:
        return _badge(
            'FRAÎCHEUR 🔴', const Color(0xFFEA580C), Colors.white);
      case AlertType.stockBas:
        return _badge(
            'Stock bas', const Color(0xFFFEF3C7), const Color(0xFFB45309));
    }
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.2)),
    );
  }

  /// Action button with emoji — matches Figma colors per type
  Widget _actionButton(String emoji, String label, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _dtOutlinedBtn(String label) {
    return GestureDetector(
      onTap: () {},
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
}

// ── Column header label ──────────────────────────────────────────────────────

class _ColLabel extends StatelessWidget {
  final String text;
  const _ColLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.5));
  }
}
