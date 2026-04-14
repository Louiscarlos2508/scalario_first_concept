import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/internal_orders/data/internal_order.dart';
import 'package:frontend/features/shared/internal_orders/presentation/widgets/internal_order_card.dart'
    show formatAmount;

// ── Motifs rapides pour refus ────────────────────────────────────────────────

const _refusalReasons = [
  'Hors budget',
  'Stock OK',
  'Mauvais fournisseur',
  'Trop cher',
  'Reporter',
  'Autre',
];

// ── Entry point ─────────────────────────────────────────────────────────────

/// Affiche la modale de confirmation (valider ou refuser).
/// Desktop → Dialog centré (560px). Mobile → BottomSheet.
Future<bool?> showInternalOrderConfirmSheet(
  BuildContext context, {
  required InternalOrder order,
  required bool isRefusal,
}) {
  final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

  if (isDesktop) {
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.xxl)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _ConfirmContent(order: order, isRefusal: isRefusal),
        ),
      ),
    );
  }

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
    ),
    builder: (_) => _ConfirmContent(order: order, isRefusal: isRefusal),
  );
}

// ── Content ─────────────────────────────────────────────────────────────────

class _ConfirmContent extends StatefulWidget {
  final InternalOrder order;
  final bool isRefusal;

  const _ConfirmContent({required this.order, required this.isRefusal});

  @override
  State<_ConfirmContent> createState() => _ConfirmContentState();
}

class _ConfirmContentState extends State<_ConfirmContent> {
  final _commentController = TextEditingController();
  String? _selectedReason;
  static const _maxChars = 280;

  bool get _isRefusal => widget.isRefusal;
  InternalOrder get _order => widget.order;
  Color get _accentColor =>
      _isRefusal ? AppColors.error : AppColors.success;

  bool get _canSubmit {
    if (_isRefusal) {
      return _selectedReason != null || _commentController.text.isNotEmpty;
    }
    return true;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final hPad = isDesktop ? 36.0 : 20.0;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            hPad, isDesktop ? 36 : 0, hPad, MediaQuery.paddingOf(context).bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button (desktop only)
            if (isDesktop)
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Text('\u2715',
                        style: TextStyle(
                            fontSize: 18, color: AppColors.textSecondary)),
                  ),
                ),
              ),

            // Icon circle
            Container(
              width: isDesktop ? 96 : 80,
              height: isDesktop ? 96 : 80,
              decoration: BoxDecoration(
                color: _accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                _isRefusal ? '\u2715' : '\u2713',
                style: TextStyle(
                    fontSize: isDesktop ? 50 : 42, color: Colors.white),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              _isRefusal
                  ? 'Refuser la commande ?'
                  : 'Valider la commande ?',
              style: TextStyle(
                fontSize: isDesktop ? 24 : 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Subtitle
            Text(
              _isRefusal
                  ? 'Le commercial recevra le motif et pourra ajuster sa demande.'
                  : isDesktop
                      ? 'Cette action est définitive. Le commercial pourra passer à l\'étape réception et le journal d\'audit sera complété.'
                      : 'Cette action est définitive. Le commercial pourra passer à l\'étape réception.',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Order summary card
            _OrderSummaryCard(
                order: _order, isRefusal: _isRefusal, isDesktop: isDesktop),
            const SizedBox(height: 20),

            // Refusal: quick reason chips
            if (_isRefusal) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('MOTIF RAPIDE',
                      style: AppTextStyles.labelSmall.copyWith(
                          fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _refusalReasons.map((r) {
                  final isSelected = _selectedReason == r;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                    onTap: () => setState(() =>
                        _selectedReason = isSelected ? null : r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.error
                            : const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.error
                              : const Color(0xFFFECACA),
                          width: 0.8,
                        ),
                      ),
                      child: Text(r,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                isSelected ? Colors.white : AppColors.error,
                          )),
                    ),
                  ));
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Comment field
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('COMMENTAIRE',
                    style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                Text(
                  _isRefusal ? '\u2605 OBLIGATOIRE' : '(optionnel)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        _isRefusal ? FontWeight.bold : FontWeight.w500,
                    color: _isRefusal
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _commentController,
              maxLines: isDesktop ? 4 : 3,
              maxLength: _maxChars,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.6),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.6),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_commentController.text.length} / $_maxChars',
                  style: const TextStyle(
                      fontFamily: 'Cousine',
                      fontSize: 10,
                      color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notification info
            if (!_isRefusal)
              _NotificationBanner(
                color: const Color(0xFFE3F2FD),
                borderColor: const Color(0xFF90CAF9),
                textColor: const Color(0xFF0D47A1),
                text:
                    'Notification envoyée à : ${_order.commercialName} · Fatim Diop · journal d\'audit',
              ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          vertical: isDesktop ? 18 : 16),
                      side: const BorderSide(
                          color: AppColors.border, width: 0.8),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadii.lg)),
                    ),
                    child: Text(
                        isDesktop ? 'Retour au détail' : 'Retour',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _canSubmit
                        ? () => Navigator.pop(context, true)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          _accentColor.withValues(alpha: 0.4),
                      padding: EdgeInsets.symmetric(
                          vertical: isDesktop ? 18 : 16),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadii.lg)),
                      elevation: 4,
                      shadowColor:
                          _accentColor.withValues(alpha: 0.25),
                    ),
                    child: Text(
                      _isRefusal
                          ? '\u2715 Refuser'
                          : isDesktop
                              ? '\u2713 Confirmer la validation'
                              : '\u2713 Confirmer',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Order summary card ──────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  final InternalOrder order;
  final bool isRefusal;
  final bool isDesktop;

  const _OrderSummaryCard({
    required this.order,
    required this.isRefusal,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(order.id,
              style: const TextStyle(
                  fontFamily: 'Cousine',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            isDesktop
                ? '${order.title} · ${order.productCount} produits · Fournisseur ${order.supplierName}'
                : '${order.title} · ${order.productCount} produits',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold),
          ),
          if (!isRefusal) ...[
            const SizedBox(height: 8),
            _SummaryRow(label: 'Demandé par', value: order.commercialName),
            const SizedBox(height: 4),
            _SummaryRow(label: 'Approuvé par', value: 'Fatim Diop (Gérante)'),
            if (isDesktop) ...[
              const SizedBox(height: 4),
              _SummaryRow(
                  label: 'Date demande',
                  value: _formatDate(order.createdAt)),
            ],
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: AppColors.border,
                      width: 0.8,
                      style: BorderStyle.solid)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total estimé',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                Text('${formatAmount(order.estimatedAmount)} F',
                    style: const TextStyle(
                        fontFamily: 'Cousine',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ],
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
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontFamily: 'Cousine',
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── Notification banner ─────────────────────────────────────────────────────

class _NotificationBanner extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final Color textColor;
  final String text;

  const _NotificationBanner({
    required this.color,
    required this.borderColor,
    required this.textColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        children: [
          const Text('\u{1F514}', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: 'Notification envoyée à : ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: textColor)),
                TextSpan(
                    text: text.replaceFirst('Notification envoyée à : ', ''),
                    style: TextStyle(color: textColor)),
              ]),
              style: const TextStyle(fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
