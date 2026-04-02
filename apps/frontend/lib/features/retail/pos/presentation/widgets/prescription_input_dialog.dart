import 'package:flutter/material.dart';
import 'package:frontend/core/theme/sheet_style.dart';

/// Prescription data captured at POS before checkout (AC2 — FR94).
class PrescriptionData {
  final String number;
  final String prescriberName;

  const PrescriptionData({required this.number, required this.prescriberName});
}

/// Shows a dialog asking the cashier for prescription number + prescriber name.
/// Returns [PrescriptionData] on confirm, null on cancel.
Future<PrescriptionData?> showPrescriptionDialog(BuildContext context) {
  return showDialog<PrescriptionData>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _PrescriptionInputDialog(),
  );
}

class _PrescriptionInputDialog extends StatefulWidget {
  const _PrescriptionInputDialog();

  @override
  State<_PrescriptionInputDialog> createState() =>
      _PrescriptionInputDialogState();
}

class _PrescriptionInputDialogState extends State<_PrescriptionInputDialog> {
  final _numberCtrl = TextEditingController();
  final _prescriberCtrl = TextEditingController();

  bool get _isValid =>
      _numberCtrl.text.trim().isNotEmpty &&
      _prescriberCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _prescriberCtrl.dispose();
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
            // ── Header ───────────────────────────────────────────────────
            const SheetDialogHeader(
              icon: Icons.medical_services_outlined,
              iconColor: Color(0xFF8B5CF6),
              title: 'Ordonnance requise',
              subtitle: 'Un article nécessite une ordonnance médicale',
            ),
            const SizedBox(height: 20),

            // ── Fields ───────────────────────────────────────────────────
            TextField(
              key: const Key('prescription_number_field'),
              controller: _numberCtrl,
              autofocus: true,
              decoration: sheetInputDecoration(
                label: "Numéro d'ordonnance *",
                hint: 'Ex: ORD-2026-00123',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('prescriber_name_field'),
              controller: _prescriberCtrl,
              decoration: sheetInputDecoration(
                label: 'Nom du prescripteur *',
                hint: 'Ex: Dr. Ouédraogo',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            SheetActionRow(
              confirmLabel: 'Confirmer',
              onConfirm: _isValid
                  ? () => Navigator.pop(
                        context,
                        PrescriptionData(
                          number: _numberCtrl.text.trim(),
                          prescriberName: _prescriberCtrl.text.trim(),
                        ),
                      )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
