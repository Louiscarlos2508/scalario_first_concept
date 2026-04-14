import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/internal_orders/data/internal_order.dart';
import 'package:frontend/features/shared/internal_orders/presentation/widgets/internal_order_card.dart'
    show formatAmount;

/// KPI mini-cards — 3 cards en row (mobile) ou 4 cards (desktop).
class InternalOrderKpiRow extends StatelessWidget {
  final List<InternalOrder> allOrders;

  const InternalOrderKpiRow({super.key, required this.allOrders});

  @override
  Widget build(BuildContext context) {
    final toValidate = allOrders.where((o) => o.status == OrderStatus.toValidate).length;
    final inProgress = allOrders.where((o) => o.status == OrderStatus.inProgress).length;
    final validated = allOrders.where((o) => o.status == OrderStatus.validated).length;
    final refused = allOrders.where((o) => o.status == OrderStatus.refused).length;
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    final cards = [
      _KpiCard(
        count: toValidate,
        label: 'À VALIDER PAR TOI',
        sublabel: toValidate > 0 ? _toValidateSublabel() : null,
        isHighlighted: toValidate > 0,
      ),
      _KpiCard(count: inProgress, label: 'EN COURS',
          sublabel: 'en attente gérante / commercial'),
      _KpiCard(count: validated, label: 'VALIDÉES · SEM.',
          sublabel: '▲ +18% vs sem. dernière'),
      if (isWide)
        _KpiCard(count: refused, label: 'REFUSÉES · SEM.',
            sublabel: '— hors budget · stock OK'),
    ];

    if (isWide) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
        child: Row(
          children: cards
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: c,
                    ),
                  ))
              .toList(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i < cards.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  String _toValidateSublabel() {
    final pending = allOrders.where((o) => o.status == OrderStatus.toValidate).toList();
    final urgentCount = pending.where((o) => o.urgency == OrderUrgency.urgent).length;
    final total = pending.fold<double>(0, (s, o) => s + o.estimatedAmount);
    final buf = StringBuffer();
    if (urgentCount > 0) buf.write('dont $urgentCount urgent · ');
    buf.write('~ ${formatAmount(total)} F');
    return buf.toString();
  }
}

class _KpiCard extends StatelessWidget {
  final int count;
  final String label;
  final String? sublabel;
  final bool isHighlighted;

  const _KpiCard({
    required this.count,
    required this.label,
    this.sublabel,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isHighlighted
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
              )
            : null,
        color: isHighlighted ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isHighlighted ? const Color(0xFFFFE082) : AppColors.border,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? const Color(0xFFE65100) : AppColors.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(letterSpacing: 0.5, fontWeight: FontWeight.w600)),
          if (sublabel != null) ...[
            const SizedBox(height: 4),
            Text(
              sublabel!,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
