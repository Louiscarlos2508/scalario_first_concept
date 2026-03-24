import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';

final _fcfa = NumberFormat.currency(
  locale: 'fr_FR',
  symbol: 'FCFA',
  decimalDigits: 0,
);

Product productFromMap(Map<String, dynamic> item) => Product()
  ..remoteId = item['id']?.toString()
  ..name = item['name']?.toString() ?? ''
  ..price = (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0
  ..barcode = item['barcode']?.toString()
  ..categoryId = item['categoryId']?.toString()
  ..minStockLevel = (item['minStockLevel'] is num)
      ? (item['minStockLevel'] as num).toDouble()
      : null
  ..unitType = item['unitType']?.toString() ?? 'piece'
  ..weightUnit = item['weightUnit']?.toString()
  ..expiryDays = item['expiryDays'] as int?
  ..hasVariants = item['hasVariants'] as bool? ?? false
  ..isUnique = item['isUnique'] as bool? ?? false
  ..trackSerialNumbers = item['trackSerialNumbers'] as bool? ?? false
  ..itemType = item['itemType']?.toString() ?? 'product';

class ProductStockCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback? onMenuTap;

  const ProductStockCard({
    super.key,
    required this.item,
    required this.isOwner,
    required this.onTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString() ?? '';
    final price =
        (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0;
    final stock = (item['stockQuantity'] is num)
        ? (item['stockQuantity'] as num).toDouble()
        : 0.0;
    final minStock = (item['minStockLevel'] is num)
        ? (item['minStockLevel'] as num).toDouble()
        : null;
    final unitType = item['unitType']?.toString() ?? 'piece';
    final unit = item['weightUnit']?.toString() ?? unitType;
    final expiryDays = item['expiryDays'] as int?;

    final isRupture = stock <= 0;
    final isLowStock = !isRupture && minStock != null && stock < minStock;
    final couldExpire = expiryDays != null;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    if (isRupture) {
      statusColor = AppColors.error;
      statusIcon = Icons.block;
      statusLabel = 'Rupture';
    } else if (isLowStock) {
      statusColor = AppColors.warning;
      statusIcon = Icons.warning_amber_rounded;
      statusLabel = 'Stock bas';
    } else if (couldExpire) {
      statusColor = Colors.amber.shade700;
      statusIcon = Icons.eco_outlined;
      statusLabel = 'Fraîcheur';
    } else {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_outline;
      statusLabel = 'OK';
    }

    final stockLabel = unitType == 'piece'
        ? stock.toStringAsFixed(stock.truncateToDouble() == stock ? 0 : 1)
        : '${stock.toStringAsFixed(stock.truncateToDouble() == stock ? 0 : 1)} $unit';

    final priceLabel = unitType == 'piece'
        ? _fcfa.format(price)
        : '${_fcfa.format(price)}/$unit';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(
          left: 16,
          right: 4,
          top: 2,
          bottom: 2,
        ),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        title: Text(
          name,
          style: AppTextStyles.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(priceLabel, style: AppTextStyles.bodySmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  stockLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isRupture
                        ? AppColors.error
                        : isLowStock
                            ? AppColors.warning
                            : AppColors.success,
                    fontSize: 13,
                  ),
                ),
                Text(
                  statusLabel,
                  style: TextStyle(fontSize: 11, color: statusColor),
                ),
              ],
            ),
            if (onMenuTap != null)
              SizedBox(
                width: 40,
                child: IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: onMenuTap,
                  padding: EdgeInsets.zero,
                ),
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
