import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Rapport Pertes — Figma 18:2 "01.6 Rapport pertes"
// Mock data — backend débranché
// ══════════════════════════════════════════════════════════════════════════════

// ── Mock data ────────────────────────────────────────────────────────────────

const _mockTopProduits = [
  (emoji: '🍅', name: 'Tomate fraîche', subtitle: '12 kg · Frotte + expirés', valeur: 22000.0, types: ['frotte', 'expires']),
  (emoji: '🥬', name: 'Salade verte', subtitle: '8 unités · Expirés', valeur: 14500.0, types: ['expires']),
  (emoji: '🥛', name: 'Lait frais 1L', subtitle: '6 unités · Écart inventaire ⚠', valeur: 9000.0, types: ['ecarts']),
  (emoji: '🥖', name: 'Pain artisanal', subtitle: '15 unités · Frotte', valeur: 7500.0, types: ['frotte']),
  (emoji: '🧀', name: 'Fromage local', subtitle: '4 unités · Écart inv. ⚠', valeur: 6000.0, types: ['ecarts']),
];

const _mockVentilation = [
  (label: 'Frotte naturelle', shortLabel: 'Frotte', pct: 45, subtitle: 'périssables', amount: 38000.0, color: Color(0xFFC62828)),
  (label: 'Expirés', shortLabel: 'Expirés', pct: 30, subtitle: 'DLC dépassée', amount: 26000.0, color: Color(0xFFF9A825)),
  (label: 'Écarts inventaire', shortLabel: 'Écarts inv.', pct: 25, subtitle: 'vol probable', amount: 21000.0, color: Color(0xFF9E9E9E)),
];

const _mockTendance = [
  (label: 'Sem. −3 (9-15 mars)', shortLabel: 'S-3', value: 52000.0),
  (label: 'Sem. −2 (16-22 mars)', shortLabel: 'S-2', value: 71000.0),
  (label: 'Sem. −1 (23-29 mars)', shortLabel: 'S-1', value: 92000.0),
  (label: 'Cette semaine', shortLabel: 'Cette sem.', value: 85000.0),
];

// ── Screen ───────────────────────────────────────────────────────────────────

class PertesReportScreen extends StatefulWidget {
  final String periodLabel;
  final String periodDateRange;
  final VoidCallback onPeriodTap;

  const PertesReportScreen({
    super.key,
    required this.periodLabel,
    required this.periodDateRange,
    required this.onPeriodTap,
  });

  @override
  State<PertesReportScreen> createState() => _PertesReportScreenState();
}

class _PertesReportScreenState extends State<PertesReportScreen> {
  String _selectedType = 'Tout';

