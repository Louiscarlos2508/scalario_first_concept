import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/retail/backoffice/presentation/screens/dashboard_screen.dart'
    show activeBreadcrumbSubLabel;
import 'package:intl/intl.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Mouvements stock — Figma 52:2
// Mobile  : period tabs + chips + KPI row + grouped cards
// Desktop : KPI cards + grouped data table
// ══════════════════════════════════════════════════════════════════════════════

// ── Movement types ───────────────────────────────────────────────────────────

enum MvtType { entree, vente, frotte, inventaire }

extension MvtTypeExt on MvtType {
  String get label {
    switch (this) {
      case MvtType.entree:
        return 'Entrée';
      case MvtType.vente:
        return 'Vente';
      case MvtType.frotte:
        return 'Frotte';
      case MvtType.inventaire:
        return 'Inventaire';
    }
  }

  String get icon {
    switch (this) {
      case MvtType.entree:
        return '↑';
      case MvtType.vente:
        return '↓';
      case MvtType.frotte:
        return '⚠';
      case MvtType.inventaire:
        return '↻';
    }
  }

  Color get color {
    switch (this) {
      case MvtType.entree:
        return const Color(0xFF16A34A);
      case MvtType.vente:
        return const Color(0xFFDC2626);
      case MvtType.frotte:
        return const Color(0xFFF59E0B);
      case MvtType.inventaire:
        return const Color(0xFF1565C0);
    }
  }

  Color get bgColor {
    switch (this) {
      case MvtType.entree:
        return const Color(0xFFDCFCE7);
      case MvtType.vente:
        return const Color(0xFFFEE2E2);
      case MvtType.frotte:
        return const Color(0xFFFEF3C7);
      case MvtType.inventaire:
        return const Color(0xFFDBEAFE);
    }
  }
}

// ── Mock data ────────────────────────────────────────────────────────────────

class _Movement {
  final String time;
  final MvtType type;
  final String product;
  final String source;
  final String? sourceLink;
  final String author;
  final double qty; // positive = in, negative = out
  final int valeur;
  final String dateGroup; // "AUJOURD'HUI · 7 AVR", "HIER · 6 AVR", etc.

  const _Movement({
    required this.time,
    required this.type,
    required this.product,
    required this.source,
    this.sourceLink,
    required this.author,
    required this.qty,
    required this.valeur,
    required this.dateGroup,
  });
}

const _kToday = "AUJOURD'HUI · 7 AVR";
const _kHier = 'HIER · 6 AVR';
const _k5avr = '5 AVR';
const _k2avr = '2 AVR';

final _mockMovements = <_Movement>[
  // Today
  _Movement(
    time: '14:22',
    type: MvtType.vente,
    product: 'Tomate fraîche locale',
    source: 'Vente INTE-3418',
    sourceLink: '→',
    author: 'Fermgoshe',
    qty: -2,
    valeur: 1200,
    dateGroup: _kToday,
  ),
  _Movement(
    time: '11:08',
    type: MvtType.vente,
    product: 'Tomate fraîche locale',
    source: 'Vente INTE-3455',
    sourceLink: '→',
    author: 'Fermgoshe',
    qty: -3,
    valeur: 1800,
    dateGroup: _kToday,
  ),
  // Yesterday
  _Movement(
    time: '08:30',
    type: MvtType.entree,
    product: 'Tomate fraîche locale',
    source: 'Réception · Marché Sankaryaré',
    sourceLink: '→',
    author: 'Blandine',
    qty: 15,
    valeur: 9750,
    dateGroup: _kHier,
  ),
  _Movement(
    time: '16:45',
    type: MvtType.vente,
    product: 'Tomate fraîche locale',
    source: 'Vente INTE-3391',
    sourceLink: '→',
    author: '',
    qty: -4,
    valeur: 2400,
    dateGroup: _kHier,
  ),
  _Movement(
    time: '18:00',
    type: MvtType.frotte,
    product: 'Tomate fraîche locale',
    source: 'Frotte auto · saison',
    sourceLink: '→',
    author: 'Périodique',
    qty: -0.4,
    valeur: 180,
    dateGroup: _kHier,
  ),
  // 5 AVR
  _Movement(
    time: '19:30',
    type: MvtType.inventaire,
    product: 'Tomate fraîche locale',
    source: 'Inventaire 00004 · écart',
    sourceLink: '→',
    author: 'Périodique',
    qty: -1.5,
    valeur: 900,
    dateGroup: _k5avr,
  ),
  // 2 AVR
  _Movement(
    time: '07:00',
    type: MvtType.entree,
    product: 'Tomate fraîche locale',
    source: 'Réception · Marché Sankaryaré',
    sourceLink: '→',
    author: 'Blandine',
    qty: 30,
    valeur: 13500,
    dateGroup: _k2avr,
  ),
];

