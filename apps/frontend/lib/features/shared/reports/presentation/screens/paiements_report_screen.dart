import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/reports/presentation/screens/export_share_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Rapport paiements — Figma 25:2 "01.9 Rapport modes de paiement"
// Mock data — backend débranché
// ══════════════════════════════════════════════════════════════════════════════

// ── Mock data ────────────────────────────────────────────────────────────────

const _mockModes = [
  (
    icon: '₣',
    iconBg: Color(0xFF34A853),
    name: 'Cash',
    transactions: 52,
    transLabel: '52 transactions · 0 F frais',
    brut: '861 000 F',
    frais: '0 F',
    net: '861 000 F',
    netLabel: 'net 861 000 F',
    part: '42%',
    partRaw: 0.42,
  ),
  (
    icon: 'W',
    iconBg: Color(0xFF1DC8DB),
    name: 'Wave',
    transactions: 38,
    transLabel: '38 transactions · 5 740 F frais',
    brut: '574 000 F',
    frais: '5 740 F',
    net: '568 260 F',
    netLabel: 'net 568 260 F',
    part: '28%',
    partRaw: 0.28,
  ),
  (
    icon: 'OM',
    iconBg: Color(0xFFFF6F00),
    name: 'Orange Money',
    transactions: 23,
    transLabel: '23 transactions · 5 640 F frais',
    brut: '369 000 F',
    frais: '5 640 F',
    net: '363 360 F',
    netLabel: 'net 363 360 F',
    part: '18%',
    partRaw: 0.18,
  ),
  (
    icon: 'C',
    iconBg: Color(0xFF1A73E8),
    name: 'Crédit client',
    transactions: 15,
    transLabel: '15 transactions · à recouvrer',
    brut: '246 000 F',
    frais: '—',
    net: 'en attente',
    netLabel: 'en attente',
    part: '12%',
    partRaw: 0.12,
  ),
];

const _mockCredits = [
  (initial: 'D', name: 'Mr Diallo', category: 'Restaurant', age: '18 jours d\'ancienneté', ageShort: '18 j', amount: '148 000 F'),
  (initial: 'A', name: 'Aïssa Sow', category: 'Particulier', age: '14 jours', ageShort: '14 j', amount: '92 500 F'),
  (initial: 'C', name: 'Cantine Lycée', category: 'Institution', age: '16 jours', ageShort: '16 j', amount: '76 000 F'),
  (initial: 'F', name: 'Famille Touré', category: 'Particulier', age: '9 jours', ageShort: '9 j', amount: '52 000 F'),
  (initial: '+', name: '4 autres clients', category: '', age: 'moy. 6 jours', ageShort: 'moy. 6 j', amount: '50 000 F'),
];

const _mockTrendBars = [
  (label: 'S-3', factor: 0.42),
  (label: 'S-2', factor: 0.55),
  (label: 'S-1', factor: 0.68),
  (label: 'S0', factor: 0.88),
];

const _mockInsights = [
  (title: 'Wave en hausse', body: '+34% vs sem. dernière, dépasse OM pour la 1re fois', bodyShort: '+34% vs sem. dernière, dépasse OM pour la 1re fois'),
  (title: '3 crédits à relancer', body: 'Mr Diallo, Aïssa, Cantine Lycée > 14 jours d\'ancienneté', bodyShort: 'Mr Diallo, Aïssa, Cantine Lycée > 14 jours'),
  (title: 'Frais OM élevés', body: '1,53% sur OM vs 1,00% sur Wave. Pousse Wave si possible', bodyShort: '1,53% sur OM vs 1,00% sur Wave'),
];

const _mockFilters = [
  (icon: '∗', label: 'Tous les statuts', detail: '128 transactions · 2 050 000 F'),
  (icon: '✓', label: 'Encaissé', detail: '113 transactions · 1 804 000 F'),
  (icon: '⏳', label: 'En attente', detail: '15 transactions · 246 000 F'),
  (icon: '✕', label: 'Refusé', detail: '0 transaction'),
];

// ── Donut colors matching legend order ──────────────────────────────────────
const _donutColors = [
  Color(0xFF34A853), // Cash
  Color(0xFF1DC8DB), // Wave
  Color(0xFFFF6F00), // Orange Money
  Color(0xFF1A73E8), // Crédit
];

