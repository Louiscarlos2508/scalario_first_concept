import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/internal_orders/data/internal_order.dart';
import 'package:frontend/features/shared/internal_orders/presentation/widgets/internal_order_card.dart'
    show formatAmount;
import 'package:frontend/features/shared/internal_orders/presentation/screens/photo_viewer_screen.dart';
import 'package:frontend/features/shared/internal_orders/presentation/widgets/internal_order_confirm_sheet.dart';

/// Écran détail d'une commande interne — mobile + desktop.
/// Écran détail d'une commande interne — mobile + desktop.
/// En desktop inline, le retour se fait via le breadcrumb du shell.
class InternalOrderDetailScreen extends StatelessWidget {
  final InternalOrder order;
  const InternalOrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    return isDesktop
        ? _DesktopDetail(order: order)
        : _MobileDetail(order: order);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════════════════

class _MobileDetail extends StatelessWidget {
  final InternalOrder order;
  const _MobileDetail({required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appbar,
        foregroundColor: Colors.white,
        title: Text(order.id,
            style: const TextStyle(
                fontFamily: 'Cousine',
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Text('\u22EE',
                style: TextStyle(fontSize: 20, color: Colors.white)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _MobileHeaderCard(order: order),
                  _MobileInfoCard(order: order),
                  _MobileProductsList(order: order),
                  if (order.commercialNote != null)
                    _CommercialNoteCard(order: order),
                  _WorkflowCard(order: order),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          if (order.isMyTurn) _MobileActionBar(order: order),
        ],
      ),
    );
  }
}

/// Blue gradient header — mobile.
class _MobileHeaderCard extends StatelessWidget {
  final InternalOrder order;
  const _MobileHeaderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final currentStep =
        order.steps.where((s) => s.state == WfStepState.current).firstOrNull;
    final stepLabel = currentStep != null
        ? 'étape ${currentStep.stepNumber}/${order.steps.length}'
        : '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (order.isMyTurn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'À valider par toi · $stepLabel',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          if (order.isMyTurn) const SizedBox(height: 8),
          Text(
            '${order.title} · ${order.productCount} produits',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _HeaderMiniField(
                  label: 'Estimé',
                  value: '${formatAmount(order.estimatedAmount)} F'),
              const SizedBox(width: 14),
              _HeaderMiniField(
                  label: 'Urgence',
                  value: order.urgency == OrderUrgency.urgent
                      ? 'Urgent'
                      : 'Normale'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMiniField extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderMiniField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.white)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Cousine',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

/// Info card — mobile (Créé par, Date, Boutique, Fournisseur).
class _MobileInfoCard extends StatelessWidget {
  final InternalOrder order;
  const _MobileInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INFORMATIONS',
              style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _InfoField(label: 'Créé par', value: order.commercialName)),
              Expanded(
                  child: _InfoField(
                      label: 'Date',
                      value: _formatDate(order.createdAt))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _InfoField(label: 'Boutique', value: order.shopName)),
              Expanded(
                  child: _InfoField(
                      label: 'Fournisseur', value: order.supplierName)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  const _InfoField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

/// Products list — mobile.
class _MobileProductsList extends StatelessWidget {
  final InternalOrder order;
  const _MobileProductsList({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PRODUITS DEMANDÉS',
                    style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.4)),
                Text('${order.products.length} lignes',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          ...order.products.map((p) => _MobileProductRow(product: p)),
          // Totals
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                const Divider(height: 1),
                const SizedBox(height: 12),
                _TotalRow(
                    label: 'Sous-total HT',
                    value: '${formatAmount(order.estimatedAmount)} F',
                    isBold: false),
                const SizedBox(height: 6),
                _TotalRow(
                    label: 'Transport estimé',
                    value: 'inclus',
                    isBold: false),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(color: AppColors.border, width: 0.8)),
                  ),
                  child: _TotalRow(
                    label: 'Total estimé',
                    value: '${formatAmount(order.estimatedAmount)} F',
                    isBold: true,
                    valueColor: AppColors.primary,
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

class _MobileProductRow extends StatelessWidget {
  final OrderProductLine product;
  const _MobileProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: product.emojiBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(product.emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${product.quantity} ${product.unit} × ${formatAmount(product.unitPrice)} F',
                  style: const TextStyle(
                      fontFamily: 'Cousine',
                      fontSize: 11,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text('${formatAmount(product.total)} F',
              style: const TextStyle(
                  fontFamily: 'Cousine',
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;
  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: isBold ? 16 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            )),
        Text(value,
            style: TextStyle(
              fontFamily: 'Cousine',
              fontSize: isBold ? 18 : 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            )),
      ],
    );
  }
}

/// Yellow note card — commercial reason + photos.
class _CommercialNoteCard extends StatelessWidget {
  final InternalOrder order;
  const _CommercialNoteCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: const Color(0xFFFFE082), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('\u26A0', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('MOTIF DU COMMERCIAL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE65100),
                    letterSpacing: 0.4,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${order.commercialNote}"',
            style: const TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '— ${order.commercialName} · ${_formatShort(order.createdAt)}',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          // Photo placeholders — tap to open viewer
          Row(
            children: [
              _PhotoPlaceholder(
                color: const Color(0xFFFFCCBC),
                onTap: () => _openPhotos(context, 0),
              ),
              const SizedBox(width: 6),
              _PhotoPlaceholder(
                color: const Color(0xFFFFAB91),
                onTap: () => _openPhotos(context, 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openPhotos(BuildContext context, int index) {
    final caption = order.commercialNote ?? '';
    openPhotoViewer(
      context,
      photos: [
        PhotoData(color: const Color(0xFFFFCCBC), caption: caption),
        PhotoData(color: const Color(0xFFFFAB91), caption: caption),
      ],
      title: 'Photo rupture stock',
      subtitle:
          '${order.commercialName} \u00B7 ${_formatShort(order.createdAt)}',
      initialIndex: index,
    );
  }

  String _formatShort(DateTime d) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final Color color;
  final VoidCallback? onTap;
  const _PhotoPlaceholder({required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 1.6),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          alignment: Alignment.center,
          child: const Text('\u{1F4F7}', style: TextStyle(fontSize: 30)),
        ),
      ),
    );
  }
}

/// Workflow timeline card — shared mobile + desktop.
class _WorkflowCard extends StatelessWidget {
  final InternalOrder order;
  const _WorkflowCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("WORKFLOW D'APPROBATION",
              style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.4)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: order.workflowHistory
                  .map((e) => _WorkflowTimelineEntry(entry: e))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowTimelineEntry extends StatelessWidget {
  final WorkflowHistoryEntry entry;
  const _WorkflowTimelineEntry({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isCompleted = entry.state == WfStepState.completed;
    final isCurrent = entry.state == WfStepState.current;
    final dotColor = isCompleted
        ? AppColors.success
        : isCurrent
            ? AppColors.primary
            : AppColors.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          Transform.translate(
            offset: const Offset(-20, 2),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.4),
              ),
              alignment: Alignment.center,
              child: isCompleted
                  ? const Text('\u2713',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white))
                  : Text('${entry.stepNumber}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),
          ),
          // Content
          Expanded(
            child: Transform.translate(
              offset: const Offset(-20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(entry.actor,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(entry.timestamp,
                      style: const TextStyle(
                          fontFamily: 'Cousine',
                          fontSize: 10,
                          color: AppColors.textSecondary)),
                  if (entry.comment != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(
                            left: BorderSide(
                                color: AppColors.success, width: 2.4)),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(6),
                          bottomRight: Radius.circular(6),
                        ),
                      ),
                      child: Text('"${entry.comment}"',
                          style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary)),
                    ),
                  ],
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom action bar — mobile.
class _MobileActionBar extends StatelessWidget {
  final InternalOrder order;
  const _MobileActionBar({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
        boxShadow: [
          BoxShadow(color: Color(0x0F000000), blurRadius: 24, offset: Offset(0, -8)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => showInternalOrderConfirmSheet(
                    context, order: order, isRefusal: true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.lg)),
                ),
                child: const Text('\u2715 Refuser',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => showInternalOrderConfirmSheet(
                    context, order: order, isRefusal: false),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.lg)),
                ),
                child: const Text('\u2713 Valider',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DESKTOP
// ═══════════════════════════════════════════════════════════════════════════════

class _DesktopDetail extends StatelessWidget {
  final InternalOrder order;
  const _DesktopDetail({required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.8)),
            ),
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.id,
                          style: const TextStyle(
                              fontFamily: 'Cousine',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('${order.title} ',
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                          if (order.isMyTurn)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.chipActionBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('À VALIDER PAR TOI',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    letterSpacing: 0.4,
                                  )),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: 'Créé par '),
                          TextSpan(
                              text: order.commercialName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(
                              text:
                                  ' · ${_formatDate(order.createdAt)} · ${order.shopName} centre · Fournisseur ${order.supplierName}'),
                        ]),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text('${formatAmount(order.estimatedAmount)} F',
                    style: const TextStyle(
                      fontFamily: 'Cousine',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    )),
              ],
            ),
          ),
          // Two-column content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left — products + commercial note
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        _DesktopProductsTable(order: order),
                        if (order.commercialNote != null) ...[
                          const SizedBox(height: 18),
                          _CommercialNoteCard(order: order),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right — workflow + actions
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        _WorkflowCard(order: order),
                        if (order.isMyTurn) ...[
                          const SizedBox(height: 18),
                          _DesktopActions(order: order),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1].substring(0, 3)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}


/// Desktop products table with PRODUIT / QTÉ / PU / TOTAL columns.
class _DesktopProductsTable extends StatelessWidget {
  final InternalOrder order;
  const _DesktopProductsTable({required this.order});

  static const _headerStyle = TextStyle(
    fontFamily: 'Cousine',
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  @override
  Widget build(BuildContext context) {
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
          Text('PRODUITS DEMANDÉS · ${order.products.length} LIGNES',
              style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.4)),
          const SizedBox(height: 18),
          // Header
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.8)),
            ),
            child: Row(
              children: [
                const Expanded(flex: 5, child: Text('PRODUIT', style: _headerStyle)),
                const Expanded(
                    flex: 2,
                    child:
                        Text('QTÉ', style: _headerStyle, textAlign: TextAlign.right)),
                const Expanded(
                    flex: 2,
                    child:
                        Text('PU', style: _headerStyle, textAlign: TextAlign.right)),
                const Expanded(
                    flex: 2,
                    child: Text('TOTAL',
                        style: _headerStyle, textAlign: TextAlign.right)),
              ],
            ),
          ),
          // Rows
          ...order.products.map((p) => _DesktopProductRow(product: p)),
          // Totals
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              border:
                  Border(top: BorderSide(color: AppColors.border, width: 0.8)),
            ),
            child: Column(
              children: [
                _TotalRow(
                    label: 'Sous-total HT',
                    value: '${formatAmount(order.estimatedAmount)} F',
                    isBold: false),
                const SizedBox(height: 6),
                const _TotalRow(
                    label: 'Transport (inclus)', value: '0 F', isBold: false),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(color: AppColors.border, width: 0.8)),
                  ),
                  child: _TotalRow(
                    label: 'Total estimé',
                    value: '${formatAmount(order.estimatedAmount)} F',
                    isBold: true,
                    valueColor: AppColors.primary,
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

class _DesktopProductRow extends StatelessWidget {
  final OrderProductLine product;
  const _DesktopProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: product.emojiBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child:
                      Text(product.emoji, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Text(product.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('${product.quantity} ${product.unit}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontFamily: 'Cousine',
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text('${formatAmount(product.unitPrice)} F',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontFamily: 'Cousine',
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text('${formatAmount(product.total)} F',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontFamily: 'Cousine',
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

/// Desktop action buttons (right column).
class _DesktopActions extends StatelessWidget {
  final InternalOrder order;
  const _DesktopActions({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: () => showInternalOrderConfirmSheet(context,
                order: order, isRefusal: false),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg)),
              elevation: 4,
              shadowColor: const Color(0x402E7D32),
            ),
            child: const Text('\u2713 Valider la commande',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => showInternalOrderConfirmSheet(context,
                order: order, isRefusal: true),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: 1.6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg)),
            ),
            child: const Text('\u2715 Refuser avec motif',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'Une notification sera envoyée à '),
            TextSpan(
                text: order.commercialName.split(' ').first,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const TextSpan(text: ' et '),
            const TextSpan(
                text: 'Fatim',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const TextSpan(text: ' dès ta décision.'),
          ]),
          textAlign: TextAlign.center,
          style:
              const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
