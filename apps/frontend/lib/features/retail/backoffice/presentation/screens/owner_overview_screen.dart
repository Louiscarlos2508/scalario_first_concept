import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/backoffice/presentation/screens/dashboard_screen.dart'
    show dashboardNavigationProvider;
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart'
    show salesStatsDateRangeProvider;

// ══════════════════════════════════════════════════════════════════════════════
// Owner Overview — Figma 11:2 "01.2 Dashboard Patron"
// ══════════════════════════════════════════════════════════════════════════════

class OwnerOverviewScreen extends ConsumerStatefulWidget {
  const OwnerOverviewScreen({super.key});

  @override
  ConsumerState<OwnerOverviewScreen> createState() =>
      _OwnerOverviewScreenState();
}

class _OwnerOverviewScreenState extends ConsumerState<OwnerOverviewScreen> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final firstName = profile?.fullName?.split(' ').first ?? '';
    final dateRange = ref.watch(salesStatsDateRangeProvider);

    // Period label
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final today = DateTime(now.year, now.month, now.day);
    String periodLabel;
    String periodShort; // for hero / KPI labels (e.g. "hier", "ce mois")
    if (dateRange == null) {
      periodLabel = 'Hier · ${DateFormat("d MMMM", "fr_FR").format(yesterday)}';
      periodShort = 'hier';
    } else {
      periodLabel =
          '${DateFormat("d MMM", "fr_FR").format(dateRange.start)} – ${DateFormat("d MMM", "fr_FR").format(dateRange.end)}';
      // Determine a human-friendly short label
      final s = dateRange.start;
      final e = dateRange.end;
      if (s == yesterday && e == yesterday) {
        periodShort = 'hier';
      } else if (s == today && e == today) {
        periodShort = "aujourd'hui";
      } else if (s == today.subtract(const Duration(days: 6)) && e == today) {
        periodShort = '7 derniers jours';
      } else if (s == DateTime(now.year, now.month, 1) && e == today) {
        periodShort = 'ce mois';
      } else if (s == DateTime(now.year, now.month - 1, 1) &&
          e == DateTime(now.year, now.month, 0)) {
        periodShort = 'mois dernier';
      } else {
        periodShort = '${DateFormat("d MMM", "fr_FR").format(s)} – ${DateFormat("d MMM", "fr_FR").format(e)}';
      }
    }

    // Mock data — Figma 11:2 values
    const totalRevenue = 425000.0;
    const totalOrders = 32;
    const avgBasket = 13280.0;
    const margin = 119000.0; // 28% du CA
    const totalExpenses = 5200.0;
    const lowStockCount = 4;
    const criticalCount = 1;

    final pad = EdgeInsets.fromLTRB(
      isDesktop ? AppSpacing.xl : AppSpacing.md,
      isDesktop ? AppSpacing.lg : AppSpacing.md,
      isDesktop ? AppSpacing.xl : AppSpacing.md,
      32,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop ? null : const ScalarioAppBar(title: 'Dashboard'),
      body: ListView(
                padding: pad,
                children: [
                  // ── Greeting ────────────────────────────────────
                  _GreetingSection(
                    firstName: firstName,
                    periodLabel: periodLabel,
                    isDesktop: isDesktop,
                    onPeriodTap: () => _showPeriodSheet(context),
                    onReportsTap: () => ref
                        .read(dashboardNavigationProvider.notifier)
                        .state = 'reports',
                  ),
                  SizedBox(height: isDesktop ? 24 : 16),

                  // ── Period selector (mobile) ────────────────────
                  if (!isDesktop) ...[
                    _PeriodSelectorRow(
                      label: periodLabel,
                      onTap: () => _showPeriodSheet(context),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Revenue hero card ───────────────────────────
                  _RevenueHeroCard(
                    revenue: totalRevenue,
                    orderCount: totalOrders,
                    avgBasket: avgBasket,
                    margin: margin,
                    isDesktop: isDesktop,
                    periodShort: periodShort,
                  ),
                  SizedBox(height: isDesktop ? 24 : 20),

                  // ── Action requise ──────────────────────────────
                  _ActionRequiredSection(
                    lowStockCount: lowStockCount,
                    criticalCount: criticalCount,
                    isDesktop: isDesktop,
                    onOrdersTap: () => ref
                        .read(dashboardNavigationProvider.notifier)
                        .state = 'Commandes',
                    onStockTap: () => ref
                        .read(dashboardNavigationProvider.notifier)
                        .state = 'inventory',
                  ),
                  SizedBox(height: isDesktop ? 24 : 20),

                  // ── Vue d'ensemble ──────────────────────────────
                  _VueEnsembleSection(
                    orderCount: totalOrders,
                    stockValue: 2450000,
                    losses: 8500,
                    expenses: totalExpenses,
                    isDesktop: isDesktop,
                    periodShort: periodShort,
                  ),
                  const SizedBox(height: 20),

                  // ── Reports CTA (mobile) ───────────────────────
                  if (!isDesktop)
                    _ReportsCta(
                      onTap: () => ref
                          .read(dashboardNavigationProvider.notifier)
                          .state = 'reports',
                    ),
                ],
              ),
    );
  }

  void _showPeriodSheet(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    final content = _PeriodSelectorSheet(
      currentRange: ref.read(salesStatsDateRangeProvider),
      onSelect: (range) {
        ref.read(salesStatsDateRangeProvider.notifier).state = range;
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
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
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
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, _) => content,
        ),
      );
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Greeting — Figma 11:2 top section
// ══════════════════════════════════════════════════════════════════════════════

class _GreetingSection extends StatelessWidget {
  final String firstName;
  final String periodLabel;
  final bool isDesktop;
  final VoidCallback onPeriodTap;
  final VoidCallback onReportsTap;

  const _GreetingSection({
    required this.firstName,
    required this.periodLabel,
    required this.isDesktop,
    required this.onPeriodTap,
    required this.onReportsTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = isDesktop
        ? DateFormat('d MMMM yyyy', 'fr_FR').format(now)
        : DateFormat('d MMMM', 'fr_FR').format(now);
    final wave = isDesktop ? ' \u{1F44B}' : '';
    final greeting =
        firstName.isEmpty ? 'Bonjour$wave' : 'Bonjour $firstName$wave';
    final subtitle = "Voici l'état de ta boutique · $dateStr";

    if (isDesktop) {
      return Container(
        padding: const EdgeInsets.only(top: 24, bottom: 24),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.8),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Period dropdown
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onPeriodTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 21, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Text('$periodLabel \u25BE',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Reports button
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onReportsTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 21, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary, width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('\u{1F4CA}', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 6),
                      Text('Voir les rapports',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(greeting,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle,
            style:
                const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Period selector row (mobile) — Figma 11:2
// ══════════════════════════════════════════════════════════════════════════════

class _PeriodSelectorRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PeriodSelectorRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Période',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Text('\u203A',
                style: TextStyle(
                    fontSize: 20, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Revenue hero card — Figma 11:2
// ══════════════════════════════════════════════════════════════════════════════

class _RevenueHeroCard extends StatelessWidget {
  final double revenue;
  final int orderCount;
  final double avgBasket;
  final double margin;
  final bool isDesktop;
  final String periodShort;

  const _RevenueHeroCard({
    required this.revenue,
    required this.orderCount,
    required this.avgBasket,
    required this.margin,
    required this.isDesktop,
    required this.periodShort,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) return _buildDesktop();
    return _buildMobile();
  }

  // ── Desktop: blue gradient card, 4 columns — Figma 11:289 ──────────
  Widget _buildDesktop() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment(-0.6, -1),
          end: Alignment(0.6, 1),
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          // Hero metric — CA
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: 0.85,
                  child: Text("CHIFFRE D'AFFAIRES ${periodShort.toUpperCase()}",
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5)),
                ),
                const SizedBox(height: 8),
                Text(_fmtCurrency(revenue),
                        style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cousine',
                            color: Colors.white,
                            height: 1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Opacity(
                  opacity: 0.95,
                  child: Text.rich(TextSpan(children: const [
                    TextSpan(text: '\u25B2 ', style: TextStyle(fontSize: 13, color: Colors.white)),
                    TextSpan(text: '+12%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.trendGreenLight)),
                    TextSpan(text: ' vs avant-hier · 7e meilleur jour du mois', style: TextStyle(fontSize: 13, color: Colors.white)),
                  ])),
                ),
              ],
            ),
          ),
          _verticalDivider(),
          Expanded(
            flex: 2,
            child: _DesktopMetric(
              label: 'VENTES',
              value: '$orderCount',
              valueSize: 24,
              trend: '\u25B2 +5 vs avant-hier',
            ),
          ),
          _verticalDivider(),
          Expanded(
            flex: 2,
            child: _DesktopMetric(
              label: 'PANIER MOYEN',
              value: _fmtCurrency(avgBasket),
              valueSize: 24,
              trend: '\u25B2 +6%',
            ),
          ),
          _verticalDivider(),
          Expanded(
            flex: 2,
            child: _DesktopMetric(
              label: 'MARGE BRUTE',
              value: _fmtCurrency(margin),
              valueSize: 24,
              trend: '28% du CA',
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() => Container(
        width: 0.8,
        height: 89,
        color: Colors.white.withValues(alpha: 0.25),
      );

  // ── Mobile: blue gradient card ────────────────────────────────────
  Widget _buildMobile() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment(-0.6, -1),
          end: Alignment(0.6, 1),
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label — uppercase, small, white 85%
          Opacity(
            opacity: 0.85,
            child: Text(
              "CHIFFRE D'AFFAIRES ${periodShort.toUpperCase()}",
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Hero value — Cousine Bold 32px white
          Text(_fmtCurrency(revenue),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cousine',
                    color: Colors.white,
                  )),
          const SizedBox(height: 10),
          // Trend — mixed: ▲ white, +12% green bold, rest white, 95% opacity
          Opacity(
            opacity: 0.95,
            child: Text.rich(
              TextSpan(children: [
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
                    text: ' vs avant-hier',
                    style: TextStyle(fontSize: 13, color: Colors.white)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          // Separator line — white 20%
          Container(
            height: 0.8,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 15),
          // Sub-metrics — white text
          Row(
            children: [
              _HeroSubMetric(
                  label: 'Ventes',
                  value: '$orderCount'),
              const SizedBox(width: 16),
              _HeroSubMetric(
                  label: 'Panier moy.',
                  value: _fmtShort(avgBasket)),
              const SizedBox(width: 16),
              _HeroSubMetric(
                  label: 'Marge',
                  value: _fmtShort(margin)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Desktop metric column (white card) ──────────────────────────────────────

class _DesktopMetric extends StatelessWidget {
  final String label;
  final String value;
  final double valueSize;
  final String trend;

  const _DesktopMetric({
    required this.label,
    required this.value,
    required this.valueSize,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Column(
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
          const SizedBox(height: 8),
          Text(value,
                  style: TextStyle(
                      fontSize: valueSize,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cousine',
                      color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Opacity(
            opacity: 0.85,
            child: Text(trend,
                style: const TextStyle(
                    fontSize: 11, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Hero sub-metric (mobile, white on blue) ─────────────────────────────────

class _HeroSubMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroSubMetric({required this.label, required this.value});

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
// Action requise — Figma 11:85
// ══════════════════════════════════════════════════════════════════════════════

class _ActionRequiredSection extends StatelessWidget {
  final int lowStockCount;
  final int criticalCount;
  final bool isDesktop;
  final VoidCallback onOrdersTap;
  final VoidCallback onStockTap;

  const _ActionRequiredSection({
    required this.lowStockCount,
    required this.criticalCount,
    required this.isDesktop,
    required this.onOrdersTap,
    required this.onStockTap,
  });

  @override
  Widget build(BuildContext context) {
    final alertCount =
        (lowStockCount > 0 ? 1 : 0) + (criticalCount > 0 ? 1 : 0) + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header — uppercase 11px, "3 ALERTES" in primary blue
        Row(
          children: [
            const Text('ACTION REQUISE',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary)),
            const Spacer(),
            Text('$alertCount ALERTES',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 10),
        // Cards
        if (isDesktop)
          Row(
            children: [
              Expanded(
                  child: _AlertCard(
                emoji: '\u26A1',
                emojiBg: AppColors.chipErrorBg,
                emojiColor: AppColors.error,
                borderColor: AppColors.error,
                title: '1 commande à valider',
                subtitle: "50kg oignons · demandée à 14:32",
                onTap: onOrdersTap,
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _AlertCard(
                emoji: '\u{1F4E6}',
                emojiBg: AppColors.chipWarningBg,
                emojiColor: AppColors.chipWarningText,
                borderColor: AppColors.warning,
                title: '$lowStockCount produits en stock bas',
                subtitle: 'Tomate, lait, savon, riz',
                onTap: onStockTap,
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _AlertCard(
                emoji: '\u26A0',
                emojiBg: AppColors.chipWarningBg,
                emojiColor: AppColors.chipWarningText,
                borderColor: AppColors.warning,
                title: 'Écart caisse : -1 200 F',
                subtitle: 'Justifié : monnaie rendue',
                onTap: () {},
              )),
            ],
          )
        else
          Column(
            children: [
              _AlertCard(
                emoji: '\u26A1',
                emojiBg: AppColors.chipErrorBg,
                emojiColor: AppColors.error,
                borderColor: AppColors.error,
                title: '1 commande à valider',
                subtitle: "50kg oignons · demandée à 14:32",
                onTap: onOrdersTap,
              ),
              const SizedBox(height: 8),
              _AlertCard(
                emoji: '\u{1F4E6}',
                emojiBg: AppColors.chipWarningBg,
                emojiColor: AppColors.chipWarningText,
                borderColor: AppColors.warning,
                title: '$lowStockCount produits en stock bas',
                subtitle: 'Tomate, lait, savon, riz',
                onTap: onStockTap,
              ),
              const SizedBox(height: 8),
              _AlertCard(
                emoji: '\u26A0',
                emojiBg: AppColors.chipWarningBg,
                emojiColor: AppColors.chipWarningText,
                borderColor: AppColors.warning,
                title: 'Écart caisse : -1 200 F',
                subtitle: 'Justifié : monnaie rendue',
                onTap: () {},
              ),
            ],
          ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String emoji;
  final Color emojiBg;
  final Color emojiColor;
  final Color borderColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AlertCard({
    required this.emoji,
    required this.emojiBg,
    required this.emojiColor,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.only(left: 22, right: 19, top: 14, bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: borderColor, width: 4),
              top: BorderSide(color: borderColor, width: 0.8),
              right: BorderSide(color: borderColor, width: 0.8),
              bottom: BorderSide(color: borderColor, width: 0.8),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: emojiBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(emoji,
                    style: TextStyle(fontSize: 20, color: emojiColor)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text('\u203A',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Vue d'ensemble — 4 KPI cards (Figma 11:2)
// ══════════════════════════════════════════════════════════════════════════════

class _VueEnsembleSection extends StatelessWidget {
  final int orderCount;
  final double stockValue;
  final double losses;
  final double expenses;
  final bool isDesktop;
  final String periodShort;

  const _VueEnsembleSection({
    required this.orderCount,
    required this.stockValue,
    required this.losses,
    required this.expenses,
    required this.isDesktop,
    required this.periodShort,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCardData(
        emoji: '\u{1F6D2}',
        value: '$orderCount',
        label: 'Ventes $periodShort',
        trend: '\u25B2 +5 vs avant-hier',
        trendColor: AppColors.success,
      ),
      _KpiCardData(
        emoji: '\u{1F4E6}',
        value: isDesktop ? _fmtCurrency(stockValue) : _fmtShort(stockValue),
        label: isDesktop ? 'Valeur stock totale' : 'Valeur stock',
        trend: '\u25BC -2% (rotation OK)',
        trendColor: AppColors.error,
      ),
      _KpiCardData(
        emoji: '\u26A0',
        value: _fmtCurrency(losses),
        label: 'Pertes $periodShort',
        trend: '\u25BC -15% vs avant-hier',
        trendColor: AppColors.success,
      ),
      _KpiCardData(
        emoji: '\u{1F4B8}',
        value: _fmtCurrency(expenses),
        label: 'Dépenses $periodShort',
        trend: isDesktop ? '+2 dépenses' : '+2 dép.',
        trendColor: AppColors.error,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("VUE D'ENSEMBLE",
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        if (isDesktop)
          Row(
            children: [
              Expanded(child: _KpiCard(data: cards[0])),
              const SizedBox(width: 12),
              Expanded(child: _KpiCard(data: cards[1])),
              const SizedBox(width: 12),
              Expanded(child: _KpiCard(data: cards[2])),
              const SizedBox(width: 12),
              Expanded(child: _KpiCard(data: cards[3])),
            ],
          )
        else
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _KpiCard(data: cards[0])),
                  const SizedBox(width: 12),
                  Expanded(child: _KpiCard(data: cards[1])),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _KpiCard(data: cards[2])),
                  const SizedBox(width: 12),
                  Expanded(child: _KpiCard(data: cards[3])),
                ],
              ),
            ],
          ),
      ],
    );
  }
}

class _KpiCardData {
  final String emoji;
  final String value;
  final String label;
  final String trend;
  final Color trendColor;

  const _KpiCardData({
    required this.emoji,
    required this.value,
    required this.label,
    required this.trend,
    required this.trendColor,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiCardData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.chipActionBg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(data.emoji,
                style: const TextStyle(
                    fontSize: 18, color: AppColors.primary)),
          ),
          const SizedBox(height: 12),
          Text(data.value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cousine',
                  color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(data.label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(data.trend,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: data.trendColor)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Reports CTA (mobile) — Figma 11:2
// ══════════════════════════════════════════════════════════════════════════════

class _ReportsCta extends StatelessWidget {
  final VoidCallback onTap;
  const _ReportsCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.chipActionBg,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              alignment: Alignment.center,
              child:
                  const Text('\u{1F4CA}', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Voir les rapports détaillés',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text('CA, stock, pertes, vendeurs…',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Text('\u203A',
                style:
                    TextStyle(fontSize: 24, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Period selector bottom sheet — Figma 11:2
// ══════════════════════════════════════════════════════════════════════════════

class _PeriodSelectorSheet extends StatefulWidget {
  final DateTimeRange? currentRange;
  final ValueChanged<DateTimeRange?> onSelect;

  const _PeriodSelectorSheet({
    required this.currentRange,
    required this.onSelect,
  });

  @override
  State<_PeriodSelectorSheet> createState() => _PeriodSelectorSheetState();
}

class _PeriodSelectorSheetState extends State<_PeriodSelectorSheet> {
  int _selectedIndex = 1; // Default to "Hier"
  // Custom date range state — stays in-sheet
  bool _showCustomPicker = false;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  Widget build(BuildContext context) {
    if (_showCustomPicker) return _buildCustomPicker(context);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final options = [
      (
        label: "Aujourd'hui",
        sub: '${DateFormat("d MMMM", "fr_FR").format(today)} · en cours',
        range: DateTimeRange(start: today, end: today),
      ),
      (
        label: 'Hier',
        sub: '${DateFormat("d MMMM", "fr_FR").format(yesterday)} · journée complète',
        range: DateTimeRange(start: yesterday, end: yesterday),
      ),
      (
        label: '7 derniers jours',
        sub:
            '${DateFormat("d MMM", "fr_FR").format(today.subtract(const Duration(days: 6)))} → ${DateFormat("d MMM", "fr_FR").format(today)}',
        range: DateTimeRange(
            start: today.subtract(const Duration(days: 6)), end: today),
      ),
      (
        label: 'Ce mois',
        sub:
            '1er → ${DateFormat("d MMMM", "fr_FR").format(today)}',
        range:
            DateTimeRange(start: DateTime(now.year, now.month, 1), end: today),
      ),
      (
        label: 'Mois dernier',
        sub: DateFormat("MMMM yyyy", "fr_FR")
            .format(DateTime(now.year, now.month - 1, 1)),
        range: DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0),
        ),
      ),
    ];

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
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
          // Options — scrollable card list
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...options.asMap().entries.map((e) {
                    final i = e.key;
                    final opt = e.value;
                    final isSelected = i == _selectedIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedIndex = i),
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
                              // Radio circle
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
                  }),
                  // Personnalisé option — chevron instead of radio
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _showCustomPicker = true),
                      child: Container(
                        height: 62,
                        padding: const EdgeInsets.symmetric(horizontal: 17),
                        decoration: BoxDecoration(
                          color: AppColors.sheetBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.border, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Personnalisé',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(height: 2),
                                  Text('Choisir des dates',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            const Text('\u203A',
                                style: TextStyle(
                                    fontSize: 18,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Buttons
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
                        border: Border.all(color: AppColors.border, width: 0.8),
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
                    onTap: () {
                      widget.onSelect(options[_selectedIndex].range);
                    },
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

  // ── In-sheet custom date picker ─────────────────────────────────────
  Widget _buildCustomPicker(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startLabel = _customStart != null
        ? DateFormat('d MMM yyyy', 'fr_FR').format(_customStart!)
        : 'Début';
    final endLabel = _customEnd != null
        ? DateFormat('d MMM yyyy', 'fr_FR').format(_customEnd!)
        : 'Fin';
    final canApply = _customStart != null && _customEnd != null;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
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
          // Header with back button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showCustomPicker = false),
                  child: const Icon(Icons.arrow_back_ios,
                      size: 18, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 8),
                const Text('Période personnalisée',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Sélectionne le début puis la fin',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(height: 12),
          // Selected range display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.chipActionBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary, width: 0.8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(startLabel,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _customStart != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary)),
                  ),
                  const Text(' → ',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                  Expanded(
                    child: Text(endLabel,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _customEnd != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Calendar — stays in-sheet
          Flexible(
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: AppColors.surface,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: CalendarDatePicker(
                initialDate: _customStart ?? today,
                firstDate: DateTime(2020),
                lastDate: today,
                onDateChanged: (date) {
                  setState(() {
                    if (_customStart == null || _customEnd != null) {
                      // First pick or reset
                      _customStart = date;
                      _customEnd = null;
                    } else if (date.isBefore(_customStart!)) {
                      _customStart = date;
                    } else {
                      _customEnd = date;
                    }
                  });
                },
              ),
            ),
          ),
          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showCustomPicker = false),
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 0.8),
                      ),
                      child: const Text('Retour',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: canApply
                        ? () {
                            widget.onSelect(DateTimeRange(
                                start: _customStart!, end: _customEnd!));
                          }
                        : null,
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: canApply
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.4),
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

// ── Helpers ──────────────────────────────────────────────────────────────────

String _fmtCurrency(double v) {
  if (v >= 1000000) return '${NumberFormat("#,##0", "fr_FR").format(v.round())} F';
  if (v >= 1000) return '${NumberFormat("#,##0", "fr_FR").format(v.round())} F';
  return '${v.toStringAsFixed(0)} F';
}

String _fmtShort(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M F';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k F';
  return '${v.toStringAsFixed(0)} F';
}