// ── Screen widget ──────────────────────────────────────────────────────────

class PaiementsReportScreen extends StatefulWidget {
  final String periodLabel;
  final String periodDateRange;
  final VoidCallback onPeriodTap;

  const PaiementsReportScreen({
    super.key,
    required this.periodLabel,
    required this.periodDateRange,
    required this.onPeriodTap,
  });

  @override
  State<PaiementsReportScreen> createState() => _PaiementsReportScreenState();
}

class _PaiementsReportScreenState extends State<PaiementsReportScreen> {
  final bool _hasPaiements = true;
  int _filterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    if (!_hasPaiements) {
      return isDesktop ? _buildDesktopEmpty() : _buildMobileEmpty();
    }
    return isDesktop ? _buildDesktop() : _buildMobile();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MOBILE LAYOUT — Figma 25:10
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMobile() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        // ── Period selector ───────────────────────────────
        _buildMobilePeriodCard(),
        const SizedBox(height: 12),

        // ── Hero KPIs ────────────────────────────────────
        _buildMobileHero(),
        const SizedBox(height: 12),

        // ── Filter chips ─────────────────────────────────
        _buildFilterChips(),
        const SizedBox(height: 16),

        // ── Répartition par mode (donut) ─────────────────
        _buildMobileDonut(),
        const SizedBox(height: 12),

        // ── Détail par mode ──────────────────────────────
        _buildMobileDetailCards(),
        const SizedBox(height: 12),

        // ── Crédits ouverts ──────────────────────────────
        _buildMobileCredits(),
        const SizedBox(height: 12),

        // ── Tendance mobile money ────────────────────────
        _buildTrendChart(),
        const SizedBox(height: 12),

        // ── Insights ─────────────────────────────────────
        _buildMobileInsights(),
        const SizedBox(height: 16),

