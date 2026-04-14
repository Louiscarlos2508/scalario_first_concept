import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/app_logos.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Exporter & partager — Figma 23:2 "01.7 Export & partage"
// Mock data — backend débranché
// ══════════════════════════════════════════════════════════════════════════════

// ── Export step ─────────────────────────────────────────────────────────────

enum _ExportStep { config, generating, preview, sending, success }

// ── Mock data ────────────────────────────────────────────────────────────────

const _mockReports = [
  (icon: '₣', iconBg: Color(0xFFE3F2FD), iconColor: Color(0xFF1565C0), title: 'Chiffre d\'affaires', subtitle: '2 450 000 F · 128 ventes', checked: true),
  (icon: '📦', iconBg: Color(0xFFFFF8E1), iconColor: Color(0xFFB27A00), title: 'Stock', subtitle: '187 réfs · 12 critiques', checked: true),
  (icon: '⚠', iconBg: Color(0xFFFFEBEE), iconColor: Color(0xFFC62828), title: 'Pertes', subtitle: '85 000 F · 24 mvts', checked: true),
  (icon: '👥', iconBg: Color(0xFFE8F5E9), iconColor: Color(0xFF34A853), title: 'Vendeurs', subtitle: '5 actifs', checked: false),
  (icon: '💳', iconBg: Color(0xFFEDE7F6), iconColor: Color(0xFF5E35B1), title: 'Modes de paiement', subtitle: '3 modes', checked: false),
];

const _mockChannelsMobile = [
  (icon: 'W', iconBg: Color(0xFF25D366), title: 'WhatsApp', subtitle: 'Mr Diallo · Comptable'),
  (icon: '@', iconBg: Color(0xFF1A73E8), title: 'Email', subtitle: 'diallo.compta@gmail.com'),
  (icon: '⇩', iconBg: Color(0xFF757575), title: 'Téléchargement', subtitle: 'Enregistrer le PDF'),
  (icon: '🔗', iconBg: Color(0xFF9C27B0), title: 'Copier le lien', subtitle: 'Lien valable 7 jours'),
];

const _mockChannelsDesktop = [
  (icon: 'W', iconBg: Color(0xFF25D366), title: 'WhatsApp · Mr Diallo', subtitle: 'Comptable · +226 70 00 00 00'),
  (icon: '@', iconBg: Color(0xFF1A73E8), title: 'Email', subtitle: 'diallo.compta@gmail.com'),
];

// ── Mobile screen (full-screen push) ────────────────────────────────────────

class ExportShareScreen extends StatefulWidget {
  const ExportShareScreen({super.key});

  @override
  State<ExportShareScreen> createState() => _ExportShareScreenState();
}

class _ExportShareScreenState extends State<ExportShareScreen> {
  final _selectedReports = <int>{0, 1, 2};
  int _selectedFormat = 0;
  int _selectedChannel = 0;
  _ExportStep _step = _ExportStep.config;

  double _genProgress = 0;

