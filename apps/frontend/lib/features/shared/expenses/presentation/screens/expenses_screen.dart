import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/expenses/data/models/expense.dart';
import 'package:frontend/features/shared/expenses/presentation/providers/expense_providers.dart';
import 'package:frontend/features/shared/expenses/presentation/widgets/expense_form.dart';
import 'package:frontend/features/shared/expenses/presentation/widgets/expense_list_tile.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: ScalarioAppBar(
        title: 'Dépenses',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(expensesProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('expense_fab'),
        heroTag: null,
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Erreur : $err', style: const TextStyle(color: AppColors.error)),
        ),
        data: (expenses) {
          if (expenses.isEmpty) {
            return const Center(
              key: Key('expenses_empty_state'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long, size: 48, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text(
                    'Aucune dépense enregistrée',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return ExpenseListTile(
                expense: expense,
                onEdit: () => _openForm(context, existing: expense),
                onDelete: () => _confirmDelete(context, ref, expense.id),
              );
            },
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, {Expense? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ExpenseForm(existing: existing),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la dépense ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            key: const Key('confirm_delete_button'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _doDelete(context, ref, id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _doDelete(BuildContext context, WidgetRef ref, String id) async {
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId == null) return;
    try {
      final repo = ref.read(expenseRepositoryProvider);
      await repo.delete(id, tenantId: tenantId);
      ref.invalidate(expensesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            key: Key('snackbar_expense_deleted'),
            content: Text('Dépense supprimée'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