        // ── CTA ──────────────────────────────────────────
        _buildCta(),
      ],
    );
  }

  // ── Mobile period card ──────────────────────────────────────────────────

  Widget _buildMobilePeriodCard() {
    return GestureDetector(
      onTap: widget.onPeriodTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
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
                  const SizedBox(height: 4),
                  Text('${widget.periodLabel} · ${widget.periodDateRange}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
            const Text('▾',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ── Mobile hero KPIs — Figma 25:35 ─────────────────────────────────────

  Widget _buildMobileHero() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0891B2), Color(0xFF0E4F67)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💳 TOTAL ENCAISSÉ · SEMAINE',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Colors.white70)),
          const SizedBox(height: 6),
          const Text('2 050 000 F',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cousine',
                  color: Colors.white)),
          const SizedBox(height: 4),
          const Text('▲ +12% vs sem. dernière · 58% mobile money',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70)),
          const SizedBox(height: 12),
          // Split row
          Row(
            children: [
              _heroSplit('Cash', '861 000 F'),
              Container(width: 0.8, height: 28, color: Colors.white30),
              _heroSplit('Mobile', '1 189 000 F'),
              Container(width: 0.8, height: 28, color: Colors.white30),
              _heroSplit('Frais', '11 380 F'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroSplit(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white70)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cousine',
                  color: Colors.white)),
        ],
      ),
    );
  }

  // ── Filter chips ───────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    const labels = ['Tous statuts', 'Encaissé', 'En attente'];
    return Row(
      children: List.generate(labels.length, (i) {
        final isActive = _filterIndex == i;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              if (i == 0) {
                _showFilterSheet();
              } else {
                setState(() => _filterIndex = i);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.primary : AppColors.border,
                  width: 0.8,
                ),
              ),
              child: Text(labels[i],
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppColors.textPrimary)),
            ),
          ),
        );
      }),
    );
  }

  // ── Mobile donut — Figma 25:69 ─────────────────────────────────────────

  Widget _buildMobileDonut() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Répartition par mode',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const Spacer(),
              const Text('4 modes',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Donut chart
              SizedBox(
                width: 128, height: 128,
                child: CustomPaint(
                  painter: _DonutPainter(
                    values: _mockModes.map((m) => m.partRaw).toList(),
                    colors: _donutColors,
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('2,05M',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cousine',
                                color: AppColors.textPrimary)),
                        Text('Total',
                            style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(_mockModes.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              color: _donutColors[i],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_mockModes[i].name,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary)),
                          const Spacer(),
                          Text(_mockModes[i].part,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Mobile detail cards — Figma 25:98 ──────────────────────────────────

  Widget _buildMobileDetailCards() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Text('Détail par mode',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Spacer(),
              Text('Net après frais',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(_mockModes.length, (i) {
            final m = _mockModes[i];
            final isLast = i == _mockModes.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: !isLast
                    ? const Border(bottom: BorderSide(color: AppColors.border, width: 0.8))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: m.iconBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(m.icon,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(m.transLabel,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(m.brut,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cousine',
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(m.netLabel,
                          style: TextStyle(
                              fontSize: 11,
                              color: m.net == 'en attente'
                                  ? const Color(0xFFB27A00)
                                  : AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Mobile credits — Figma 25:130 ──────────────────────────────────────

  Widget _buildMobileCredits() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚠ Crédits ouverts',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const Spacer(),
              const Text('Cumul',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('418 500 F',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cousine',
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('8 clients · ancienneté moy. 12 j',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          // Top 3 debtors
          ...List.generate(3, (i) {
            final c = _mockCredits[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${c.name} (${c.category})',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary)),
                  ),
                  Text(c.amount,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cousine',
                          color: Color(0xFFC62828))),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showCreditsSheet,
            child: const Text('Voir tous les crédits ouverts →',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // ── Trend bar chart — shared mobile/desktop ────────────────────────────

  Widget _buildTrendChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📈 Tendance mobile money',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Spacer(),
              Text('4 sem.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_mockTrendBars.length, (i) {
                final b = _mockTrendBars[i];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: b.factor,
                            child: Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFF0891B2), Color(0xFF0E4F67)],
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(3),
                                  topRight: Radius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(_mockTrendBars.length, (i) {
              return Expanded(
                child: Text(_mockTrendBars[i].label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary)),
              );
            }),
          ),
          const SizedBox(height: 8),
          const Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              children: [
                TextSpan(text: 'Wave + OM passent de '),
                TextSpan(text: '41%', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: ' à '),
                TextSpan(text: '58%', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: ' du CA en 4 semaines. Wave dépasse OM pour la 1re fois.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile insights ────────────────────────────────────────────────────

  Widget _buildMobileInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Text('💡', style: TextStyle(fontSize: 16)),
            SizedBox(width: 6),
            Text('Insights',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            Spacer(),
            _AutoBadge(),
          ],
        ),
        const SizedBox(height: 8),
        // Only 2 insights on mobile — Figma 25:295 / 25:301
        ...List.generate(2, (i) {
          final ins = _mockInsights[i];
          final leftColor = i == 0
              ? const Color(0xFF0891B2)
              : const Color(0xFFC62828);
          final bgColor = i == 0
              ? const Color(0xFFE0F7FA)
              : const Color(0xFFFFEBEE);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border(
                    left: BorderSide(color: leftColor, width: 2.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ins.title,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121))),
                    const SizedBox(height: 4),
                    Text(ins.bodyShort,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575))),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── CTA ────────────────────────────────────────────────────────────────

  Widget _buildCta() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ExportShareScreen())),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        alignment: Alignment.center,
        child: const Text('↗ Exporter & partager',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DESKTOP LAYOUT — Figma 25:663
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktop() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      children: [
        // ── Hero KPI strip ────────────────────────────────
        _buildDesktopHeroStrip(),
        const SizedBox(height: 24),

        // ── Two columns: left (table + credits) | right (donut + trend) ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildDesktopTable(),
                  const SizedBox(height: 24),
                  _buildDesktopCredits(),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right column
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildDesktopDonut(),
                  const SizedBox(height: 24),
                  _buildTrendChart(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Insights full width ──────────────────────────
        _buildDesktopInsights(),
      ],
    );
  }

  // ── Desktop hero KPI strip — Figma 25:670 ──────────────────────────────

  Widget _buildDesktopHeroStrip() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0891B2), Color(0xFF0E4F67)],
        ),
      ),
      child: Row(
        children: [
          // Main KPI
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('💳 TOTAL ENCAISSÉ · SEMAINE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Colors.white70)),
                SizedBox(height: 6),
                Text('2 050 000 F',
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cousine',
                        color: Colors.white)),
                SizedBox(height: 4),
                Text('▲ +12% vs sem. dernière (1 830 000 F)',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70)),
              ],
            ),
          ),
          Container(width: 0.8, height: 60, color: Colors.white30),
          const SizedBox(width: 24),
          // Sub KPIs
          _desktopKpiCol('MOBILE MONEY', '58%', '1 189 000 F · Wave + OM'),
          Container(width: 0.8, height: 60, color: Colors.white30),
          const SizedBox(width: 24),
          _desktopKpiCol('CASH', '42%', '861 000 F · 52 tickets'),
          Container(width: 0.8, height: 60, color: Colors.white30),
          const SizedBox(width: 24),
          _desktopKpiCol('FRAIS CUMULÉS', '11 380 F', '0,55% du CA mobile'),
        ],
      ),
    );
  }

  Widget _desktopKpiCol(String label, String value, String sub) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cousine',
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70)),
        ],
      ),
    );
  }

  // ── Desktop table — Figma 25:700 ───────────────────────────────────────

  Widget _buildDesktopTable() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Text('Détail par mode de paiement',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Spacer(),
              Text('NET APRÈS FRAIS',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          // Header row
          Container(
            height: 34,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('MODE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cousine',
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary))),
                SizedBox(width: 60, child: Text('TRANS.',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cousine',
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary))),
                SizedBox(width: 100, child: Text('BRUT',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cousine',
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary))),
                SizedBox(width: 80, child: Text('FRAIS',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cousine',
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary))),
                SizedBox(width: 110, child: Text('NET',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cousine',
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary))),
                SizedBox(width: 50, child: Text('PART',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cousine',
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary))),
              ],
            ),
          ),
          // Data rows
          ...List.generate(_mockModes.length, (i) {
            final m = _mockModes[i];
            final isLast = i == _mockModes.length - 1;
            return Container(
              height: 65,
              decoration: BoxDecoration(
                border: !isLast
                    ? const Border(bottom: BorderSide(color: AppColors.border, width: 0.8))
                    : null,
              ),
              child: Row(
                children: [
                  // Mode name + icon
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: m.iconBg,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(m.icon,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        const SizedBox(width: 10),
                        Text(m.name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text('${m.transactions}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Cousine',
                            color: AppColors.textPrimary)),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(m.brut,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Cousine',
                            color: AppColors.textPrimary)),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(m.frais,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Cousine',
                            color: AppColors.textSecondary)),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(m.net,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cousine',
                            color: m.net == 'en attente'
                                ? const Color(0xFF7C3AED)
                                : AppColors.textPrimary)),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(m.part,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Cousine',
                            color: AppColors.textPrimary)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Desktop donut — Figma 25:755 ───────────────────────────────────────

  Widget _buildDesktopDonut() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Text('Répartition',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Spacer(),
              Text('4 MODES',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 160, height: 160,
            child: CustomPaint(
              painter: _DonutPainter(
                values: _mockModes.map((m) => m.partRaw).toList(),
                colors: _donutColors,
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('2 050K F',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cousine',
                            color: AppColors.textPrimary)),
                    Text('Total',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          ...List.generate(_mockModes.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: _donutColors[i],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_mockModes[i].name,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  Text(_mockModes[i].part,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Desktop credits — Figma 25:790 ─────────────────────────────────────

  Widget _buildDesktopCredits() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: const Color(0xFFD8B4FE), width: 0.8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚠ Crédits ouverts',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B21A8))),
              const Spacer(),
              const Text('TOP DÉBITEURS',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Color(0xFF7E22CE))),
            ],
          ),
          const SizedBox(height: 8),
          const Text('418 500 F',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cousine',
                  color: Color(0xFF581C87))),
          const SizedBox(height: 4),
          const Text('8 clients · ancienneté moyenne 12 jours · 3 à relancer',
              style: TextStyle(fontSize: 12, color: Color(0xFF7E22CE))),
          const SizedBox(height: 16),
          // All debtors
          ...List.generate(_mockCredits.length, (i) {
            final c = _mockCredits[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.category.isNotEmpty
                            ? '${c.name} (${c.category})'
                            : c.name,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF581C87))),
                        const SizedBox(height: 2),
                        Text(c.age,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF7E22CE))),
                      ],
                    ),
                  ),
                  Text(c.amount,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cousine',
                          color: Color(0xFF6B21A8))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Desktop insights — Figma 25:850 ────────────────────────────────────

  Widget _buildDesktopInsights() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text('Insights automatiques',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121))),
              Spacer(),
              _AutoBadge(),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: List.generate(_mockInsights.length, (i) {
              final ins = _mockInsights[i];
              final leftColors = [
                const Color(0xFF0891B2),
                const Color(0xFFC62828),
                const Color(0xFFF9A825),
              ];
              final bgColors = [
                const Color(0xFFE0F7FA),
                const Color(0xFFFFEBEE),
                const Color(0xFFFFF8E1),
              ];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: i < _mockInsights.length - 1 ? 12 : 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bgColors[i],
                        border: Border(
                          left: BorderSide(
                              color: leftColors[i], width: 4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ins.title,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF212121))),
                          const SizedBox(height: 4),
                          Text(ins.body,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF757575))),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EMPTY STATES — Figma 25:9 (mobile) / 25:663 right (desktop)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMobileEmpty() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _buildMobilePeriodCard(),
        const SizedBox(height: 32),
        _buildEmptyContent(),
      ],
    );
  }

  Widget _buildDesktopEmpty() {
    return Center(
      child: Container(
        width: 540,
        margin: const EdgeInsets.symmetric(vertical: 64),
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: _buildEmptyContent(),
      ),
    );
  }

  Widget _buildEmptyContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('💳', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        const Text('Aucun encaissement sur la période',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        const Text(
            'Configure les modes de paiement (Wave, Orange Money…) et enregistre ta première vente pour suivre la répartition des encaissements.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: const Text('+ Configurer les paiements',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FILTER SHEET — Figma 25:508 left
  // ══════════════════════════════════════════════════════════════════════════

  void _showFilterSheet() {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final content = _FilterStatusSheet(
      selectedIndex: _filterIndex,
      onSelect: (i) {
        setState(() => _filterIndex = i);
        Navigator.pop(context);
      },
    );

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 400),
            child: content,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.45,
          maxChildSize: 0.6,
          minChildSize: 0.3,
          builder: (_, sc) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: content,
          ),
        ),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CREDITS SHEET — Figma 25:508 right
  // ══════════════════════════════════════════════════════════════════════════

  void _showCreditsSheet() {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    const content = _CreditsSheet();

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
            child: content,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          builder: (_, sc) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: content,
          ),
        ),
      );
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Donut chart painter
// ══════════════════════════════════════════════════════════════════════════════

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _DonutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 20.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    double startAngle = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.values != values || old.colors != colors;
}