  void _onSend() {
    setState(() => _step = _ExportStep.sending);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _step = _ExportStep.success);
    });
  }

  void _onPreview() {
    setState(() {
      _step = _ExportStep.generating;
      _genProgress = 0;
    });
    _animateProgress();
  }

  void _animateProgress() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted || _step != _ExportStep.generating) return;
      final next = _genProgress + 0.04 + (_genProgress > 0.6 ? 0.02 : 0);
      if (next >= 1.0) {
        setState(() => _step = _ExportStep.preview);
      } else {
        setState(() => _genProgress = next);
        _animateProgress();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _ExportStep.success) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: _MobileSuccessView(onClose: () => Navigator.pop(context))),
      );
    }

    if (_step == _ExportStep.preview) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: _buildPreviewView()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header — Figma 23:16 ────────────────────────
            Container(
              color: AppColors.surface,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const SizedBox(
                      width: 40, height: 40,
                      child: Center(
                        child: Text('✕',
                            style: TextStyle(fontSize: 22, color: AppColors.textPrimary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Exporter & partager',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                  ),
                  PopupMenuButton<String>(
                    icon: const Text('⋮',
                        style: TextStyle(fontSize: 20, color: AppColors.textSecondary)),
                    onSelected: (v) {
                      if (v == 'preview') _onPreview();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'preview', child: Text('Aperçu du PDF')),
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 0.8, color: AppColors.border),

            // ── Content ─────────────────────────────────────
            Expanded(
              child: _step == _ExportStep.sending
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 48, height: 48,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFF25D366),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text('Génération du PDF en cours…',
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : _step == _ExportStep.generating
                      ? _buildGeneratingView()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                          children: [
                            _sectionLabel('RAPPORTS À INCLURE'),
                            const SizedBox(height: 10),
                            _buildReportsCard(),
                            const SizedBox(height: 14),

                            _sectionLabel('PÉRIODE'),
                            const SizedBox(height: 10),
                            _buildPeriodCardMobile(),
                            const SizedBox(height: 14),

                            _sectionLabel('FORMAT'),
                            const SizedBox(height: 10),
                            _buildFormatCard(),
                            const SizedBox(height: 14),

                            _sectionLabel('ENVOYER VIA'),
                            const SizedBox(height: 10),
                            ..._buildChannelCards(false),
                          ],
                        ),
            ),

            // ── CTA ─────────────────────────────────────────
            if (_step == _ExportStep.config)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _buildCta(),
              ),
          ],
        ),
      ),
    );
  }

  // ── Generating state — Figma 23:357 ──────────────────────────────────────

  Widget _buildGeneratingView() {
    final percent = (_genProgress * 100).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 48),
              // Spinner ring
              SizedBox(
                width: 64, height: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 4.8,
                  value: _genProgress,
                  color: AppColors.primary,
                  backgroundColor: const Color(0xFFE3F2FD),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Génération du PDF…',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text(
                  'Compilation des rapports CA, Stock et Pertes\nsur 7 jours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: _genProgress,
                  minHeight: 6,
                  color: AppColors.primary,
                  backgroundColor: const Color(0xFFE0E0E0),
                ),
              ),
              const SizedBox(height: 8),
              Text('$percent%',
                  style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'Cousine',
                      color: AppColors.textSecondary)),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  // ── Preview state — Figma 23:207 ─────────────────────────────────────────

  Widget _buildPreviewView() {
    return Column(
      children: [
        // ── Header — ← Aperçu ⋮ ─────────────────────────
        Container(
          color: AppColors.surface,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _step = _ExportStep.config),
                child: const SizedBox(
                  width: 40, height: 40,
                  child: Center(
                    child: Text('←',
                        style: TextStyle(fontSize: 22, color: AppColors.textPrimary)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Aperçu',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
              ),
              const SizedBox(
                width: 40, height: 40,
                child: Center(
                  child: Text('⋮',
                      style: TextStyle(fontSize: 20, color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
        Container(height: 0.8, color: AppColors.border),

        // ── PDF preview in grey surround ─────────────────
        Expanded(
          child: Container(
            color: AppColors.background,
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF9CA3AF),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: const [
                    _PdfPreviewContent(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Reports card ──────────────────────────────────────────────────────────

  Widget _buildReportsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      padding: const EdgeInsets.fromLTRB(14.8, 14.8, 14.8, 0),
      child: Column(
        children: List.generate(_mockReports.length, (i) {
          final r = _mockReports[i];
          final isChecked = _selectedReports.contains(i);
          final isLast = i == _mockReports.length - 1;
          return GestureDetector(
            onTap: () => setState(() {
              isChecked ? _selectedReports.remove(i) : _selectedReports.add(i);
            }),
            child: Container(
              height: i == 0 ? 52.8 : 64.8,
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
                      color: r.iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(r.icon,
                        style: TextStyle(fontSize: 20, color: r.iconColor)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(r.subtitle,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  _checkbox(isChecked),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Period card mobile ────────────────────────────────────────────────────

  Widget _buildPeriodCardMobile() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      padding: const EdgeInsets.fromLTRB(14.8, 14.8, 14.8, 0),
      child: Column(
        children: [
          _periodRow('Période', '7 derniers jours ▾'),
          _periodRow('Du', '30 mars 2026'),
          _periodRow('Au', '5 avril 2026', isLast: true),
        ],
      ),
    );
  }

  // ── Format card ───────────────────────────────────────────────────────────

  Widget _buildFormatCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      padding: const EdgeInsets.fromLTRB(14.8, 14.8, 14.8, 14.8),
      child: _buildFormatTiles(),
    );
  }

  Widget _buildFormatTiles() {
    const formats = [
      (icon: '📄', label: 'PDF'),
      (icon: '🖼', label: 'Image'),
      (icon: '🔗', label: 'Lien'),
    ];

    return Row(
      children: List.generate(formats.length, (i) {
        final f = formats[i];
        final isSelected = _selectedFormat == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < formats.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFormat = i),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  height: 80.8,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE3F2FD) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(f.icon, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(f.label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Channel cards ─────────────────────────────────────────────────────────

  List<Widget> _buildChannelCards(bool isDesktop) {
    final channels = isDesktop ? _mockChannelsDesktop : _mockChannelsMobile;
    return List.generate(channels.length, (i) {
      final c = channels[i];
      final isSelected = _selectedChannel == i;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () => setState(() => _selectedChannel = i),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              height: 73.6,
              padding: const EdgeInsets.symmetric(horizontal: 14.8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE8F5E9) : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(
                  color: isSelected ? const Color(0xFF25D366) : AppColors.border,
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: c.iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(c.icon,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(c.subtitle,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
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
      );
    });
  }

  // ── CTA ───────────────────────────────────────────────────────────────────

  Widget _buildCta() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _onSend,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF25D366),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25D366).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text('📤 Envoyer sur WhatsApp',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: AppColors.textSecondary));
  }

  Widget _periodRow(String label, String value, {bool isLast = false}) {
    return Container(
      height: 41.6,
      decoration: BoxDecoration(
        border: !isLast
            ? const Border(bottom: BorderSide(color: AppColors.border, width: 0.8))
            : null,
      ),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _checkbox(bool checked) {
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        color: checked ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: checked ? AppColors.primary : AppColors.border,
          width: 1.6,
        ),
      ),
      alignment: Alignment.center,
      child: checked
          ? const Text('✓',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white))
          : null,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Desktop content widget — embeddable in ReportsScreen within DashboardShell
// Figma 23:516
// ══════════════════════════════════════════════════════════════════════════════

class ExportShareContent extends StatefulWidget {
  final VoidCallback onClose;
  const ExportShareContent({super.key, required this.onClose});

  @override
  State<ExportShareContent> createState() => _ExportShareContentState();
}

class _ExportShareContentState extends State<ExportShareContent> {
  final _selectedReports = <int>{0, 1, 2};
  int _selectedFormat = 0;
  int _selectedChannel = 0;
  _ExportStep _step = _ExportStep.config;

  void _onSend() {
    setState(() => _step = _ExportStep.sending);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _step = _ExportStep.success);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _ExportStep.success) {
      return _DesktopSuccessView(
        onClose: widget.onClose,
        onResend: () => setState(() => _step = _ExportStep.config),
      );
    }

    return Column(
      children: [
        // ── Page header — Figma 23:563 ──────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Exporter & partager',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        const Text(
                            'Génère un PDF de tes rapports et envoie-le à ton comptable en un clic',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20.8, vertical: 12.8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border, width: 0.8),
                        ),
                        child: const Text('✕ Fermer',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        Container(height: 0.8, color: AppColors.border),

        // ── Two-column content — Figma 23:574 ──────────────
        Expanded(
          child: _step == _ExportStep.sending
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 48, height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFF25D366),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text('Génération du PDF en cours…',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column — config card
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: SizedBox(
                        width: 492,
                        child: _buildLeftCard(),
                      ),
                    ),

                    // Right column — PDF preview
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(0, 32, 32, 32),
                        children: [
                          _buildPdfPreviewPanel(),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ── Left config card — Figma 23:575 ───────────────────────────────────────

  Widget _buildLeftCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Reports ───────────────────────────────────
          _sectionLabel('RAPPORTS À INCLURE'),
          const SizedBox(height: 14),
          ...List.generate(_mockReports.length, (i) {
            final r = _mockReports[i];
            final isChecked = _selectedReports.contains(i);
            final isLast = i == _mockReports.length - 1;
            return GestureDetector(
              onTap: () => setState(() {
                isChecked ? _selectedReports.remove(i) : _selectedReports.add(i);
              }),
              child: Container(
                height: 64.8,
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
                        color: r.iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(r.icon,
                          style: TextStyle(fontSize: 20, color: r.iconColor)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.title,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(r.subtitle,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    _checkbox(isChecked),
                  ],
                ),
              ),
            );
          }),

          // ── Period ────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
            ),
            padding: const EdgeInsets.only(top: 18),
            child: _sectionLabel('PÉRIODE'),
          ),
          const SizedBox(height: 8),
          _desktopPeriodRow('Période', '7 derniers jours ▾'),
          _desktopPeriodRow('Du 30 mars 2026', 'au 5 avril 2026'),

          // ── Format ────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
            ),
            padding: const EdgeInsets.only(top: 18),
            child: _sectionLabel('FORMAT'),
          ),
          const SizedBox(height: 8),
          _buildFormatTiles(),

          // ── Canal d'envoi ─────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
            ),
            padding: const EdgeInsets.only(top: 18),
            child: _sectionLabel('CANAL D\'ENVOI'),
          ),
          const SizedBox(height: 8),
          ..._buildChannelRows(),

          // ── CTA ───────────────────────────────────────
          const SizedBox(height: 16),
          _buildCta(),
        ],
      ),
    );
  }

  // ── Format tiles ──────────────────────────────────────────────────────────

  Widget _buildFormatTiles() {
    const formats = [
      (icon: '📄', label: 'PDF'),
      (icon: '🖼', label: 'Image'),
      (icon: '🔗', label: 'Lien'),
    ];

    return Row(
      children: List.generate(formats.length, (i) {
        final f = formats[i];
        final isSelected = _selectedFormat == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < formats.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFormat = i),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  height: 80.8,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE3F2FD) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(f.icon, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(f.label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Channel rows ──────────────────────────────────────────────────────────

  List<Widget> _buildChannelRows() {
    return List.generate(_mockChannelsDesktop.length, (i) {
      final c = _mockChannelsDesktop[i];
      final isSelected = _selectedChannel == i;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () => setState(() => _selectedChannel = i),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              height: 73.6,
              padding: const EdgeInsets.symmetric(horizontal: 14.8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE8F5E9) : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(
                  color: isSelected ? const Color(0xFF25D366) : AppColors.border,
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: c.iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(c.icon,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(c.subtitle,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
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
      );
    });
  }

  // ── CTA ───────────────────────────────────────────────────────────────────

  Widget _buildCta() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _onSend,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF25D366),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25D366).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text('📤 Envoyer sur WhatsApp',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
      ),
    );
  }

  // ── PDF preview panel — Figma 23:718 ──────────────────────────────────────

  Widget _buildPdfPreviewPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      padding: const EdgeInsets.fromLTRB(24.8, 24.8, 24.8, 0),
      child: Column(
        children: [
          const Row(
            children: [
              Text('Aperçu du PDF',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Spacer(),
              Text('4 PAGES · 248 KO',
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF9CA3AF),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: const _PdfPreviewContent(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: AppColors.textSecondary));
  }

  Widget _desktopPeriodRow(String left, String right) {
    return Container(
      height: 41.6,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(right,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _checkbox(bool checked) {
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        color: checked ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: checked ? AppColors.primary : AppColors.border,
          width: 1.6,
        ),
      ),
      alignment: Alignment.center,
      child: checked
          ? const Text('✓',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white))
          : null,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared PDF preview content — Figma 23:224 / 23:727
// Used by both mobile aperçu and desktop right panel
// ══════════════════════════════════════════════════════════════════════════════

class _PdfPreviewContent extends StatelessWidget {
  const _PdfPreviewContent();

  static const _pdfText = Color(0xFF111111);
  static const _pdfGrey = Color(0xFF6B7280);
  static const _pdfBorder = Color(0xFFE5E7EB);
  static const _pdfKpiBg = Color(0xFFF3F4F6);
  static const _pdfBarColor = Color(0xFF1A73E8);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Report header ──────────────────────────────
        Container(
          padding: const EdgeInsets.only(bottom: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _pdfBorder, width: 1.6)),
          ),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.appbar,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  AppLogos.monogramDark,
                  width: 24, height: 14,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Boutique Ouaga',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _pdfText)),
                    Text('Rapport hebdo · Blandine Ouédraogo',
                        style: TextStyle(fontSize: 9, color: _pdfGrey)),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('5 avril 2026',
                      style: TextStyle(fontSize: 9, color: _pdfGrey)),
                  Text('16:42',
                      style: TextStyle(fontSize: 9, color: _pdfGrey)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Récap exécutif ─────────────────────────────
        const Text('RÉCAP EXÉCUTIF · 30 MARS → 5 AVRIL',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: _pdfGrey)),
        const SizedBox(height: 6),
        Row(
          children: [
            _kpi('2 450K', 'CA semaine'),
            const SizedBox(width: 8),
            _kpi('3 820K', 'Stock'),
            const SizedBox(width: 8),
            _kpi('85K', 'Pertes'),
          ],
        ),
        const SizedBox(height: 12),

        // ── CA bar chart ───────────────────────────────
        const Text('CA PAR JOUR',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: _pdfGrey)),
        const SizedBox(height: 6),
        SizedBox(
          height: 50,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bar(0.55, _pdfBarColor, 'Lun'),
              _bar(0.48, _pdfBarColor, 'Mar'),
              _bar(0.62, _pdfBarColor, 'Mer'),
              _bar(0.58, _pdfBarColor, 'Jeu'),
              _bar(0.70, _pdfBarColor, 'Ven'),
              _bar(1.0, const Color(0xFF34A853), 'Sam'),
              _bar(0.84, _pdfBarColor, 'Dim'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Stock critiques ────────────────────────────
        const Text('STOCK — PRODUITS CRITIQUES',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: _pdfGrey)),
        const SizedBox(height: 6),
        _row('🍅 Tomate fraîche', '3 / 50 kg', true),
        _row('🥬 Salade verte', '8 / 30 u', true),
        _row('🌶 Piment vert', '1,5 / 20 kg', false),
        const SizedBox(height: 12),

        // ── Pertes top 3 ───────────────────────────────
        const Text('PERTES — TOP 3',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: _pdfGrey)),
        const SizedBox(height: 6),
        _row('🍅 Tomate (frotte)', '32 000 F', true),
        _row('🥬 Salade (expirée)', '24 500 F', true),
        _row('🥒 Concombre (écart)', '14 000 F', false),
        const SizedBox(height: 12),
        Container(height: 0.8, color: _pdfBorder),
        const SizedBox(height: 10),

        // ── Footer ─────────────────────────────────────
        const Center(
          child: Text(
              'Généré par Scalario · scalario.app · Boutique Ouaga · Blandine Ouédraogo',
              style: TextStyle(fontSize: 8, color: _pdfGrey)),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  static Widget _kpi(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: _pdfKpiBg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cousine',
                    color: _pdfText)),
            const SizedBox(height: 1),
            Text(label,
                style: const TextStyle(fontSize: 8, color: _pdfGrey)),
          ],
        ),
      ),
    );
  }

  static Widget _bar(double factor, Color color, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: FractionallySizedBox(
                heightFactor: factor,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(fontSize: 8, color: _pdfGrey)),
          ],
        ),
      ),
    );
  }

  static Widget _row(String text, String value, bool hasBorder) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: hasBorder
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: _pdfBorder, width: 0.8)),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 10, color: _pdfText)),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cousine',
                  color: _pdfText)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Success view — shared card widget — Figma 23:931