  // TODO: replace with real provider
  static const _hasData = true;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    if (!_hasData) return _PertesEmptyState(isDesktop: isDesktop);
    if (isDesktop) return _buildDesktop(context);
    return _buildMobile(context);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOBILE — Figma 18:11
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
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(widget.periodLabel,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  const Text('›',
                      style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Hero card (pink/red gradient) ────────────────
        Padding(
          padding: pad,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment(-0.8, -1),
                end: Alignment(0.8, 1),
                colors: [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
              ),
              border: Border.all(color: const Color(0xFFFFCDD2), width: 0.8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PERTES TOTALES SEMAINE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: AppColors.error)),
                SizedBox(height: 8),
                Text('85 000 F',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cousine',
                        color: AppColors.error,
                        height: 1)),
                SizedBox(height: 8),
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: '3,5%',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error)),
                  TextSpan(
                      text: ' du chiffre d\'affaires',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary)),
                ])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Section: Ventilation par type ────────────────
        Padding(
          padding: pad,
          child: const Text('VENTILATION PAR TYPE',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: pad,
          child: const _VentilationCard(isDesktop: false),
        ),
        const SizedBox(height: 20),

        // ── Section: Top produits perdus ─────────────────
        Padding(
          padding: pad,
          child: const Text('TOP PRODUITS PERDUS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: pad,
          child: const _TopProduitsCard(isDesktop: false),
        ),
        const SizedBox(height: 20),

        // ── Section: Tendance ───────────────────────────
        Padding(
          padding: pad,
          child: const Text('TENDANCE 4 DERNIÈRES SEMAINES',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: pad,
          child: const _TendanceCard(isDesktop: false),
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
  // DESKTOP — Figma 18:2 desktop
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktop(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 32),
      children: [
        // ── Filter chips ─────────────────────────────────
        _buildFilterChips(),
        const SizedBox(height: 24),

        // ── KPI cards row ────────────────────────────────
        _buildKpiRow(),
        const SizedBox(height: 24),

        // ── Row: Ventilation + Top produits ──────────────
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(child: _VentilationCard(isDesktop: true)),
              const SizedBox(width: 16),
              const Expanded(child: _TopProduitsCard(isDesktop: true)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Tendance (full width) ───────────────────────
        const _TendanceCard(isDesktop: true),
      ],
    );
  }

  Widget _buildFilterChips() {
    const types = ['Tout', 'Frotte', 'Expirés', 'Écarts inventaire'];

    return Container(
      padding: const EdgeInsets.only(left: 0, bottom: 0),
      child: Row(
        children: [
          const Text('FILTRER PAR TYPE',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          ...types.map((label) {
            final isSelected = _selectedType == label;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedType = label),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.chipActionBg : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: 0.8,
                      ),
                    ),
                    child: Text('● $label',
                        style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.black)),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildKpiRow() {
    // Single card with 3 sections separated by vertical dividers — Figma 18:303
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: const LinearGradient(
          begin: Alignment(-1, -0.8),
          end: Alignment(0, 0.5),
          colors: [Color(0xFFFFEBEE), Color(0xFFFFFFFF)],
          stops: [0.0, 0.5],
        ),
        border: Border.all(color: const Color(0xFFFFCDD2), width: 0.8),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Section 1 — Pertes totales
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('PERTES TOTALES',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: AppColors.error)),
                  SizedBox(height: 8),
                  Text('85 000 F',
                      style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cousine',
                          color: AppColors.error,
                          height: 1)),
                  SizedBox(height: 8),
                  Text('3,5% du chiffre d\'affaires · 7 derniers jours',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            // Divider
            Container(
              width: 0.8,
              color: const Color(0xFFFFCDD2),
              margin: const EdgeInsets.symmetric(horizontal: 24),
            ),
            // Section 2 — vs semaine dernière
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('VS SEMAINE DERNIÈRE',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: AppColors.textSecondary)),
                    SizedBox(height: 6),
                    Text('▼ −8%',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cousine',
                            color: AppColors.success)),
                  ],
                ),
              ),
            ),
            // Divider
            Container(
              width: 0.8,
              color: const Color(0xFFFFCDD2),
              margin: const EdgeInsets.symmetric(horizontal: 24),
            ),
            // Section 3 — Produits impactés
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('PRODUITS IMPACTÉS',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: AppColors.textSecondary)),
                  SizedBox(height: 6),
                  Text('14',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cousine',
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Ventilation par type — donut chart
// Mobile: donut left + simple legend right (name + amount only)
// Desktop: donut left + detailed legend (name, pct, subtitle, amount)
// ══════════════════════════════════════════════════════════════════════════════

class _VentilationCard extends StatelessWidget {
  final bool isDesktop;
  const _VentilationCard({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final donutSize = isDesktop ? 160.0 : 120.0;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            const Row(
              children: [
                Text('Ventilation par type',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Spacer(),
                Text('Détail',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary)),
              ],
            ),
          if (isDesktop) const SizedBox(height: 24),
          // Donut + legend side by side
          Row(
            children: [
              _DonutChart(size: donutSize),
              SizedBox(width: isDesktop ? 32 : 16),
              Expanded(child: _buildLegend()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _mockVentilation.map((v) {
        final amountStr = v.amount >= 1000
            ? '${(v.amount / 1000).round()} 000 F'
            : '${v.amount.round()} F';
        if (isDesktop) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: v.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.label,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 1),
                      Text('${v.pct}% · ${v.subtitle}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Text(amountStr,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cousine',
                        color: AppColors.textPrimary)),
              ],
            ),
          );
        }
        // Mobile: simple row — dot + name + amount
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: v.color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(v.shortLabel,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary)),
              ),
              Text(amountStr,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cousine',
                      color: AppColors.textPrimary)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Donut chart (custom paint) ──────────────────────────────────────────────

class _DonutChart extends StatelessWidget {
  final double size;
  const _DonutChart({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(size >= 140 ? '85 000 F' : '85k',
                  style: TextStyle(
                      fontSize: size >= 140 ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cousine',
                      color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text('TOTAL',
                  style: TextStyle(
                      fontSize: size >= 140 ? 10 : 9,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 18.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    const segments = [
      (pct: 0.45, color: Color(0xFFC62828)), // Frotte — red
      (pct: 0.30, color: Color(0xFFF9A825)), // Expirés — yellow
      (pct: 0.25, color: Color(0xFF9E9E9E)), // Écarts — grey
    ];

    var startAngle = -math.pi / 2;
    for (final seg in segments) {
      final sweep = 2 * math.pi * seg.pct;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
// Top produits perdus — Figma 18:2
// Mobile: card with header + list (4 items), amounts in red
// Desktop: card with header + table (5 items)
// ══════════════════════════════════════════════════════════════════════════════

class _TopProduitsCard extends StatelessWidget {
  final bool isDesktop;
  const _TopProduitsCard({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final count = isDesktop ? _mockTopProduits.length : 4;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row inside card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
            ),
            child: Row(
              children: [
                Text(isDesktop ? 'Top produits perdus' : 'Cette semaine',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const Spacer(),
                Text(isDesktop ? 'Voir tout' : 'TRI ↓',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: AppColors.primary)),
              ],
            ),
          ),
          // Desktop: table headers
          if (isDesktop)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text('Produit',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          letterSpacing: 0.5, color: AppColors.textSecondary))),
                  Expanded(flex: 2, child: Text('Type',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          letterSpacing: 0.5, color: AppColors.textSecondary))),
                  SizedBox(width: 90, child: Text('Valeur',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          letterSpacing: 0.5, color: AppColors.textSecondary))),
                ],
              ),
            ),
          // Product rows
          ...List.generate(count, (i) {
            final p = _mockTopProduits[i];
            if (isDesktop) return _buildDesktopRow(p, i, count);
            return _buildMobileRow(p, i, count);
          }),
        ],
      ),
    );
  }

  Widget _buildMobileRow(
    ({String emoji, String name, String subtitle, double valeur, List<String> types}) p,
    int i, int count,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: i < count - 1
            ? const Border(bottom: BorderSide(color: AppColors.border, width: 0.8))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.chipErrorBg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(p.emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(p.subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(_fmtCurrency(p.valeur),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cousine',
                  color: AppColors.error)),
        ],
      ),
    );
  }

  Widget _buildDesktopRow(
    ({String emoji, String name, String subtitle, double valeur, List<String> types}) p,
    int i, int count,
  ) {
    // Extract type label for desktop
    final typeLabel = p.types.contains('ecarts')
        ? 'Écart inv. ⚠'
        : p.types.contains('expires') && p.types.contains('frotte')
            ? 'Frotte + expirés'
            : p.types.contains('expires')
                ? 'Expirés'
                : 'Frotte';

    Color typeBg() {
      if (p.types.contains('ecarts')) return AppColors.chipActionBg;
      if (p.types.contains('expires')) return AppColors.chipErrorBg;
      return AppColors.chipWarningBg;
    }

    Color typeColor() {
      if (p.types.contains('ecarts')) return const Color(0xFF1565C0);
      if (p.types.contains('expires')) return const Color(0xFFC62828);
      return const Color(0xFFF9A825);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: i < count - 1
            ? const Border(bottom: BorderSide(color: AppColors.border, width: 0.5))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.chipErrorBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(p.emoji, style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(p.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: typeBg(),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(typeLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: typeColor())),
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(_fmtCurrency(p.valeur),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cousine',
                    color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Tendance — 4 dernières semaines (bar chart)
// Mobile: "Évolution" title, bars pink/red, labels 10px
// Desktop: full title, trend badge
// ══════════════════════════════════════════════════════════════════════════════

class _TendanceCard extends StatelessWidget {
  final bool isDesktop;
  const _TendanceCard({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final maxVal = _mockTendance.map((d) => d.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
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
              Text(isDesktop ? 'Tendance — 4 dernières semaines' : 'Évolution',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              const Text('▼ ',
                  style: TextStyle(fontSize: 12, color: AppColors.success)),
              Text(isDesktop ? '−8% vs S−1' : '−8% vs sem. dernière',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 16),
          // Bars
          SizedBox(
            height: isDesktop ? 160 : 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _mockTendance.asMap().entries.map((entry) {
                final i = entry.key;
                final d = entry.value;
                final pct = d.value / maxVal;
                final isLast = i == _mockTendance.length - 1;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FractionallySizedBox(
                      heightFactor: pct.clamp(0.05, 1.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isLast
                              ? AppColors.error
                              : const Color(0xFFFFCDD2),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          // Labels
          Row(
            children: _mockTendance.map((d) {
              return Expanded(
                child: Text(
                    isDesktop ? d.label : d.shortLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Empty state — Figma 18:2 (empty variant)
// ══════════════════════════════════════════════════════════════════════════════

class _PertesEmptyState extends StatelessWidget {
  final bool isDesktop;
  const _PertesEmptyState({required this.isDesktop});

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
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              const Text('AUCUNE PERTE CETTE SEMAINE',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              const Text('0 F',
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cousine',
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              const SizedBox(
                width: 480,
                child: Text(
                  'Bravo ! Aucune frotte enregistrée, aucun produit expiré, aucun écart d\'inventaire cette semaine.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('▼ ', style: TextStyle(fontSize: 12, color: AppColors.success)),
                  Text(
                      isDesktop
                          ? 'Meilleure semaine des 4 dernières'
                          : 'Meilleure semaine du mois',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success)),
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
            color: AppColors.primary,
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

// ── Helpers ──────────────────────────────────────────────────────────────────

String _fmtCurrency(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M F';
  if (v >= 1000) return '${(v / 1000).round()} 000 F';
  return '${v.toStringAsFixed(0)} F';
}
