import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/internal_orders/data/internal_order.dart';
import 'package:frontend/features/shared/internal_orders/presentation/widgets/workflow_stepper.dart';

/// Carte commande interne — vue mobile.
class InternalOrderCard extends StatelessWidget {
  final InternalOrder order;
  final VoidCallback? onTap;

  const InternalOrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isHighlighted = order.isMyTurn;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isHighlighted ? const Color(0xFFF8FBFF) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isHighlighted ? AppColors.primary : AppColors.border,
            width: 0.8,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Container(
            decoration: isHighlighted
                ? const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppColors.primary, width: 4),
                    ),
                  )
                : null,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildTitle(),
                const SizedBox(height: 6),
                _buildCommercialRow(),
                const SizedBox(height: 14),
                WorkflowStepper(steps: order.steps),
                const SizedBox(height: 14),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          order.id,
          style: const TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        InternalOrderStatusBadge(order: order),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      '${order.title} · ${order.productCount} produit${order.productCount > 1 ? 's' : ''}',
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCommercialRow() {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.chipActionBg,
          child: Text(
            order.commercialInitial,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${order.commercialName} · ${order.shopName} · ${formatTimeAgo(order.createdAt)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            order.supplierName,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '~ ${formatAmount(order.estimatedAmount)} F',
          style: const TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Badge statut ────────────────────────────────────────────────────────────

class InternalOrderStatusBadge extends StatelessWidget {
  final InternalOrder order;
  const InternalOrderStatusBadge({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final (String label, Color bg, Color text) = switch (order) {
      InternalOrder(isMyTurn: true) => (
          'À VALIDER PAR TOI',
          AppColors.chipActionBg,
          AppColors.chipActionText,
        ),
      InternalOrder(status: OrderStatus.validated) => (
          'VALIDÉE',
          AppColors.chipSuccessBg,
          AppColors.chipSuccessText,
        ),
      InternalOrder(status: OrderStatus.refused) => (
          'REFUSÉE',
          AppColors.chipErrorBg,
          AppColors.chipErrorText,
        ),
      InternalOrder(urgency: OrderUrgency.urgent) => (
          'URGENT',
          AppColors.chipErrorBg,
          AppColors.chipErrorText,
        ),
      _ => (
          'NORMAL',
          const Color(0xFFF1F5F9),
          AppColors.textSecondary,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: text,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Helpers de formatage ────────────────────────────────────────────────────

String formatTimeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return "à l'instant";
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  return '${dt.day.toString().padLeft(2, '0')} avr ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String formatAmount(double amount) {
  if (amount >= 1000) {
    final str = amount.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(' ');
      buf.write(str[i]);
    }
    return buf.toString();
  }
  return amount.toInt().toString();
}
