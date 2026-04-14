import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/internal_orders/data/internal_order.dart';

/// Résultat du filtre retourné par [showInternalOrderFilterSheet].
class InternalOrderFilter {
  final Set<String> commercials;
  final OrderUrgency? urgency;

  const InternalOrderFilter({this.commercials = const {}, this.urgency});

  bool get isActive => commercials.isNotEmpty || urgency != null;
  int get activeCount => (commercials.isNotEmpty ? 1 : 0) + (urgency != null ? 1 : 0);
}

/// Affiche le filtre : Dialog sur desktop (≥ 1024), bottom sheet sur mobile.
Future<InternalOrderFilter?> showInternalOrderFilterSheet(
  BuildContext context, {
  required InternalOrderFilter current,
}) {
  final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

  if (isDesktop) {
    return showDialog<InternalOrderFilter>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.xl)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: _FilterSheetContent(initial: current),
        ),
      ),
    );
  }

  return showModalBottomSheet<InternalOrderFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
    ),
    builder: (_) => _FilterSheetContent(initial: current),
  );
}

class _FilterSheetContent extends StatefulWidget {
  final InternalOrderFilter initial;
  const _FilterSheetContent({required this.initial});

  @override
  State<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends State<_FilterSheetContent> {
  late Set<String> _selectedCommercials;
  OrderUrgency? _urgency;

  @override
  void initState() {
    super.initState();
    _selectedCommercials = {...widget.initial.commercials};
    _urgency = widget.initial.urgency;
  }

  void _reset() => setState(() {
        _selectedCommercials.clear();
        _urgency = null;
      });

  void _apply() => Navigator.pop(
        context,
        InternalOrderFilter(commercials: _selectedCommercials, urgency: _urgency),
      );

  int get _activeCount =>
      (_selectedCommercials.isNotEmpty ? 1 : 0) + (_urgency != null ? 1 : 0);

  int get _urgentCount =>
      mockInternalOrders.where((o) => o.urgency == OrderUrgency.urgent).length;
  int get _normalCount =>
      mockInternalOrders.where((o) => o.urgency == OrderUrgency.normal).length;

  @override
  Widget build(BuildContext context) {
    final commercials = distinctCommercials();

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.paddingOf(context).bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filtrer les commandes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Commerciaux ───────────────────────────────────────
                  Text('COMMERCIAL',
                      style: AppTextStyles.labelSmall.copyWith(
                          letterSpacing: 0.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),

                  // "Tous les commerciaux"
                  _FilterCard(
                    icon: '\u2217',
                    iconBg: _selectedCommercials.isEmpty
                        ? const Color(0xFFE3F2FD)
                        : const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF1565C0),
                    label: 'Tous les commerciaux',
                    sublabel: '${commercials.length} personnes',
                    isSelected: _selectedCommercials.isEmpty,
                    onTap: () => setState(() => _selectedCommercials.clear()),
                  ),
                  const SizedBox(height: 8),

                  // Individual commercials
                  ...commercials.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _FilterCard(
                          icon: c.initial,
                          iconBg: const Color(0xFFE3F2FD),
                          iconColor: const Color(0xFF1565C0),
                          label: c.name,
                          sublabel:
                              '${c.orderCount} commande${c.orderCount > 1 ? 's' : ''}',
                          isSelected:
                              _selectedCommercials.contains(c.name),
                          onTap: () => setState(() {
                            if (_selectedCommercials.contains(c.name)) {
                              _selectedCommercials.remove(c.name);
                            } else {
                              _selectedCommercials.add(c.name);
                            }
                          }),
                        ),
                      )),
                  const SizedBox(height: 16),

                  // ── Urgence ───────────────────────────────────────────
                  Text('URGENCE',
                      style: AppTextStyles.labelSmall.copyWith(
                          letterSpacing: 0.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),

                  _FilterCard(
                    icon: '\u2217',
                    iconBg: const Color(0xFFF1F5F9),
                    iconColor: const Color(0xFF757575),
                    label: 'Toutes urgences',
                    isSelected: _urgency == null,
                    onTap: () => setState(() => _urgency = null),
                  ),
                  const SizedBox(height: 8),
                  _FilterCard(
                    icon: '!',
                    iconBg: const Color(0xFFFFEBEE),
                    iconColor: const Color(0xFFC62828),
                    label: 'Urgent',
                    sublabel:
                        '$_urgentCount commande${_urgentCount > 1 ? 's' : ''}',
                    isSelected: _urgency == OrderUrgency.urgent,
                    onTap: () =>
                        setState(() => _urgency = OrderUrgency.urgent),
                  ),
                  const SizedBox(height: 8),
                  _FilterCard(
                    icon: '~',
                    iconBg: const Color(0xFFF1F5F9),
                    iconColor: const Color(0xFF757575),
                    label: 'Normal',
                    sublabel:
                        '$_normalCount commande${_normalCount > 1 ? 's' : ''}',
                    isSelected: _urgency == OrderUrgency.normal,
                    onTap: () =>
                        setState(() => _urgency = OrderUrgency.normal),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Footer buttons ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: OutlinedButton(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFE0E0E0), width: 0.8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Réinitialiser',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: FilledButton(
                    onPressed: _apply,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                        'Appliquer${_activeCount > 0 ? ' ($_activeCount)' : ''}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
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

// ── Unified filter card (Figma 31:617) ──────────────────────────────────────

class _FilterCard extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String? sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.sublabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF1565C0) : const Color(0xFFE0E0E0),
            width: isSelected ? 1.6 : 0.8,
          ),
        ),
        child: Row(
          children: [
            // Icon circle (32×32, rounded-[16])
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(icon,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: iconColor)),
            ),
            const SizedBox(width: 12),
            // Label + sublabel
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  if (sublabel != null) ...[
                    const SizedBox(height: 2),
                    Text(sublabel!,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF757575))),
                  ],
                ],
              ),
            ),
            // Radio circle (22×22)
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF1565C0) : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1565C0)
                      : const Color(0xFFE0E0E0),
                  width: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
