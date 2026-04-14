import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/reports/presentation/screens/export_share_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Rapport vendeurs — Figma 24:2 "01.8 Rapport vendeurs"
// Mock data — backend débranché
// ══════════════════════════════════════════════════════════════════════════════

// ── Mock data ────────────────────────────────────────────────────────────────

const _mockVendeurs = [
  (
    rank: 1,
    initial: 'A',
    name: 'Awa Sankara',
    role: 'Vendeur',
    roleBg: Color(0xFFE3F2FD),
    roleColor: Color(0xFF1565C0),
    tickets: 38,
    panier: '16 105 F',
    remise: '2,1%',
    ca: '612 000 F',
    caRaw: 612000,
    delta: '+18%',
    deltaUp: true,
    avatarBorder: Color(0xFFFFCC00),
  ),
  (
    rank: 2,
    initial: 'B',
    name: 'Boubou Tall',
    role: 'Vendeur',
    roleBg: Color(0xFFE3F2FD),
    roleColor: Color(0xFF1565C0),
    tickets: 31,
    panier: '16 064 F',
    remise: '3,4%',
    ca: '498 000 F',
    caRaw: 498000,
    delta: '+7%',
    deltaUp: true,
    avatarBorder: Color(0xFF9CA3AF),
  ),
  (
    rank: 3,
    initial: 'F',
    name: 'Fatim Diop',
    role: 'Caissière',
    roleBg: Color(0xFFE8F5E9),
    roleColor: Color(0xFF34A853),
    tickets: 28,
    panier: '15 750 F',
    remise: '1,8%',
    ca: '441 000 F',
    caRaw: 441000,
    delta: '+3%',
    deltaUp: true,
    avatarBorder: Color(0xFFCD7F32),
  ),
  (
    rank: 4,
    initial: 'M',
    name: 'Moussa Kouma',
    role: 'Vendeur',
    roleBg: Color(0xFFE3F2FD),
    roleColor: Color(0xFF1565C0),
    tickets: 21,
    panier: '15 476 F',
    remise: '4,2%',
    ca: '325 000 F',
    caRaw: 325000,
    delta: '-8%',
    deltaUp: false,
    avatarBorder: null,
  ),
  (
    rank: 5,
    initial: 'S',
    name: 'Salif Bâ',
    role: 'Manager',
    roleBg: Color(0xFFFFF8E1),
    roleColor: Color(0xFFB27A00),
    tickets: 10,
    panier: '17 400 F',
    remise: '5,8%',
    ca: '174 000 F',
    caRaw: 174000,
    delta: '-22%',
    deltaUp: false,
    avatarBorder: null,
  ),
];

const _mockInsights = [
  (
    title: 'Awa explose la semaine',
    body: '+18% vs sem. dernière, panier moyen le plus haut de l\'équipe.',
    borderColor: Color(0xFF2E7D32),
    bgColor: Color(0xFFE8F5E9),
  ),
  (
    title: 'Salif décroche',
    body: '-22% sur 7 jours, seulement 10 tickets émis. À soutenir.',
    borderColor: Color(0xFFF9A825),
    bgColor: Color(0xFFFFF8E1),
  ),
  (
    title: 'Régularité Boubou',
    body: '3e semaine consécutive entre 480K et 520K F.',
    borderColor: Color(0xFF1565C0),
    bgColor: Color(0xFFE3F2FD),
  ),
  (
    title: 'Remise élevée Salif',
    body: '5,8% de remise · supérieur à la moyenne équipe (3,1%)',
    borderColor: Color(0xFFC62828),
    bgColor: Color(0xFFFFEBEE),
  ),
];

// ── Screen ───────────────────────────────────────────────────────────────────

class VendeursReportScreen extends StatefulWidget {
  final String periodLabel;
  final String periodDateRange;
  final VoidCallback onPeriodTap;

  const VendeursReportScreen({
    super.key,
    required this.periodLabel,
    required this.periodDateRange,
    required this.onPeriodTap,
  });

  @override
  State<VendeursReportScreen> createState() => _VendeursReportScreenState();
}

