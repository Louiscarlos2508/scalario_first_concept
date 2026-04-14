import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Hub rapports — Figma 19:2 "01.3 Hub rapports"
// Mock data — backend débranché
// ══════════════════════════════════════════════════════════════════════════════

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';
  int _periodIndex = 2; // Default: "7 derniers jours"

  static const _tabsMobile = [
    'Aperçu',
    'CA',
    'Stock',
    'Pertes',
    'Vendeurs',
    'Paiements',
  ];

  static const _tabsDesktop = [
    'Aperçu',
    "Chiffre d'affaires",
    'Stock',
    'Pertes',
    'Vendeurs',
    'Paiements',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabsMobile.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _periodLabel => _periodLabels[_periodIndex];

  String get _periodDateRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_periodIndex) {
      case 0:
        return DateFormat("d MMMM yyyy", "fr_FR").format(today);
      case 1:
        return DateFormat("d MMMM yyyy", "fr_FR")
            .format(today.subtract(const Duration(days: 1)));
      case 2:
        final start = today.subtract(const Duration(days: 6));
        return '${DateFormat("d MMM", "fr_FR").format(start)} \u2192 ${DateFormat("d MMM yyyy", "fr_FR").format(today)}';
      case 3:
        return '1er ${DateFormat("MMMM yyyy", "fr_FR").format(today)}  \u2192 ${DateFormat("d MMM yyyy", "fr_FR").format(today)}';
      case 4:
        final prev = DateTime(now.year, now.month - 1, 1);
        return DateFormat("MMMM yyyy", "fr_FR").format(prev);
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final tabs = isDesktop ? _tabsDesktop : _tabsMobile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop ? null : const ScalarioAppBar(title: 'Rapports'),
      body: Column(
        children: [
          // ── Header + search + period (desktop only) ─────
          if (isDesktop) ...[
            _DesktopHeader(
              periodLabel: _periodLabel,
              periodDateRange: _periodDateRange,
              searchQuery: _searchQuery,
              onSearchChanged: (q) => setState(() => _searchQuery = q),
              onPeriodTap: () => _showPeriodSelector(context, true),
              onExportTap: () {},
            ),
          ],

          // ── Tab bar ──────────────────────────────────────
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500),
              indicatorColor: AppColors.textPrimary,
              indicatorWeight: 2.5,
              dividerColor: AppColors.border,
              padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? AppSpacing.xl : AppSpacing.md),
              tabs: tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),

          // ── Tab content ─────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(
                  isDesktop: isDesktop,
                  searchQuery: _searchQuery,
                  periodIndex: _periodIndex,
                  onSearchChanged: (q) => setState(() => _searchQuery = q),
                  onPeriodTap: () => _showPeriodSelector(context, isDesktop),
                  onExportTap: () {},
                  onCardTap: (tabIndex) =>
                      _tabController.animateTo(tabIndex),
                ),
                _PlaceholderTab(
                    title: "Chiffre d'affaires", emoji: '\u{20A3}'),
                const _PlaceholderTab(
                    title: 'Stock', emoji: '\u{1F4E6}'),
                const _PlaceholderTab(
                    title: 'Pertes', emoji: '\u26A0'),
                const _PlaceholderTab(
                    title: 'Vendeurs', emoji: '\u{1F465}'),
                const _PlaceholderTab(
                    title: 'Paiements', emoji: '\u{1F4B3}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPeriodSelector(BuildContext context, bool isDesktop) {
    final content = _ReportPeriodSheet(
      selectedIndex: _periodIndex,
      onSelect: (index) {
        setState(() => _periodIndex = index);
        Navigator.pop(context);
      },
    );

    if (isDesktop) {
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
            child: content,
          ),
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (_, controller) => content,
        ),
      );
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Desktop header — Figma 19:560
// ══════════════════════════════════════════════════════════════════════════════

class _DesktopHeader extends StatelessWidget {
  final String periodLabel;
  final String periodDateRange;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onPeriodTap;
  final VoidCallback onExportTap;

