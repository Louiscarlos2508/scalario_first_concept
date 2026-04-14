import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Rapport Stock — Figma 21:9 "01.5 Rapport Stock"
// Mock data — backend débranché
// ══════════════════════════════════════════════════════════════════════════════

// ── Mock data ────────────────────────────────────────────────────────────────

const _mockCriticalProducts = [
  (emoji: '🍅', name: 'Tomate', category: 'Légumes', alert: 'Rupture <24h', reste: '3 kg', seuil: '50 kg', valeur: 3750.0, alertColor: AppColors.error),
  (emoji: '🥬', name: 'Salade', category: 'Légumes', alert: 'Fraîcheur rouge', reste: '8 u', seuil: '30 u', valeur: 4800.0, alertColor: AppColors.warning),
  (emoji: '🌶', name: 'Piment', category: 'Épices', alert: 'Stock bas', reste: '1.5 kg', seuil: '20 kg', valeur: 3000.0, alertColor: AppColors.warning),
  (emoji: '🥒', name: 'Concombre', category: 'Légumes', alert: 'Fraîcheur rouge', reste: '6 u', seuil: '25 u', valeur: 3600.0, alertColor: AppColors.warning),
  (emoji: '🥭', name: 'Mangue', category: 'Fruits', alert: 'Stock bas', reste: '12 u', seuil: '60 u', valeur: 9600.0, alertColor: AppColors.warning),
];

const _mockTopValeur = [
  (emoji: '🍠', name: 'Pommes de terre', category: 'Légumes', qty: '85 kg', unitPrice: '1 250 F', total: 106250.0),
  (emoji: '🧅', name: 'Oignons', category: 'Légumes', qty: '62 kg', unitPrice: '1 400 F', total: 86800.0),
  (emoji: '🥕', name: 'Carottes', category: 'Légumes', qty: '48 kg', unitPrice: '1 600 F', total: 76800.0),
  (emoji: '🍌', name: 'Bananes', category: 'Fruits', qty: '55 kg', unitPrice: '1 200 F', total: 66000.0),
  (emoji: '🥑', name: 'Avocats', category: 'Fruits', qty: '40 u', unitPrice: '1 500 F', total: 60000.0),
];

const _mockMouvements = [
  (label: 'Entrées', shortLabel: 'Entrées', icon: '↘', value: '+218', color: Color(0xFF2E7D32), bgColor: AppColors.chipSuccessBg),
  (label: 'Sorties', shortLabel: 'Sorties', icon: '↗', value: '−312', color: Color(0xFF1565C0), bgColor: AppColors.chipActionBg),
  (label: 'Ajustements', shortLabel: 'Ajust.', icon: '⇄', value: '−14', color: Color(0xFFF9A825), bgColor: AppColors.chipWarningBg),
];

const _mockStockInsights = [
  (
    title: '3 produits en rupture <24h',
    subtitle: 'À recommander dès aujourd\'hui',
    borderColor: Color(0xFFC62828),
    bgColor: Color(0xFFFFEBEE),
  ),
  (
    title: '9 produits fraîcheur rouge',
    subtitle: 'Promo express conseillée',
    borderColor: Color(0xFFF9A825),
    bgColor: Color(0xFFFFF8E1),
  ),
  (
    title: 'Stock −4% sur 7 jours',
    subtitle: 'Bonne rotation commerciale',
    borderColor: Color(0xFF1565C0),
    bgColor: Color(0xFFE3F2FD),
  ),
];

// ── Screen ───────────────────────────────────────────────────────────────────

class StockReportScreen extends StatefulWidget {
  final String periodLabel;
  final String periodDateRange;
  final VoidCallback onPeriodTap;

  const StockReportScreen({
    super.key,
    required this.periodLabel,
    required this.periodDateRange,
    required this.onPeriodTap,
  });

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  String _selectedCategorie = 'Toutes catégories';
  String _selectedTri = 'Valeur immobilisée';

