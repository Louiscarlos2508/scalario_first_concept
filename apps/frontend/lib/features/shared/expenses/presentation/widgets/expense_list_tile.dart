import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/expenses/data/models/expense.dart';

final _fcfa = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

class ExpenseListTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ExpenseListTile({
    super.key,
    required this.expense,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final label = expenseCategoryLabels[expense.category] ?? expense.category;
    final dateStr = DateFormat('dd/MM/yyyy').format(expense.date.toLocal());

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        key: Key('expense_tile_${expense.id}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          child: const Icon(Icons.receipt_long, color: AppColors.error, size: 20),
        ),
        title: Text(
          expense.label,
          style: AppTextStyles.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$label • $dateStr',
          style: AppTextStyles.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _fcfa.format(expense.amount),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              key: Key('expense_edit_${expense.id}'),
              icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
              tooltip: 'Modifier',
              onPressed: onEdit,
            ),
            IconButton(
              key: Key('expense_delete_${expense.id}'),
              icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
              tooltip: 'Supprimer',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