  const _DesktopHeader({
    required this.periodLabel,
    required this.periodDateRange,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onPeriodTap,
    required this.onExportTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: [
              Text('Boutique Ouaga',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500)),
              const SizedBox(width: 6),
              const Text('Rapports',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          // Title row + search + period + export
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rapports',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                        'Vue d\'ensemble \u00B7 Période : $periodDateRange',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Search
              SizedBox(
                width: 240,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: TextField(
                    onChanged: onSearchChanged,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un rapport...',
                      hintStyle: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      prefixIcon: Icon(Icons.search,
                          size: 18, color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Period button
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onPeriodTap,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('\u{1F4C5}',
                            style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 8),
                        Text('$periodLabel \u2022',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Export button
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onExportTap,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('\u2197',
                            style:
                                TextStyle(fontSize: 14, color: Colors.white)),
                        SizedBox(width: 6),
                        Text('Exporter & partager',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Aperçu tab — Figma 19:2 hub view
// ══════════════════════════════════════════════════════════════════════════════

const _periodLabels = [
  "Aujourd'hui",
  'Hier',
  '7 derniers jours',
  'Ce mois',
  'Mois dernier',
];

class _OverviewTab extends StatelessWidget {
  final bool isDesktop;
  final String searchQuery;
  final int periodIndex;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onPeriodTap;
  final VoidCallback onExportTap;
  final ValueChanged<int> onCardTap;

  const _OverviewTab({
    required this.isDesktop,
    required this.searchQuery,
    required this.periodIndex,
    required this.onSearchChanged,
    required this.onPeriodTap,
    required this.onExportTap,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final pad = EdgeInsets.symmetric(
      horizontal: isDesktop ? AppSpacing.xl : AppSpacing.md,
    );

    // Mock report cards — Figma 19:2
    final cards = [
      _ReportCardData(
        emoji: 'F',
        emojiBg: AppColors.chipActionBg,
        emojiColor: AppColors.primary,
        title: "Chiffre d'affaires",
        subtitle: 'Total période',
        value: '2 450 000 F',
        trend: '\u25B2 +12% vs sem. dernière',
        trendColor: AppColors.success,
        tabIndex: 1,
      ),
      _ReportCardData(
        emoji: '\u{1F4E6}',
        emojiBg: AppColors.chipWarningBg,
        emojiColor: AppColors.chipWarningText,
        title: 'Stock',
        subtitle: 'Réfs en stock bas',
        value: '42',
        trend: '\u25BC -3 vs hier',
        trendColor: AppColors.error,
        tabIndex: 2,
      ),
      _ReportCardData(
        emoji: '\u26A0',
        emojiBg: AppColors.chipErrorBg,
        emojiColor: AppColors.error,
        title: 'Pertes',
        subtitle: 'Coût période',
        value: '85 000 F',
        trend: '\u25B2 +5%',
        trendColor: AppColors.error,
        tabIndex: 3,
      ),
      _ReportCardData(
        emoji: '\u{1F465}',
        emojiBg: AppColors.chipActionBg,
        emojiColor: AppColors.primary,
        title: 'Vendeurs',
        subtitle: 'Top : Awa \u00B7 612 000 F',
        value: '5 actifs',
        trend: '\u25B2 +1',
        trendColor: AppColors.success,
        tabIndex: 4,
      ),
      _ReportCardData(
        emoji: '\u{1F4B3}',
        emojiBg: AppColors.chipActionBg,
        emojiColor: AppColors.primary,
        title: 'Modes de paiement',
        subtitle: 'Cash 62% \u00B7 OM 31% \u00B7 Crédit 7%',
        value: '3 actifs',
        trend: '\u2014',
        trendColor: AppColors.textSecondary,
        tabIndex: 5,
      ),
    ];

    // Desktop has a 6th card: Tendances
    if (isDesktop) {
      cards.add(_ReportCardData(
        emoji: '\u{1F4C8}',
        emojiBg: const Color(0xFFF3E8FF),
        emojiColor: const Color(0xFF7C3AED),
        title: 'Tendances',
        subtitle: 'Comparaisons multi-périodes',
        value: '7 vues',
        trend: 'Nouveau',
        trendColor: AppColors.primary,
        tabIndex: 0,
      ));
    }

    // Filter by search
    final filtered = searchQuery.isEmpty
        ? cards
        : cards
            .where((c) =>
                c.title.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

    if (isDesktop) return _buildDesktop(context, pad, filtered);
    return _buildMobile(context, pad, filtered);
  }

  // ── Mobile layout — Figma 19:11 ──────────────────────────────────────
  Widget _buildMobile(
      BuildContext context, EdgeInsets pad, List<_ReportCardData> filtered) {
    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      children: [
        // Header
        Padding(
          padding: pad,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rapports',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              SizedBox(height: 4),
              Text('Vue d\'ensemble \u00B7 Boutique Ouaga',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Search
        Padding(
          padding: pad,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: TextField(
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Rechercher un rapport...',
                hintStyle:
                    TextStyle(fontSize: 14, color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search,
                    size: 18, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Period selector
        Padding(
          padding: pad,
          child: GestureDetector(
            onTap: onPeriodTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PÉRIODE',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(_periodLabels[periodIndex],
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  const Text('\u25BE',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // "RAPPORTS DISPONIBLES" label
        Padding(
          padding: pad,
          child: const Text('RAPPORTS DISPONIBLES',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 10),

        // Report cards — mobile style (horizontal row)
        if (filtered.isEmpty)
          Padding(padding: pad, child: const _EmptyState())
        else
          ...filtered.map((c) => Padding(
                padding: pad.copyWith(bottom: 10),
                child: _MobileReportCard(
                    data: c, onTap: () => onCardTap(c.tabIndex)),
              )),
        const SizedBox(height: 20),

        // Export button
        Padding(
          padding: pad,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onExportTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('\u2197',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                    SizedBox(width: 8),
                    Text('Exporter & partager',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Desktop layout — Figma 19:560 (grid 3x2) ────────────────────────
  Widget _buildDesktop(
      BuildContext context, EdgeInsets pad, List<_ReportCardData> filtered) {
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: pad,
          child: const _EmptyState(),
        ),
      );
    }

    // Build rows of 3 cards each
    final rows = <List<_ReportCardData>>[];
    for (var i = 0; i < filtered.length; i += 3) {
      rows.add(filtered.sublist(
          i, i + 3 > filtered.length ? filtered.length : i + 3));
    }

    return ListView(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: 32,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
      ),
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < rows[r].length; c++) ...[
                if (c > 0) const SizedBox(width: 16),
                Expanded(
                  child: _DesktopReportCard(
                    data: rows[r][c],
                    onTap: () => onCardTap(rows[r][c].tabIndex),
                  ),
                ),
              ],
              // Fill remaining slots with empty Expanded to keep equal widths
              for (var e = rows[r].length; e < 3; e++) ...[
                const SizedBox(width: 16),
                const Expanded(child: SizedBox.shrink()),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Report card data
// ══════════════════════════════════════════════════════════════════════════════

class _ReportCardData {
  final String emoji;
  final Color emojiBg;
  final Color emojiColor;
  final String title;
  final String subtitle;
  final String value;
  final String trend;
  final Color trendColor;
  final int tabIndex;

  const _ReportCardData({
    required this.emoji,
    required this.emojiBg,
    required this.emojiColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.trend,
    required this.trendColor,
    required this.tabIndex,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// Mobile report card — Figma 19:11 (horizontal: icon | title+value+trend | ›)
// ══════════════════════════════════════════════════════════════════════════════

class _MobileReportCard extends StatelessWidget {
  final _ReportCardData data;
  final VoidCallback onTap;

  const _MobileReportCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: data.emojiBg,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                alignment: Alignment.center,
                child: Text(data.emoji,
                    style: TextStyle(fontSize: 22, color: data.emojiColor)),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(data.value,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cousine',
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(data.trend,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: data.trendColor)),
                  ],
                ),
              ),
              // Chevron
              const Text('\u203A',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Desktop report card — Figma 19:560 (vertical: icon+title+sub top, value bottom, trend+Voir)
// ══════════════════════════════════════════════════════════════════════════════

class _DesktopReportCard extends StatelessWidget {
  final _ReportCardData data;
  final VoidCallback onTap;

  const _DesktopReportCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: icon + title + subtitle
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: data.emojiBg,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    alignment: Alignment.center,
                    child: Text(data.emoji,
                        style:
                            TextStyle(fontSize: 20, color: data.emojiColor)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.title,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(data.subtitle,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Value — large mono
              Text(data.value,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cousine',
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              // Bottom row: trend left, "Voir →" right
              Row(
                children: [
                  Text(data.trend,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: data.trendColor)),
                  const Spacer(),
                  Text('Voir \u2192',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Empty state — Figma 19:783
// ══════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('\u{1F4CA}', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 20),
          const Text('Pas encore de rapports',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const SizedBox(
            width: 340,
            child: Text(
              'Les rapports CA, stock, pertes, vendeurs et paiements s\'activent dès tes premières ventes ou réceptions stock.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Text('+ Enregistrer une vente',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Period selector sheet — same style as dashboard (Figma 11:710)
// ══════════════════════════════════════════════════════════════════════════════

class _ReportPeriodSheet extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _ReportPeriodSheet({
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  State<_ReportPeriodSheet> createState() => _ReportPeriodSheetState();
}

class _ReportPeriodSheetState extends State<_ReportPeriodSheet> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final options = [
      (
        label: "Aujourd'hui",
        sub: '${DateFormat("d MMMM", "fr_FR").format(today)} \u00B7 en cours',
      ),
      (
        label: 'Hier',
        sub: '${DateFormat("d MMMM", "fr_FR").format(yesterday)} \u00B7 journée complète',
      ),
      (
        label: '7 derniers jours',
        sub: '${DateFormat("d MMM", "fr_FR").format(today.subtract(const Duration(days: 6)))} \u2192 ${DateFormat("d MMM", "fr_FR").format(today)}',
      ),
      (
        label: 'Ce mois',
        sub: '1er \u2192 ${DateFormat("d MMMM", "fr_FR").format(today)}',
      ),
      (
        label: 'Mois dernier',
        sub: DateFormat("MMMM yyyy", "fr_FR")
            .format(DateTime(now.year, now.month - 1, 1)),
      ),
    ];

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Choisir la période',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Quels chiffres veux-tu voir ?',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: options.asMap().entries.map((e) {
                  final i = e.key;
                  final opt = e.value;
                  final isSelected = i == _selected;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = i),
                      child: Container(
                        height: 62,
                        padding: const EdgeInsets.symmetric(horizontal: 17),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.chipActionBg
                              : AppColors.sheetBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: isSelected ? 1.6 : 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(opt.label,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(opt.sub,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: AppColors.border, width: 0.8),
                      ),
                      child: const Text('Annuler',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onSelect(_selected),
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Appliquer',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Placeholder tab — sub-reports (bientôt disponible)
// ══════════════════════════════════════════════════════════════════════════════

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final String emoji;

  const _PlaceholderTab({required this.title, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Bientôt disponible',
              style: TextStyle(
                  fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
