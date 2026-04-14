import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/reports/presentation/screens/export_share_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Rapport CA — Figma 20:2 "01.4 Rapport CA"
// Mock data — backend débranché
// ══════════════════════════════════════════════════════════════════════════════

// ── Mock data ────────────────────────────────────────────────────────────────

const _mockDailyCA = [
  (day: 'L', label: 'Lun 30', value: 285000.0, isWeekend: false),
  (day: 'M', label: 'Mar 31', value: 240000.0, isWeekend: false),
  (day: 'M', label: 'Mer 1', value: 320000.0, isWeekend: false),
  (day: 'J', label: 'Jeu 2', value: 295000.0, isWeekend: false),
  (day: 'V', label: 'Ven 3', value: 360000.0, isWeekend: false),
  (day: 'S', label: 'Sam 4', value: 512000.0, isWeekend: true),
  (day: 'D', label: 'Dim 5', value: 438000.0, isWeekend: true),
];

const _mockPayments = [
  (name: 'Cash', pct: 62, amount: 1519000.0, color: AppColors.brandBlue),
  (name: 'Wave', pct: 24, amount: 588000.0, color: AppColors.brandGreen),
  (name: 'Orange Money', pct: 9, amount: 220000.0, color: AppColors.brandYellow),
  (name: 'Crédit', pct: 5, amount: 122000.0, color: AppColors.brandRed),
];

const _mockVendeurs = [
  (initial: 'A', name: 'Awa', sales: 38, avg: 'panier moyen 16 105 F', amount: 612000.0),
  (initial: 'B', name: 'Boubou', sales: 31, avg: 'panier moyen 16 064 F', amount: 498000.0),
  (initial: 'F', name: 'Fatim', sales: 28, avg: 'panier moyen 15 750 F', amount: 441000.0),
  (initial: 'M', name: 'Moussa', sales: 21, avg: 'panier moyen 15 476 F', amount: 325000.0),
  (initial: 'S', name: 'Salif', sales: 10, avg: 'panier moyen 17 400 F', amount: 174000.0),
];

const _mockInsights = [
  (
    title: 'Samedi est ton meilleur jour',
    subtitle: '21% du CA hebdo concentré sur ce jour',
    borderColor: AppColors.success,
    bgColor: AppColors.chipSuccessBg,
  ),
  (
    title: 'Wave en hausse',
    subtitle: '+6 pts vs semaine dernière (24% vs 18%)',
    borderColor: AppColors.primary,
    bgColor: AppColors.chipActionBg,
  ),
  (
    title: 'Crédit à surveiller',
    subtitle: '122 500 F en attente d\'encaissement',
    borderColor: AppColors.warning,
    bgColor: AppColors.chipWarningBg,
  ),
];

// ── Screen ───────────────────────────────────────────────────────────────────

class CaReportScreen extends StatefulWidget {
  final String periodLabel;
  final String periodDateRange;
  final VoidCallback onPeriodTap;

  const CaReportScreen({
    super.key,
    required this.periodLabel,
    required this.periodDateRange,
    required this.onPeriodTap,
  });

  @override
  State<CaReportScreen> createState() => _CaReportScreenState();
}

