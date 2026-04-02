import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/sheet_style.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart' as model;

class DiscountDialog extends ConsumerStatefulWidget {
  final model.CartItem item;
  const DiscountDialog({super.key, required this.item});

  @override
  ConsumerState<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends ConsumerState<DiscountDialog> {
  late TextEditingController _controller;
  late String _type;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.item.discountAmount > 0
          ? widget.item.discountAmount.toStringAsFixed(0)
          : '',
    );
    _type = widget.item.discountType;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: kSheetDialogShape,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetDialogHeader(
              icon: Icons.edit_note,
              iconColor: kSheetBlue,
              title: 'Remise article',
              subtitle: widget.item.product.name,
            ),
            const SizedBox(height: 20),

            // ── Type toggle ───────────────────────────────────────────────
            const SheetSectionLabel('Type de remise'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TypeChip(
                    label: 'Montant (FCFA)',
                    selected: _type == 'FIXED',
                    onTap: () => setState(() => _type = 'FIXED'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TypeChip(
                    label: 'Pourcentage (%)',
                    selected: _type == 'PERCENTAGE',
                    onTap: () => setState(() => _type = 'PERCENTAGE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Amount field ──────────────────────────────────────────────
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: sheetInputDecoration(
                label: 'Valeur de la remise',
                suffix: _type == 'PERCENTAGE' ? '%' : 'FCFA',
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),

            SheetActionRow(
              confirmLabel: 'Appliquer',
              onConfirm: _apply,
            ),
          ],
        ),
      ),
    );
  }

  void _apply() {
    final amount = double.tryParse(_controller.text.replaceAll(',', '.')) ?? 0.0;
    if (_type == 'PERCENTAGE' && (amount < 0 || amount > 100)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le pourcentage doit être entre 0 et 100')),
      );
      return;
    }
    if (_type == 'FIXED' && amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le montant ne peut pas être négatif')),
      );
      return;
    }
    ref.read(cartProvider.notifier).updateItemDiscount(
      widget.item.product.remoteId!,
      amount,
      _type,
    );
    Navigator.pop(context);
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? kSheetBlue : Colors.white,
          border: Border.all(color: selected ? kSheetBlue : kSheetSlate200, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : kSheetSlate500,
          ),
        ),
      ),
    );
  }
}