// ══════════════════════════════════════════════════════════════════════════════
// Auto badge
// ══════════════════════════════════════════════════════════════════════════════

class _AutoBadge extends StatelessWidget {
  const _AutoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text('Auto',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1565C0))),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Filter status sheet — Figma 25:508 left
// ══════════════════════════════════════════════════════════════════════════════

class _FilterStatusSheet extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _FilterStatusSheet({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Filtrer par statut',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        ...List.generate(_mockFilters.length, (i) {
          final f = _mockFilters[i];
          final isSelected = selectedIndex == i;
          final iconColors = [
            AppColors.primary,
            const Color(0xFF2E7D32),
            const Color(0xFFB27A00),
            const Color(0xFFC62828),
          ];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE3F2FD) : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.6 : 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(f.icon,
                          style: TextStyle(
                              fontSize: 18,
                              color: iconColors[i])),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.label,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text(f.detail,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.check, size: 14, color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Credits detail sheet — Figma 25:508 right
// ══════════════════════════════════════════════════════════════════════════════

class _CreditsSheet extends StatelessWidget {
  const _CreditsSheet();

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Container(
            width: 48, height: 5,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Crédits ouverts · 8 clients',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        const Text('418 500 F',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cousine',
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('Ancienneté moyenne : 12 jours',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        ...List.generate(_mockCredits.length, (i) {
          final c = _mockCredits[i];
          final isLast = i == _mockCredits.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: !isLast
                  ? const Border(bottom: BorderSide(color: AppColors.border, width: 0.8))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE7F6),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(c.initial,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5E35B1))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(c.category.isNotEmpty
                          ? '${c.category} · ${c.ageShort} d\'ancienneté'
                          : 'Cumul ${c.amount}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Text(c.amount,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cousine',
                        color: Color(0xFFC62828))),
              ],
            ),
          );
        }),
      ],
    );
  }
}