// ── Computed KPIs ────────────────────────────────────────────────────────────

double _totalEntrees(List<_Movement> mvts) =>
    mvts.where((m) => m.qty > 0).fold(0.0, (s, m) => s + m.qty);

double _totalSorties(List<_Movement> mvts) =>
    mvts.where((m) => m.qty < 0).fold(0.0, (s, m) => s + m.qty);

double _soldeNet(List<_Movement> mvts) =>
    mvts.fold(0.0, (s, m) => s + m.qty);

// ── Grouped helper ───────────────────────────────────────────────────────────

List<String> _dateGroups(List<_Movement> mvts) {
  final seen = <String>{};
  final groups = <String>[];
  for (final m in mvts) {
    if (seen.add(m.dateGroup)) groups.add(m.dateGroup);
  }
  return groups;
}

double _groupTotal(List<_Movement> mvts, String group) =>
    mvts.where((m) => m.dateGroup == group).fold(0.0, (s, m) => s + m.qty);

int _groupCount(List<_Movement> mvts, String group) =>
    mvts.where((m) => m.dateGroup == group).length;

// ── Screen ───────────────────────────────────────────────────────────────────

class StockMovementsScreen extends ConsumerStatefulWidget {
  /// Optional: when set, the screen is filtered to a single product (from product detail).
  final String? productName;

  const StockMovementsScreen({super.key, this.productName});

  @override
  ConsumerState<StockMovementsScreen> createState() =>
      _StockMovementsScreenState();
}

class _StockMovementsScreenState extends ConsumerState<StockMovementsScreen> {
  int _periodIndex = 1; // 0=Aujourd'hui, 1=7 jours, 2=30 jours, 3=Custom
  int _typeIndex = 0; // 0=Tous, 1=Entrée, 2=Sortie, 3=Frotte, 4=Inventaire
  String? _productFilter; // desktop product dropdown
  String? _authorFilter; // desktop author dropdown
  int _sortIndex = 0; // 0=Récent, 1=Ancien
  final _nf = NumberFormat('#,###', 'fr_FR');

  bool get _isProductLocked => widget.productName != null;

  @override
  void initState() {
    super.initState();
    _productFilter = widget.productName;
  }

  List<_Movement> get _filtered {
    var list = _mockMovements.toList();
    // Product filter
    if (_productFilter != null) {
      list = list.where((m) => m.product == _productFilter).toList();
    }
    // Type filter
    switch (_typeIndex) {
      case 1:
        list = list.where((m) => m.type == MvtType.entree).toList();
      case 2:
        list = list.where((m) => m.type == MvtType.vente).toList();
      case 3:
        list = list.where((m) => m.type == MvtType.frotte).toList();
      case 4:
        list = list.where((m) => m.type == MvtType.inventaire).toList();
    }
    // Author filter
    if (_authorFilter != null) {
      list = list.where((m) => m.author == _authorFilter).toList();
    }
    // Sort
    if (_sortIndex == 1) {
      list = list.reversed.toList();
    }
    return list;
  }