  // TODO: replace with real provider when backend is wired
  static const _hasStockData = true;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    if (!_hasStockData) return _StockEmptyState(isDesktop: isDesktop);
    if (isDesktop) return _buildDesktop(context);
    return _buildMobile(context);
  }

  // ── Filter sheets ────────────────────────────────────────────────────────

  void _showCategorieFilter(BuildContext context) {
    final options = [
      _FilterOption(initial: '∗', name: 'Toutes catégories', subtitle: '187 réf. · 3 820 000 F',
          avatarBg: AppColors.chipActionBg, avatarColor: AppColors.primary),
      _FilterOption(initial: '🍎', name: 'Fruits', subtitle: '42 réf. · 1 240 000 F',
          avatarBg: AppColors.chipWarningBg, avatarColor: AppColors.chipWarningText),
      _FilterOption(initial: '🥬', name: 'Légumes', subtitle: '86 réf. · 1 980 000 F',
          avatarBg: AppColors.chipSuccessBg, avatarColor: AppColors.success),
      _FilterOption(initial: '🌶', name: 'Épices', subtitle: '31 réf. · 420 000 F',
          avatarBg: AppColors.chipErrorBg, avatarColor: AppColors.error),
      _FilterOption(initial: '🌾', name: 'Céréales', subtitle: '28 réf. · 180 000 F',
          avatarBg: AppColors.chipWarningBg, avatarColor: AppColors.chipWarningText),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        title: 'Filtrer par catégorie',
        options: options,
        selected: _selectedCategorie,
        onSelect: (name) {
          setState(() => _selectedCategorie = name);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showTriFilter(BuildContext context) {
    final options = [
      _FilterOption(initial: '💰', name: 'Valeur immobilisée', subtitle: 'Du plus cher au moins cher',
          avatarBg: AppColors.chipWarningBg, avatarColor: AppColors.chipWarningText),
      _FilterOption(initial: '🔄', name: 'Rotation', subtitle: 'Ventes / stock moyen',
          avatarBg: AppColors.chipActionBg, avatarColor: AppColors.primary),
      _FilterOption(initial: '⏱', name: 'Fraîcheur', subtitle: 'Plus urgent en premier',
          avatarBg: AppColors.chipErrorBg, avatarColor: AppColors.error),
      _FilterOption(initial: 'A', name: 'Nom (A→Z)', subtitle: 'Alphabétique',
          avatarBg: AppColors.chipSuccessBg, avatarColor: AppColors.success),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        title: 'Trier par',
        options: options,
        selected: _selectedTri,
        onSelect: (name) {
          setState(() => _selectedTri = name);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOBILE — Figma 21:9 mobile
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMobile(BuildContext context) {
    const pad = EdgeInsets.symmetric(horizontal: AppSpacing.md);

    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      children: [
        // ── Period selector ──────────────────────────────
        Padding(
          padding: pad,
          child: GestureDetector(
            onTap: widget.onPeriodTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        Text('${widget.periodLabel} · ${widget.periodDateRange}',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  const Text('▾',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Hero card (orange gradient) ─────────────────
        Padding(
          padding: pad,
          child: const _StockHeroCard(isDesktop: false),
        ),
        const SizedBox(height: 20),

        // ── Filter chips ─────────────────────────────────
        Padding(
          padding: pad,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showCategorieFilter(context),
                child: _FilterChip(
                    label: _selectedCategorie,
                    isSelected: _selectedCategorie != 'Toutes catégories'),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showTriFilter(context),
                child: _FilterChip(
                    label: '↕ Tri : ${_selectedTri.toLowerCase()}',
                    isSelected: _selectedTri != 'Valeur immobilisée'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Produits critiques (4 on mobile) ────────────
        Padding(
          padding: pad,
          child: const _CriticalProductsCard(isDesktop: false),
        ),
        const SizedBox(height: 16),

        // ── Top valeur immobilisée (4 on mobile) ────────
        Padding(
          padding: pad,
          child: const _TopValeurCard(isDesktop: false),
        ),
        const SizedBox(height: 16),

        // ── Mouvements (no solde net on mobile) ─────────
        Padding(
          padding: pad,
          child: const _MouvementsCard(isDesktop: false),
        ),
        const SizedBox(height: 20),

        // ── Export button ────────────────────────────────
        Padding(
          padding: pad,
          child: _ExportButton(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DESKTOP — Figma 21:9 desktop
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktop(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 32),
      children: [
        // ── Hero card (orange gradient, 4 columns) ──────
        const _StockHeroCard(isDesktop: true),
        const SizedBox(height: 24),

        // ── Row 1: Produits critiques + Mouvements ──────
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                flex: 3,
                child: _CriticalProductsCard(isDesktop: true),
              ),
              const SizedBox(width: 16),
              const Expanded(
                flex: 2,
                child: _MouvementsCard(isDesktop: true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Row 2: Top valeur + Insights ────────────────
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                flex: 3,
                child: _TopValeurCard(isDesktop: true),
              ),
              const SizedBox(width: 16),
              const Expanded(
                flex: 2,
                child: _StockInsightsCard(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Hero card — orange gradient (Figma 21:705)
// ══════════════════════════════════════════════════════════════════════════════

class _StockHeroCard extends StatelessWidget {
  final bool isDesktop;
  const _StockHeroCard({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 16),
        gradient: const LinearGradient(
          begin: Alignment(-0.6, -1),
          end: Alignment(0.6, 1),
          colors: [AppColors.stockPrimary, AppColors.stockDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.stockPrimary.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          const Opacity(
            opacity: 0.85,
            child: Text(
              'VALEUR STOCK TOTALE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Value
          const Text('3 820 000 F',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cousine',
                color: Colors.white,
                height: 1,
              )),
          const SizedBox(height: 10),
          // Trend — delta amount, not previous total
          Opacity(
            opacity: 0.95,
            child: Text.rich(TextSpan(children: [
              const TextSpan(
                  text: '▼ ',
                  style: TextStyle(fontSize: 13, color: Colors.white)),
              const TextSpan(
                  text: '−4%',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.trendGreenLight)),
              const TextSpan(
                  text: ' vs sem. dernière (−160 000 F)',
                  style: TextStyle(fontSize: 13, color: Colors.white)),
            ])),
          ),
          const SizedBox(height: 16),
          // Separator
          Container(
            height: 0.8,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 14),
          // Sub-metrics
          if (isDesktop)
            Row(
              children: [
                _HeroMetric(label: 'RÉFÉRENCES', value: '187', sub: '12 catégories'),
                _verticalDivider(),
                _HeroMetric(label: 'QUANTITÉ TOTALE', value: '2 145', sub: 'unités cumulées'),
                _verticalDivider(),
                _HeroMetric(label: 'CRITIQUES', value: '12', sub: 'ruptures & fraîcheur'),
              ],
            )
          else
            Row(
              children: [
                _HeroSub(label: 'Références', value: '187'),
                const SizedBox(width: 24),
                _HeroSub(label: 'Quantité', value: '2 145'),
                const SizedBox(width: 24),
                _HeroSub(label: 'Critiques', value: '12'),
              ],
            ),
        ],
      ),
    );
  }

  static Widget _verticalDivider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: 0.8,
          height: 48,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      );
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  const _HeroMetric(
      {required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Opacity(
          opacity: 0.85,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5)),
        ),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cousine',
                color: Colors.white)),
        const SizedBox(height: 4),
        Opacity(
          opacity: 0.85,
          child: Text(sub,
              style: const TextStyle(fontSize: 11, color: Colors.white)),
        ),
      ],
    );
  }
}

class _HeroSub extends StatelessWidget {
  final String label;
  final String value;
  const _HeroSub({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cousine',
                color: Colors.white)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Produits critiques — Figma 21:9
// Mobile: list 4 items | Desktop: table 5 items with columns
// ══════════════════════════════════════════════════════════════════════════════

class _CriticalProductsCard extends StatelessWidget {
  final bool isDesktop;
  const _CriticalProductsCard({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final count = isDesktop ? _mockCriticalProducts.length : 4;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('Produits critiques',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('$count ALERTES',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          if (isDesktop) _buildDesktopTable(count) else _buildMobileList(count),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(int count) {
    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('Produit',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      letterSpacing: 0.5, color: AppColors.textSecondary))),
              Expanded(flex: 2, child: Text('État',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      letterSpacing: 0.5, color: AppColors.textSecondary))),
              SizedBox(width: 70, child: Text('Reste',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      letterSpacing: 0.5, color: AppColors.textSecondary))),
              SizedBox(width: 70, child: Text('Seuil',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      letterSpacing: 0.5, color: AppColors.textSecondary))),
              SizedBox(width: 80, child: Text('Valeur',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      letterSpacing: 0.5, color: AppColors.textSecondary))),
            ],
          ),
        ),
        // Table rows
        ...List.generate(count, (i) {
          final p = _mockCriticalProducts[i];
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: i < count - 1
                  ? const Border(bottom: BorderSide(color: AppColors.border, width: 0.5))
                  : null,
            ),
            child: Row(
              children: [
                // Produit (emoji + name + category)
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: p.alertColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(p.emoji, style: const TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(p.category, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                // État
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(width: 6, height: 6,
                          decoration: BoxDecoration(color: p.alertColor, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(p.alert, style: TextStyle(fontSize: 12, color: p.alertColor, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                // Reste
                SizedBox(width: 70,
                    child: Text(p.reste, textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cousine'))),
                // Seuil
                SizedBox(width: 70,
                    child: Text(p.seuil, textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                // Valeur
                SizedBox(width: 80,
                    child: Text(_fmtCurrency(p.valeur), textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Cousine'))),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMobileList(int count) {
    return Column(
      children: List.generate(count, (i) {
        final p = _mockCriticalProducts[i];
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: i < count - 1
                ? const Border(bottom: BorderSide(color: AppColors.border, width: 0.5))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: p.alertColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(p.emoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(width: 6, height: 6,
                            decoration: BoxDecoration(color: p.alertColor, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(p.alert,
                            style: TextStyle(fontSize: 12, color: p.alertColor, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              Text.rich(TextSpan(children: [
                TextSpan(text: p.reste,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cousine', color: AppColors.textPrimary)),
                TextSpan(text: ' / ${p.seuil}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ])),
            ],
          ),
        );
      }),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Mouvements stock — Figma 21:900
// Mobile: tiles only (no solde net) | Desktop: tiles + solde net + subtitle
// ══════════════════════════════════════════════════════════════════════════════

class _MouvementsCard extends StatelessWidget {
  final bool isDesktop;
  const _MouvementsCard({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Text('Mouvements',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Spacer(),
              Text('7 JOURS',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 18),
          // Movement tiles — horizontal row
          Row(
            children: _mockMouvements.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.sheetBg,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Column(
                      children: [
                        Text(m.icon,
                            style: const TextStyle(fontSize: 18, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Text(m.value,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cousine',
                                color: m.color)),
                        const SizedBox(height: 4),
                        Text(m.shortLabel.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 0.4,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          // Solde net — desktop only, below separator
          if (isDesktop) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              height: 0.8,
              color: AppColors.border,
            ),
            const SizedBox(height: 18),
            const Text('SOLDE NET',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            const Text('−108 unités',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cousine',
                    color: AppColors.error)),
            const SizedBox(height: 4),
            const Text('Stock en baisse cette semaine',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Top valeur immobilisée — Figma 21:9
// Mobile: list 4 items | Desktop: table 5 items with columns
// ══════════════════════════════════════════════════════════════════════════════

class _TopValeurCard extends StatelessWidget {
  final bool isDesktop;
  const _TopValeurCard({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final count = isDesktop ? _mockTopValeur.length : 4;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('Top valeur immobilisée',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(isDesktop ? '5 PRODUITS' : 'Top 4',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          if (isDesktop) _buildDesktopTable(count) else _buildMobileList(count),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(int count) {
    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('Produit',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      letterSpacing: 0.5, color: AppColors.textSecondary))),
              Expanded(flex: 2, child: Text('Catégorie',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      letterSpacing: 0.5, color: AppColors.textSecondary))),
              SizedBox(width: 70, child: Text('Qté',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      letterSpacing: 0.5, color: AppColors.textSecondary))),
              SizedBox(width: 80, child: Text('PU',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      letterSpacing: 0.5, color: AppColors.textSecondary))),
              SizedBox(width: 90, child: Text('Valeur',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      letterSpacing: 0.5, color: AppColors.textSecondary))),
            ],
          ),
        ),
        // Table rows
        ...List.generate(count, (i) {
          final p = _mockTopValeur[i];
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: i < count - 1
                  ? const Border(bottom: BorderSide(color: AppColors.border, width: 0.5))
                  : null,
            ),
            child: Row(
              children: [
                // Produit
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.chipWarningBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(p.emoji, style: const TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 10),
                      Flexible(child: Text(p.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                // Catégorie
                Expanded(
                  flex: 2,
                  child: Text(p.category,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
                // Qté
                SizedBox(width: 70,
                    child: Text(p.qty, textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 13, fontFamily: 'Cousine'))),
                // PU
                SizedBox(width: 80,
                    child: Text(p.unitPrice, textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                // Valeur
                SizedBox(width: 90,
                    child: Text(_fmtCurrency(p.total), textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Cousine'))),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMobileList(int count) {
    return Column(
      children: List.generate(count, (i) {
        final p = _mockTopValeur[i];
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: i < count - 1
                ? const Border(bottom: BorderSide(color: AppColors.border, width: 0.5))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.chipWarningBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(p.emoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${p.qty} × ${p.unitPrice}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text(_fmtCurrency(p.total),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Cousine',
                      color: AppColors.textPrimary)),
            ],
          ),
        );
      }),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Insights stock — Figma 21:1079 (desktop only)
// ══════════════════════════════════════════════════════════════════════════════

class _StockInsightsCard extends StatelessWidget {
  const _StockInsightsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Text('Insights',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Spacer(),
              Text('AUTO',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 18),
          ..._mockStockInsights.map((ins) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ins.bgColor,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border(
                      left: BorderSide(color: ins.borderColor, width: 4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ins.title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(ins.subtitle,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Filter chip
// ══════════════════════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _FilterChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.textPrimary : AppColors.border,
          width: isSelected ? 1.2 : 0.8,
        ),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary)),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Export button (mobile)
// ══════════════════════════════════════════════════════════════════════════════

class _ExportButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.stockPrimary,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('↗', style: TextStyle(fontSize: 16, color: Colors.white)),
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
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Empty state — Figma 21:1188
// ══════════════════════════════════════════════════════════════════════════════

class _StockEmptyState extends StatelessWidget {
  final bool isDesktop;
  const _StockEmptyState({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? AppSpacing.xl : AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 1.6,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📦', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text('Aucune référence en stock',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const SizedBox(
                width: 480,
                child: Text(
                  'Enregistre ta première réception pour voir ton stock, ses mouvements et tes produits critiques.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('+ Nouvelle réception',
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
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

String _fmtCurrency(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M F';
  if (v >= 1000) return '${(v / 1000).round()} 000 F';
  return '${v.toStringAsFixed(0)} F';
}

// ══════════════════════════════════════════════════════════════════════════════
// Filter bottom sheet
// ══════════════════════════════════════════════════════════════════════════════

class _FilterOption {
  final String initial;
  final String name;
  final String subtitle;
  final Color avatarBg;
  final Color avatarColor;

  const _FilterOption({
    required this.initial,
    required this.name,
    required this.subtitle,
    required this.avatarBg,
    required this.avatarColor,
  });
}

class _FilterSheet extends StatelessWidget {
  final String title;
  final List<_FilterOption> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 48, height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ),
          ),
          const SizedBox(height: 14),
          ...options.map((o) {
            final isSelected = o.name == selected;
            return GestureDetector(
              onTap: () => onSelect(o.name),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.chipActionBg : AppColors.sheetBg,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.6 : 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: o.avatarBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(o.initial,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: o.avatarColor)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.name,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(o.subtitle,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
