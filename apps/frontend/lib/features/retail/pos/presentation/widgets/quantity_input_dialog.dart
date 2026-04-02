import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/sheet_style.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class QuantityInputDialog extends StatefulWidget {
  final Product product;
  const QuantityInputDialog({super.key, required this.product});

  @override
  State<QuantityInputDialog> createState() => _QuantityInputDialogState();
}

class _QuantityInputDialogState extends State<QuantityInputDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  double? _preview;

  String get _unitLabel => widget.product.weightUnit ?? widget.product.unitType;
  double get _unitPrice => widget.product.pricePerUnit ?? widget.product.price;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updatePreview);
  }

  void _updatePreview() {
    final parsed = double.tryParse(_controller.text.replaceAll(',', '.'));
    setState(() {
      _preview = parsed != null && parsed > 0 ? parsed * _unitPrice : null;
    });
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SheetDialogHeader(
                icon: Icons.scale_outlined,
                iconColor: kSheetBlue,
                title: 'Saisir la quantité',
                subtitle: widget.product.name,
              ),
              const SizedBox(height: 16),

              // ── Unit price pill ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kSheetBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sell_outlined, size: 13, color: kSheetBlue),
                    const SizedBox(width: 6),
                    Text(
                      '${_fcfa(_unitPrice)} / $_unitLabel',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: kSheetBlue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Quantity field ───────────────────────────────────────────
              TextFormField(
                key: const Key('quantity_input_field'),
                controller: _controller,
                autofocus: true,
                decoration: sheetInputDecoration(label: 'Quantité *', suffix: _unitLabel),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Obligatoire';
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Doit être > 0';
                  return null;
                },
              ),

              // ── Total preview ─────────────────────────────────────────────
              if (_preview != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 15, color: kSheetGreen),
                      const SizedBox(width: 8),
                      Text(
                        'Total : ${_fcfa((_preview! / 5).round() * 5.0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kSheetGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              SheetActionRow(
                confirmLabel: 'Confirmer',
                onConfirm: _confirm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    final qty = double.parse(_controller.text.replaceAll(',', '.'));
    Navigator.of(context).pop(qty);
  }
}