  String _qtyStr(double v) {
    final abs = v.abs();
    final str =
        abs == abs.truncateToDouble() ? abs.toInt().toString() : abs.toStringAsFixed(1);
    return '${v >= 0 ? '+' : '-'}$str kg';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    if (isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(activeBreadcrumbSubLabel.notifier).state = 'Mouvements';
        }
      });
    }

    return isDesktop ? _buildDesktop() : _buildMobile();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MOBILE — Figma 52:3
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMobile() {
    final mvts = _filtered;
    final isEmpty = mvts.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: ScalarioAppBar(
        titleWidget: Column(
          children: [
            const Text('Mouvements stock',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            Text(
              _isProductLocked
                  ? '${widget.productName} · 7 derniers jours'
                  : 'Tous les produits · 7 derniers jours',
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
          // ── Period tabs ──
          _buildPeriodTabs(),
          // ── Type filter chips ──
          _buildTypeChips(),
          // ── KPI row ──
          _buildMobileKpiRow(mvts),
          // ── Movements list ──
          Expanded(
            child: isEmpty
                ? _buildMobileEmpty()
                : _buildMobileList(mvts),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTabs() {
    final tabs = ['Aujourd\'hui', '7 jours', '30 jours', 'Custom'];
    return Container(
      height: 48,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final i = e.key;
          final label = e.value;
          final isActive = _periodIndex == i;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _periodIndex = i),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF475569))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypeChips() {
    final chips = [
      ('Tous', null),
      ('Entrée', const Color(0xFF16A34A)),
      ('Sortie', const Color(0xFFDC2626)),
      ('Frotte', const Color(0xFFF59E0B)),
      ('Inventaire', const Color(0xFF1565C0)),
    ];

    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final (label, dotColor) = chips[i];
          final isActive = _typeIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _typeIndex = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: isActive
                    ? Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4))
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dotColor != null) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: dotColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? AppColors.primary
                              : const Color(0xFF475569))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileKpiRow(List<_Movement> mvts) {
    final entrees = _totalEntrees(mvts);
    final sorties = _totalSorties(mvts);
    final solde = _soldeNet(mvts);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _mobileKpi(
              '+${_fmtQty(entrees)}', 'ENTRÉES\nTOTALES', const Color(0xFF16A34A)),
          const SizedBox(width: 10),
          _mobileKpi(
              _fmtQty(sorties), 'SORTIES\nTOTALES', const Color(0xFFDC2626)),
          const SizedBox(width: 10),
          _mobileKpi(
              '${solde >= 0 ? '+' : ''}${_fmtQty(solde)}',
              'SOLDE NET\nPÉRIODE',
              solde >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
          const SizedBox(width: 10),
          _mobileKpi('${mvts.length}', 'MVT', const Color(0xFF0F172A)),
        ],
      ),
    );
  }

  Widget _mobileKpi(String value, String label, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFamily: 'RobotoMono',
                  height: 1.2)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.3,
                  height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildMobileList(List<_Movement> mvts) {
    final groups = _dateGroups(mvts);
    final items = <Widget>[];

    for (final group in groups) {
      final groupMvts = mvts.where((m) => m.dateGroup == group).toList();
      final total = _groupTotal(mvts, group);

      // Date header
      items.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Text(group,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5)),
            const Spacer(),
            Text(
              '${total >= 0 ? '+' : ''}${_fmtQty(total)} KG',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: total >= 0
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                  letterSpacing: 0.3),
            ),
          ],
        ),
      ));

      for (final m in groupMvts) {
        items.add(_buildMobileMovementCard(m));
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: items,
    );
  }

  Widget _buildMobileMovementCard(_Movement m) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Color stripe
            Container(width: 4, color: m.type.color),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: product name + qty
                    Row(
                      children: [
                        Expanded(
                          child: Text(m.product,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ),
                        Text(
                          _qtyStr(m.qty),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'RobotoMono',
                            color: m.qty >= 0
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Source row
                    Row(
                      children: [
                        Text('${m.source} ${m.sourceLink ?? ''}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Bottom: author + value
                    Row(
                      children: [
                        if (m.author.isNotEmpty) ...[
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Center(
                              child: Icon(Icons.person,
                                  size: 11, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(m.author,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B))),
                        ],
                        const Spacer(),
                        Text('${_nf.format(m.valeur)} F',
                            style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'RobotoMono',
                                color: Color(0xFF64748B))),
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(36),
            ),
            child: const Center(
                child: Text('📦', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(height: 16),
          const Text('Aucun mouvement',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          const Text(
            'Aucun mouvement de stock sur cette période.\nEssaie une période plus large ou ajuste les filtres.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DESKTOP — Figma 52:2 (bottom)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktop() {
    final mvts = _filtered;
    final groups = _dateGroups(mvts);

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
                    const Text('Mouvements stock',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            height: 1.1)),
                    const SizedBox(height: 6),
                    Text(
                      _isProductLocked
                          ? 'Mouvements de ${widget.productName} · ${_filtered.length} mouvements sur 7 jours · groupé par jour'
                          : 'Historique de ce qui passe · ${_filtered.length} mouvements sur 7 jours · groupé par jour',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _dtOutlinedBtn('↓ Export CSV'),
              const SizedBox(width: 10),
              _dtOutlinedBtn('📊 Vue groupée'),
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
                    child: Text('+ Saisir mouvement',
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

        // ── Filter bar — Figma 52:413 ──
        _desktopFilterBar(),
        const SizedBox(height: 4),

        // ── KPI cards row ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              _desktopKpiCard(
                value: '+${_fmtQty(_totalEntrees(mvts))}',
                label: 'ENTRÉES TOTALES',
                accentColor: const Color(0xFF16A34A),
              ),
              const SizedBox(width: 12),
              _desktopKpiCard(
                value: _fmtQty(_totalSorties(mvts)),
                label: 'SORTIES TOTALES',
                accentColor: const Color(0xFFDC2626),
              ),
              const SizedBox(width: 12),
              _desktopKpiCard(
                value:
                    '${_soldeNet(mvts) >= 0 ? '+' : ''}${_fmtQty(_soldeNet(mvts))}',
                label: 'SOLDE NET PÉRIODE',
                accentColor: _soldeNet(mvts) >= 0
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
              const SizedBox(width: 12),
              _desktopKpiCard(
                value: '${mvts.length}',
                label: 'NB MOUVEMENTS',
                accentColor: const Color(0xFF0F172A),
              ),
            ],
          ),
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
                    child: ListView(
                      children: [
                        for (final group in groups) ...[
                          _tableGroupHeader(group, mvts),
                          ...mvts
                              .where((m) => m.dateGroup == group)
                              .map(_tableRow),
                        ],
                      ],
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

  // ── Desktop KPI card (same style as alerts — left border accent) ──
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
            Container(width: 4, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(value,
                        style: TextStyle(
                            fontSize: 26,
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

  // ── Desktop filter bar — Figma 52:413 ──

  Widget _desktopFilterBar() {
    final periods = ['Aujourd\'hui', '7 jours', '30 jours', 'Personnalisé'];
    final types = ['Tous', 'Entrée', 'Vente', 'Frotte', 'Inventaire'];
    final products = _mockMovements.map((m) => m.product).toSet().toList();
    final authors = _mockMovements
        .where((m) => m.author.isNotEmpty)
        .map((m) => m.author)
        .toSet()
        .toList();
    final sorts = ['Plus récent', 'Plus ancien'];

    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          // PÉRIODE
          _filterDropdown(
            label: 'PÉRIODE',
            value: periods[_periodIndex],
            items: periods,
            width: 130,
            onChanged: (v) {
              final idx = periods.indexOf(v);
              if (idx >= 0) setState(() => _periodIndex = idx);
            },
          ),
          const SizedBox(width: 14),
          // TYPE
          _filterDropdown(
            label: 'TYPE',
            value: types[_typeIndex],
            items: types,
            width: 123,
            onChanged: (v) {
              final idx = types.indexOf(v);
              if (idx >= 0) setState(() => _typeIndex = idx);
            },
          ),
          const SizedBox(width: 14),
          // PRODUIT
          if (!_isProductLocked)
            _filterDropdown(
              label: 'PRODUIT',
              value: _productFilter ?? 'Tous',
              items: ['Tous', ...products],
              width: 162,
              onChanged: (v) {
                setState(() => _productFilter = v == 'Tous' ? null : v);
              },
            )
          else
            _filterDropdown(
              label: 'PRODUIT',
              value: widget.productName!,
              items: [widget.productName!],
              width: 162,
              onChanged: (_) {},
              locked: true,
            ),
          const SizedBox(width: 14),
          // AUTEUR
          _filterDropdown(
            label: 'AUTEUR',
            value: _authorFilter ?? 'Tous',
            items: ['Tous', ...authors],
            width: 72,
            onChanged: (v) {
              setState(() => _authorFilter = v == 'Tous' ? null : v);
            },
          ),
          const Spacer(),
          // TRI
          _filterDropdown(
            label: 'TRI',
            value: sorts[_sortIndex],
            items: sorts,
            width: 107,
            onChanged: (v) {
              final idx = sorts.indexOf(v);
              if (idx >= 0) setState(() => _sortIndex = idx);
            },
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required double width,
    required ValueChanged<String> onChanged,
    bool locked = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.4)),
        const SizedBox(width: 8),
        Container(
          height: 33.6,
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: locked ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              icon: locked
                  ? const SizedBox.shrink()
                  : const Icon(Icons.keyboard_arrow_down,
                      size: 16, color: Color(0xFF94A3B8)),
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w500),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: locked ? null : (v) { if (v != null) onChanged(v); },
            ),
          ),
        ),
      ],
    );
  }

  // ── Table ──

  Widget _tableHeader() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: const Color(0xFFFAFAFA),
      child: const Row(
        children: [
          SizedBox(width: 60, child: _ColLabel('HEURE')),
          SizedBox(width: 80, child: _ColLabel('TYPE')),
          Expanded(flex: 3, child: _ColLabel('PRODUIT')),
          Expanded(flex: 3, child: _ColLabel('SOURCE')),
          Expanded(flex: 2, child: _ColLabel('AUTEUR')),
          SizedBox(width: 90, child: _ColLabel('QUANTITÉ')),
          SizedBox(width: 90, child: _ColLabel('VALEUR')),
        ],
      ),
    );
  }

  Widget _tableGroupHeader(String group, List<_Movement> mvts) {
    final total = _groupTotal(mvts, group);
    final count = _groupCount(mvts, group);
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          Text(group,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5)),
          const Spacer(),
          Text(
            '${total >= 0 ? '+' : ''}${_fmtQty(total)} KG · $count MVT',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: total >= 0
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
                letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(_Movement m) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          // HEURE
          SizedBox(
            width: 60,
            child: Text(m.time,
                style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'RobotoMono',
                    color: Color(0xFF475569))),
          ),
          // TYPE badge
          SizedBox(
            width: 86,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: m.type.bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(m.type.icon,
                        style: TextStyle(
                            fontSize: 10, color: m.type.color)),
                    const SizedBox(width: 3),
                    Text(m.type.label,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: m.type.color)),
                  ],
                ),
              ),
            ),
          ),
          // PRODUIT
          Expanded(
            flex: 3,
            child: Text(m.product,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F172A)),
                overflow: TextOverflow.ellipsis),
          ),
          // SOURCE
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Flexible(
                  child: Text(m.source,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis),
                ),
                if (m.sourceLink != null)
                  Text(' ${m.sourceLink}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // AUTEUR
          Expanded(
            flex: 2,
            child: m.author.isNotEmpty
                ? Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Center(
                          child: Icon(Icons.person,
                              size: 13, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(m.author,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF475569)),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          // QUANTITÉ
          SizedBox(
            width: 90,
            child: Text(
              _qtyStr(m.qty),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'RobotoMono',
                color: m.qty >= 0
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
            ),
          ),
          // VALEUR
          SizedBox(
            width: 90,
            child: Text('${_nf.format(m.valeur)} F',
                style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'RobotoMono',
                    color: Color(0xFF475569))),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──

  String _fmtQty(double v) {
    final abs = v.abs();
    if (abs == abs.truncateToDouble()) return '${abs.toInt()} kg';
    return '${abs.toStringAsFixed(1)} kg';
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