class _VendeursReportScreenState extends State<VendeursReportScreen> {
  // Toggle to false to see empty state
  final bool _hasVendeurs = true;
  int _sortIndex = 0; // 0=CA, 1=Tickets, 2=Panier, 3=Remise, 4=Nom
  int _roleFilter = 0; // 0=Tous, 1=Vendeur, 2=Caissier, 3=Manager

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    if (!_hasVendeurs) {
      return isDesktop ? _buildDesktopEmpty() : _buildMobileEmpty();
    }

    if (isDesktop) return _buildDesktop();
    return _buildMobile();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EMPTY STATE — Figma 24:10 (mobile) / 24:578 (desktop)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMobileEmpty() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _MobilePeriodCard(
          periodLabel: widget.periodLabel,
          periodDateRange: widget.periodDateRange,
          onTap: widget.onPeriodTap,
        ),
        const SizedBox(height: 24),
        _emptyStateCard(
          isDesktop: false,
          body:
              'Tu n\'as encore enregistré aucun membre d\'équipe. Ajoute ton premier vendeur pour suivre ses performances.',
        ),
      ],
    );
  }

  Widget _buildDesktopEmpty() {
    return Center(
      child: _emptyStateCard(
        isDesktop: true,
        body:
            'Ajoute ton premier membre d\'équipe pour commencer à suivre les performances individuelles.',
      ),
    );
  }

  Widget _emptyStateCard({required bool isDesktop, required String body}) {
    return Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 480 : double.infinity),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 48 : 32, vertical: isDesktop ? 56 : 40),
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
          const Text('👥',
              style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('Aucun vendeur actif',
              style: TextStyle(
                  fontSize: isDesktop ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('+ Ajouter un vendeur',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sort / filter labels ────────────────────────────────────────────────

  static const _sortLabels = [
    'CA',
    'Tickets',
    'Panier',
    'Remise',
    'Nom',
  ];
  static const _roleLabels = [
    'Tous rôles',
    'Vendeur',
    'Caissier',
    'Manager',
  ];

  String get _currentRoleLabel => _roleLabels[_roleFilter];
  String get _currentSortLabel => '↕ Tri : ${_sortLabels[_sortIndex]}';

  void _showSortSheet(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final content = _SortSheet(
      selectedIndex: _sortIndex,
      onSelect: (i) {
        setState(() => _sortIndex = i);
        Navigator.pop(context);
      },
    );
    if (isDesktop) {
      _showAsDialog(context, content);
    } else {
      _showAsBottomSheet(context, content);
    }
  }

  void _showRoleFilter(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final content = _RoleFilterSheet(
      selectedIndex: _roleFilter,
      onSelect: (i) {
        setState(() => _roleFilter = i);
        Navigator.pop(context);
      },
    );
    if (isDesktop) {
      _showAsDialog(context, content);
    } else {
      _showAsBottomSheet(context, content);
    }
  }

  void _showAsDialog(BuildContext context, Widget content) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 480),
          child: content,
        ),
      ),
    );
  }

  void _showAsBottomSheet(BuildContext context, Widget content) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.75,
        builder: (_, _) => content,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MOBILE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMobile() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // ── Period selector ────────────────────────────────
        _MobilePeriodCard(
          periodLabel: widget.periodLabel,
          periodDateRange: widget.periodDateRange,
          onTap: widget.onPeriodTap,
        ),
        const SizedBox(height: 16),

        // ── Hero banner ───────────────────────────────────
        const _HeroBanner(isDesktop: false),
        const SizedBox(height: 16),

        // ── Filter chips ──────────────────────────────────
        Row(
          children: [
            GestureDetector(
              onTap: () => _showRoleFilter(context),
              child: _filterChip(_currentRoleLabel, _roleFilter == 0),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showSortSheet(context),
              child: _filterChip(_currentSortLabel, false),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Classement complet ────────────────────────────
        _mobileClassement(),
        const SizedBox(height: 16),

        // ── Insights ──────────────────────────────────────
        _mobileInsights(),
        const SizedBox(height: 16),

        // ── CTA ───────────────────────────────────────────
        _mobileCta(),
      ],
    );
  }

  Widget _filterChip(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.chipActionBg : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? AppColors.primary : AppColors.border,
          width: 0.8,
        ),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? AppColors.primary : AppColors.textPrimary)),
    );
  }

  Widget _mobileClassement() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text('Classement complet',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const Spacer(),
                Text('${_mockVendeurs.length} vendeurs',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Divider(height: 0.8, thickness: 0.8, color: AppColors.border),
          ...List.generate(_mockVendeurs.length, (i) {
            final v = _mockVendeurs[i];
            final isLast = i == _mockVendeurs.length - 1;
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                border: !isLast
                    ? const Border(
                        bottom:
                            BorderSide(color: AppColors.border, width: 0.8))
                    : null,
              ),
              child: Row(
                children: [
                  // Rank
                  SizedBox(
                    width: 24,
                    child: Text(
                      v.rank <= 3
                          ? ['🥇', '🥈', '🥉'][v.rank - 1]
                          : '${v.rank}',
                      style: TextStyle(
                          fontSize: v.rank <= 3 ? 18 : 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.chipActionBg,
                      shape: BoxShape.circle,
                      border: v.avatarBorder != null
                          ? Border.all(color: v.avatarBorder!, width: 2.4)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(v.initial,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ),
                  const SizedBox(width: 12),
                  // Name + role · tickets
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text('${v.role} · ${v.tickets} tickets',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  // CA + delta
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(v.ca,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cousine',
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        '${v.deltaUp ? "▲" : "▼"} ${v.delta}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: v.deltaUp
                                ? AppColors.success
                                : AppColors.error),
                      ),
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

  Widget _mobileInsights() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 14)),
              SizedBox(width: 4),
              Text('Insights',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Spacer(),
              Text('Auto',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          // Mobile: only first 2 insights — Figma 24:220
          ...List.generate(2, (i) {
            final ins = _mockInsights[i];
            // Mobile uses shorter body text
            const mobileBody = [
              '+18% vs sem. dernière, panier moyen le plus haut',
              '-22% sur 7 jours · 10 tickets seulement',
            ];
            return Padding(
              padding: EdgeInsets.only(bottom: i < 1 ? 8 : 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: ins.bgColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border(
                    left: BorderSide(color: ins.borderColor, width: 2.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ins.title,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(mobileBody[i],
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _mobileCta() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExportShareScreen()),
        ),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DESKTOP
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktop() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
      children: [
        // ── Hero banner ───────────────────────────────────
        const _HeroBanner(isDesktop: true),
        const SizedBox(height: 24),

        // ── Two-column: table + insights ──────────────────
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left — classement table
              Expanded(child: _desktopClassement()),
              const SizedBox(width: 24),
              // Right — insights (fixed width)
              SizedBox(width: 340, child: _desktopInsights()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _desktopClassement() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Row(
              children: [
                const Text('Classement complet',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const Spacer(),
                Text('${_mockVendeurs.length} vendeurs',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Divider(height: 0.8, thickness: 0.8, color: AppColors.border),

          // Column headers
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: const Row(
              children: [
                SizedBox(
                    width: 32,
                    child: Text('#',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cousine',
                            letterSpacing: 0.5,
                            color: AppColors.textSecondary))),
                Expanded(
                    flex: 3,
                    child: Text('VENDEUR',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cousine',
                            letterSpacing: 0.5,
                            color: AppColors.textSecondary))),
                SizedBox(
                    width: 80,
                    child: Text('RÔLE',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cousine',
                            letterSpacing: 0.5,
                            color: AppColors.textSecondary))),
                SizedBox(
                    width: 64,
                    child: Text('TICKETS',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cousine',
                            letterSpacing: 0.5,
                            color: AppColors.textSecondary))),
                SizedBox(
                    width: 80,
                    child: Text('PANIER',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cousine',
                            letterSpacing: 0.5,
                            color: AppColors.textSecondary))),
                SizedBox(
                    width: 64,
                    child: Text('REMISE',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cousine',
                            letterSpacing: 0.5,
                            color: AppColors.textSecondary))),
                SizedBox(
                    width: 96,
                    child: Text('CA',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cousine',
                            letterSpacing: 0.5,
                            color: AppColors.textSecondary))),
                SizedBox(
                    width: 56,
                    child: Text('Δ',
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
          const Divider(height: 0.8, thickness: 0.8, color: AppColors.border),

          // Data rows
          ...List.generate(_mockVendeurs.length, (i) {
            final v = _mockVendeurs[i];
            final isLast = i == _mockVendeurs.length - 1;
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
              decoration: BoxDecoration(
                border: !isLast
                    ? const Border(
                        bottom:
                            BorderSide(color: AppColors.border, width: 0.8))
                    : null,
              ),
              child: Row(
                children: [
                  // Rank
                  SizedBox(
                    width: 32,
                    child: Text(
                      v.rank <= 3
                          ? ['🥇', '🥈', '🥉'][v.rank - 1]
                          : '${v.rank}',
                      style: TextStyle(
                          fontSize: v.rank <= 3 ? 16 : 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary),
                    ),
                  ),
                  // Avatar + name
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.chipActionBg,
                            shape: BoxShape.circle,
                            border: v.avatarBorder != null
                                ? Border.all(
                                    color: v.avatarBorder!, width: 2.4)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(v.initial,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(v.name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ),
                      ],
                    ),
                  ),
                  // Role badge
                  SizedBox(
                    width: 80,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: v.roleBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(v.role,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: v.roleColor)),
                    ),
                  ),
                  // Tickets
                  SizedBox(
                    width: 64,
                    child: Text('${v.tickets}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Cousine',
                            color: AppColors.textPrimary)),
                  ),
                  // Panier
                  SizedBox(
                    width: 80,
                    child: Text(v.panier,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Cousine',
                            color: AppColors.textPrimary)),
                  ),
                  // Remise
                  SizedBox(
                    width: 64,
                    child: Text(v.remise,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Cousine',
                            color: AppColors.textPrimary)),
                  ),
                  // CA
                  SizedBox(
                    width: 96,
                    child: Text(v.ca,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cousine',
                            color: AppColors.textPrimary)),
                  ),
                  // Delta
                  SizedBox(
                    width: 56,
                    child: Text(
                      '${v.deltaUp ? "▲" : "▼"} ${v.delta}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: v.deltaUp
                              ? AppColors.success
                              : AppColors.error),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _desktopInsights() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('Insights',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              SizedBox(width: 8),
              Text('Auto',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_mockInsights.length, (i) {
            final ins = _mockInsights[i];
            return Padding(
              padding: EdgeInsets.only(
                  bottom: i < _mockInsights.length - 1 ? 10 : 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: ins.bgColor,
                  borderRadius: BorderRadius.circular(8),
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
                    Text(ins.body,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Hero banner — meilleur vendeur — Figma 24:32
// ══════════════════════════════════════════════════════════════════════════════

class _HeroBanner extends StatelessWidget {
  final bool isDesktop;
  const _HeroBanner({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final best = _mockVendeurs[0];

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF34A853), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF34A853).withValues(alpha: isDesktop ? 0.2 : 0.25),
            blurRadius: isDesktop ? 32 : 24,
            offset: Offset(0, isDesktop ? 12 : 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(isDesktop ? 24.0 : 20.0),
      child: isDesktop ? _desktopLayout(best) : _mobileLayout(best),
    );
  }

  Widget _desktopLayout(dynamic best) {
    return Row(
      children: [
        // Left — avatar + name + CA
        Expanded(
          child: Row(
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFCC00), width: 4),
                ),
                alignment: Alignment.center,
                child: Text(best.initial,
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32))),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🏆 MEILLEUR VENDEUR · SEMAINE',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(best.name,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(best.ca,
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cousine',
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      '▲ +18% vs sem. dernière (518 000 F)',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.95)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Right — sub-KPIs
        Container(
          padding: const EdgeInsets.only(left: 24),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3), width: 0.8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _desktopKpi('VENDEURS ACTIFS', '5',
                  '3 vendeurs · 1 caissier · 1 manager'),
              SizedBox(
                height: 16,
                child: Divider(
                    color: Colors.white.withValues(alpha: 0.3),
                    thickness: 0.8),
              ),
              _desktopKpi(
                  'TICKETS TOTAUX', '128', '▲ +8 vs sem. dernière'),
              SizedBox(
                height: 16,
                child: Divider(
                    color: Colors.white.withValues(alpha: 0.3),
                    thickness: 0.8),
              ),
              _desktopKpi(
                  'PANIER MOYEN ÉQUIPE', '16 015 F', '▲ +4%'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _desktopKpi(String label, String value, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cousine',
                color: Colors.white)),
        const SizedBox(height: 2),
        Text(sub,
            style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _mobileLayout(dynamic best) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        const Text('🏆 MEILLEUR VENDEUR · SEMAINE',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Colors.white)),
        const SizedBox(height: 8),
        Row(
          children: [
            // Avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border:
                    Border.all(color: const Color(0xFFFFCC00), width: 2.4),
              ),
              alignment: Alignment.center,
              child: Text(best.initial,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(best.name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(best.ca,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cousine',
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(
                    '▲ +18% vs sem. dernière (518 000 F)',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.95)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Sub-KPIs strip
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3), width: 0.8),
            ),
          ),
          child: Row(
            children: [
              _mobileKpi('Tickets', '38'),
              _mobileKpiDivider(),
              _mobileKpi('Panier', '16 105 F'),
              _mobileKpiDivider(),
              _mobileKpi('Remise', '2,1%'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobileKpi(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cousine',
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _mobileKpiDivider() {
    return Container(
      width: 0.8,
      height: 28,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Mobile period card — Figma 24:14
// ══════════════════════════════════════════════════════════════════════════════

class _MobilePeriodCard extends StatelessWidget {
  final String periodLabel;
  final String periodDateRange;
  final VoidCallback onTap;

  const _MobilePeriodCard({
    required this.periodLabel,
    required this.periodDateRange,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                  Text('$periodLabel · $periodDateRange',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
            const Text('▾',
                style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Sort sheet — Figma 24:441 "Trier les vendeurs par"
// ══════════════════════════════════════════════════════════════════════════════

class _SortSheet extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _SortSheet({required this.selectedIndex, required this.onSelect});

  static const _options = [
    (icon: '₣', title: 'Chiffre d\'affaires', subtitle: 'Du plus haut au plus bas'),
    (icon: '🎫', title: 'Nombre de tickets', subtitle: 'Volume d\'opérations'),
    (icon: '🛒', title: 'Panier moyen', subtitle: 'Valeur par ticket'),
    (icon: '%', title: 'Taux de remise', subtitle: 'Du plus généreux au plus strict'),
    (icon: 'A', title: 'Nom (A → Z)', subtitle: 'Alphabétique'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      shrinkWrap: true,
      children: [
        const Text('Trier les vendeurs par',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 14),
        ...List.generate(_options.length, (i) {
          final o = _options[i];
          final isSelected = selectedIndex == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.8, vertical: 14),
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
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.chipActionBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(o.icon,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.title,
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
                        _radio(isSelected),
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

  Widget _radio(bool selected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: 1.6,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Role filter sheet — Figma 24:516 "Filtrer par rôle"
// ══════════════════════════════════════════════════════════════════════════════

class _RoleFilterSheet extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _RoleFilterSheet({required this.selectedIndex, required this.onSelect});

  static const _options = [
    (icon: '∗', iconBg: Color(0xFFE3F2FD), iconColor: Color(0xFF1565C0), title: 'Tous rôles', subtitle: '5 actifs · 2 050 000 F'),
    (icon: 'V', iconBg: Color(0xFFE3F2FD), iconColor: Color(0xFF1A73E8), title: 'Vendeur', subtitle: '3 actifs · 1 435 000 F'),
    (icon: 'C', iconBg: Color(0xFFE8F5E9), iconColor: Color(0xFF34A853), title: 'Caissier', subtitle: '1 actif · 441 000 F'),
    (icon: 'M', iconBg: Color(0xFFFFF8E1), iconColor: Color(0xFFB27A00), title: 'Manager', subtitle: '1 actif · 174 000 F'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      shrinkWrap: true,
      children: [
        const Text('Filtrer par rôle',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 14),
        ...List.generate(_options.length, (i) {
          final o = _options[i];
          final isSelected = selectedIndex == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.8, vertical: 14),
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
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: o.iconBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(o.icon,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: o.iconColor)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.title,
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
                      _radio(isSelected),
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

  Widget _radio(bool selected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: 1.6,
        ),
      ),
    );
  }
}