// ══════════════════════════════════════════════════════════════════════════════

class _SuccessRecapCard extends StatelessWidget {
  const _SuccessRecapCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22.8, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: const Color(0xFFC8E6C9), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF25D366),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('W',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mr Diallo · Comptable',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                SizedBox(height: 2),
                Text('Rapport-Ouaga-7j.pdf · 248 Ko · à l\'instant',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Text('✓✓',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32))),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Desktop success view — Figma 23:870
// ══════════════════════════════════════════════════════════════════════════════

class _DesktopSuccessView extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onResend;
  const _DesktopSuccessView({required this.onClose, required this.onResend});

  @override
  State<_DesktopSuccessView> createState() => _DesktopSuccessViewState();
}

class _DesktopSuccessViewState extends State<_DesktopSuccessView> {
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_countdown <= 1) {
        widget.onClose();
      } else {
        setState(() => _countdown--);
        _tick();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Page header ───────────────────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Exporter & partager',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        SizedBox(height: 4),
                        Text(
                            'Génère un PDF de tes rapports et envoie-le à ton comptable en un clic',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20.8, vertical: 12.8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border, width: 0.8),
                        ),
                        child: const Text('✕ Fermer',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        Container(height: 0.8, color: AppColors.border),

        // ── Success content — gradient bg ─────────────────
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Color(0xFFE8F5E9), Colors.white],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 80),
                // ── Green check circle ────────────────────
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text('✓',
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                const SizedBox(height: 24),

                // ── Title ─────────────────────────────────
                const Text('Rapport partagé avec succès',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),

                // ── Subtitle ──────────────────────────────
                const Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                    children: [
                      TextSpan(text: 'Ton rapport hebdomadaire est en route vers '),
                      TextSpan(
                          text: 'Mr Diallo',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: ' sur WhatsApp.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // ── Recap card ────────────────────────────
                const SizedBox(
                  width: 372,
                  child: _SuccessRecapCard(),
                ),
                const SizedBox(height: 32),

                // ── Action buttons ────────────────────────
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: widget.onClose,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20.8, vertical: 12.8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border, width: 0.8),
                          ),
                          child: const Text('⌂ Retour au tableau de bord',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: widget.onResend,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20.8, vertical: 12.8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border, width: 0.8),
                          ),
                          child: const Text('↗ Renvoyer à un autre contact',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Countdown ─────────────────────────────
                Text('Retour automatique dans $_countdown secondes…',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Mobile success view — Figma 23:386
// ══════════════════════════════════════════════════════════════════════════════

class _MobileSuccessView extends StatefulWidget {
  final VoidCallback onClose;
  const _MobileSuccessView({required this.onClose});

  @override
  State<_MobileSuccessView> createState() => _MobileSuccessViewState();
}

class _MobileSuccessViewState extends State<_MobileSuccessView> {
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_countdown <= 1) {
        widget.onClose();
      } else {
        setState(() => _countdown--);
        _tick();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [Color(0xFFE8F5E9), Colors.white],
        ),
      ),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // ── Green check circle ────────────────────────
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text('✓',
                style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          const SizedBox(height: 20),

          // ── Title ──────────────────────────────────────
          const Text('Rapport partagé !',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),

          // ── Subtitle ───────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                children: [
                  TextSpan(text: 'Ton rapport hebdomadaire est en route vers '),
                  TextSpan(
                      text: 'Mr Diallo',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // ── Recap card ─────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: _SuccessRecapCard(),
          ),
          const Spacer(flex: 2),

          // ── Countdown ──────────────────────────────────
          Text('Retour au tableau de bord dans $_countdown secondes…',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
