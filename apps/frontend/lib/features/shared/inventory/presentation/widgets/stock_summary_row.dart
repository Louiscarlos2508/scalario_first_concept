import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class StockSummaryRow extends StatelessWidget {
  final int totalCount;
  final int lowStockCount;
  final int expiringCount;
  final String? activeFilter;
  final VoidCallback onTapLowStock;
  final VoidCallback onTapExpiring;

  const StockSummaryRow({
    super.key,
    required this.totalCount,
    required this.lowStockCount,
    required this.expiringCount,
    required this.activeFilter,
    required this.onTapLowStock,
    required this.onTapExpiring,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: StockStatCard(
              icon: Icons.inventory_2_outlined,
              count: totalCount,
              label: 'produits',
              color: AppColors.primary,
              isActive: activeFilter == null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StockStatCard(
              icon: Icons.warning_amber_rounded,
              count: lowStockCount,
              label: 'stock bas',
              color: lowStockCount > 0
                  ? AppColors.warning
                  : AppColors.textSecondary,
              isActive: activeFilter == 'low_stock',
              onTap: onTapLowStock,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StockStatCard(
              icon: Icons.eco_outlined,
              count: expiringCount,
              label: 'expirent',
              color: expiringCount > 0
                  ? AppColors.error
                  : AppColors.textSecondary,
              onTap: onTapExpiring,
            ),
          ),
        ],
      ),
    );
  }
}

class StockStatCard extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback? onTap;

  const StockStatCard({
    super.key,
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.35),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