class _CaReportScreenState extends State<CaReportScreen> {
  String _selectedVendeur = 'Tous vendeurs';
  String _selectedPaiement = 'Tous moyens';

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    if (isDesktop) return _buildDesktop(context);
    return _buildMobile(context);
  }

  // ── Filter sheets ────────────────────────────────────────────────────────

  void _showVendeurFilter(BuildContext context) {
    final options = [
      (initial: '∗', name: 'Tous vendeurs', subtitle: '5 actifs · 2 450 000 F',
       avatarBg: AppColors.chipActionBg, avatarColor: AppColors.primary),
      ..._mockVendeurs.map((v) => (
        initial: v.initial,
        name: v.name,
        subtitle: '${v.sales} ventes · ${_formatAmount(v.amount)}',
        avatarBg: AppColors.chipActionBg,
        avatarColor: AppColors.primary,
      )),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        title: 'Filtrer par vendeur',
        options: options.map((o) => _FilterOption(
          initial: o.initial,
          name: o.name,
          subtitle: o.subtitle,
          avatarBg: o.avatarBg,
          avatarColor: o.avatarColor,
        )).toList(),
        selected: _selectedVendeur,
        onSelect: (name) {
          setState(() => _selectedVendeur = name);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showPaiementFilter(BuildContext context) {
    final options = [
      _FilterOption(initial: '∗', name: 'Tous moyens', subtitle: '2 450 000 F',
          avatarBg: AppColors.chipActionBg, avatarColor: AppColors.primary),
      _FilterOption(initial: '\u{1F4B5}', name: 'Cash', subtitle: '62% · 1 519 000 F',
          avatarBg: AppColors.chipActionBg, avatarColor: AppColors.brandBlue),
      _FilterOption(initial: 'W', name: 'Wave', subtitle: '24% · 588 000 F',
          avatarBg: AppColors.chipSuccessBg, avatarColor: AppColors.brandGreen),
      _FilterOption(initial: 'OM', name: 'Orange Money', subtitle: '9% · 220 500 F',
          avatarBg: AppColors.chipWarningBg, avatarColor: AppColors.chipWarningText),
      _FilterOption(initial: '€', name: 'Crédit', subtitle: '5% · 122 500 F',
          avatarBg: AppColors.chipErrorBg, avatarColor: AppColors.brandRed),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        title: 'Filtrer par mode de paiement',
        options: options,
        selected: _selectedPaiement,
        onSelect: (name) {
          setState(() => _selectedPaiement = name);
          Navigator.pop(context);
        },
      ),
    );
  }

  static String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M F';
    if (amount >= 1000) return '${(amount / 1000).round()} 000 F';
    return '${amount.round()} F';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOBILE — Figma 20:11
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
                        Text('${widget.periodLabel} \u00B7 ${widget.periodDateRange}',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  const Text('\u25BE',
                      style:
                          TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Hero card (blue gradient) ────────────────────
        Padding(
          padding: pad,
          child: _HeroCard(isDesktop: false),
        ),
        const SizedBox(height: 20),

        // ── Filter chips ─────────────────────────────────
        Padding(
          padding: pad,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showVendeurFilter(context),
                child: _FilterChip(
                    label: _selectedVendeur,
                    isSelected: _selectedVendeur != 'Tous vendeurs'),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showPaiementFilter(context),
                child: _FilterChip(
                    label: _selectedPaiement,
                    isSelected: _selectedPaiement != 'Tous moyens'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── CA par jour (bar chart) ──────────────────────
        Padding(
          padding: pad,
          child: _CaBarChartCard(isDesktop: false),
        ),
        const SizedBox(height: 16),

        // ── Modes de paiement ────────────────────────────
        Padding(
          padding: pad,
          child: const _PaymentModesCard(),
        ),
        const SizedBox(height: 16),

        // ── Top vendeurs ─────────────────────────────────
        Padding(
          padding: pad,
          child: const _TopVendeursCard(isDesktop: false),
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
  // DESKTOP — Figma 20:634
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktop(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 32),
      children: [
        // ── Hero card (blue gradient, 4 columns) ─────────
        _HeroCard(isDesktop: true),
        const SizedBox(height: 24),

        // ── Charts row: CA par jour + Modes de paiement ──
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: _CaBarChartCard(isDesktop: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: const _PaymentModesCard(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Bottom row: Top vendeurs + Insights ──────────
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                flex: 3,
                child: _TopVendeursCard(isDesktop: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: const _InsightsCard(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Hero card — blue gradient (Figma 20:11 mobile / 20:634 desktop)
// ══════════════════════════════════════════════════════════════════════════════

class _HeroCard extends StatelessWidget {
  final bool isDesktop;
  const _HeroCard({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 16),
        gradient: const LinearGradient(
          begin: Alignment(-0.6, -1),
          end: Alignment(0.6, 1),
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Opacity(
            opacity: 0.85,
            child: Text(
              'CHIFFRE D\'AFFAIRES \u00B7 7 JOURS',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Value
          const Text('2 450 000 F',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cousine',
                color: Colors.white,
                height: 1,
              )),
          const SizedBox(height: 10),
          // Trend
          Opacity(
            opacity: 0.95,
            child: Text.rich(TextSpan(children: [
              const TextSpan(
                  text: '\u25B2 ',
                  style: TextStyle(fontSize: 13, color: Colors.white)),
              const TextSpan(
                  text: '+12%',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.trendGreenLight)),
              const TextSpan(
                  text: ' vs sem. dernière (2 187 000 F)',
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
                _HeroMetric(label: 'TICKETS', value: '128', sub: '+8 vs sem. dernière'),
                _verticalDivider(),
                _HeroMetric(
                    label: 'PANIER MOYEN', value: '19 140 F', sub: '\u25B2 +6%'),
                _verticalDivider(),
                _HeroMetric(
                    label: 'MEILLEUR JOUR',
                    value: '512 000 F',
                    sub: 'Samedi 4 avril'),
              ],
            )
          else
            Row(
              children: [
                _HeroSub(label: 'Tickets', value: '128'),
                const SizedBox(width: 24),
                _HeroSub(label: 'Panier moyen', value: '19 140 F'),
                const SizedBox(width: 24),
                _HeroSub(label: 'Meilleur jour', value: 'Sam \u00B7 512K'),
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
// CA par jour — bar chart (Figma 20:2)
// ══════════════════════════════════════════════════════════════════════════════

class _CaBarChartCard extends StatelessWidget {
  final bool isDesktop;
  const _CaBarChartCard({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final maxVal =
        _mockDailyCA.map((d) => d.value).reduce((a, b) => a > b ? a : b);

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
              const Text('CA par jour',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(isDesktop ? '30 MARS \u2192 5 AVRIL' : '7 jours',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 24),
          // Bars
          SizedBox(
            height: isDesktop ? 200 : 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _mockDailyCA.map((d) {
                final pct = d.value / maxVal;
                final isBest = d.value == maxVal;
                final shortVal = '${(d.value / 1000).round()}K';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(shortVal,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cousine',
                                color: isBest
                                    ? AppColors.success
                                    : AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: pct.clamp(0.05, 1.0),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: isBest
                                      ? [AppColors.success, const Color(0xFF1B5E20)]
                                      : [AppColors.brandBlue, AppColors.primaryDark],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                            (isDesktop ? d.label : d.day).toUpperCase(),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Modes de paiement — Figma 20:2
// ══════════════════════════════════════════════════════════════════════════════

class _PaymentModesCard extends StatelessWidget {
  const _PaymentModesCard();

  Widget _totalWidget() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('2 450K',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cousine',
                  color: AppColors.textPrimary)),
          SizedBox(height: 2),
          Text('TOTAL F',
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }

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
              Text('Modes de paiement',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              Spacer(),
              Text('Part du CA',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 24),
          _totalWidget(),
          const SizedBox(height: 24),
          // Legend
          ..._mockPayments.map((p) {
            final amountStr = p.amount >= 1000000
                ? '${(p.amount / 1000000).toStringAsFixed(1)}M'
                : '${(p.amount / 1000).round()}K';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: p.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(p.name,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary)),
                  ),
                  Text('${p.pct}% \u00B7 $amountStr',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cousine',
                          color: AppColors.textPrimary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Top vendeurs — Figma 20:2
// ══════════════════════════════════════════════════════════════════════════════

class _TopVendeursCard extends StatelessWidget {
  final bool isDesktop;
  const _TopVendeursCard({required this.isDesktop});

  static const _avatarColors = [
    AppColors.primary,
    AppColors.roleGerant,
    AppColors.roleVendeur,
    AppColors.roleCommercial,
    AppColors.rolePatron,
  ];

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
          Row(
            children: [
              const Text('Top vendeurs',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(isDesktop ? '5 ACTIFS' : 'Top 4',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          // List
          ...List.generate(
            isDesktop ? _mockVendeurs.length : 4,
            (i) {
              final v = _mockVendeurs[i];
              final color = _avatarColors[i % _avatarColors.length];
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: i < (isDesktop ? _mockVendeurs.length : 4) - 1
                      ? const Border(
                          bottom: BorderSide(
                              color: AppColors.border, width: 0.5))
                      : null,
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(v.initial,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ),
                    const SizedBox(width: 12),
                    // Name + sales
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.name,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            isDesktop
                                ? '${v.sales} ventes \u00B7 ${v.avg}'
                                : '${v.sales} ventes',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Amount
                    Text(_fmtCurrency(v.amount),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cousine',
                            color: AppColors.textPrimary)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Insights — Figma 20:634 (desktop only)
// ══════════════════════════════════════════════════════════════════════════════

class _InsightsCard extends StatelessWidget {
  const _InsightsCard();

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
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
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
          ..._mockInsights.map((ins) => Padding(
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
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary)),
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
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportShareScreen())),
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
// Filter bottom sheet — Figma 20:470
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
          // Handle
          const SizedBox(height: 24),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),
          // Title
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
          // Options
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
                    // Avatar
                    Container(
                      width: 32,
                      height: 32,
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
                    // Name + subtitle
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
                    // Radio circle
                    Container(
                      width: 22,
                      height: 22,
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
