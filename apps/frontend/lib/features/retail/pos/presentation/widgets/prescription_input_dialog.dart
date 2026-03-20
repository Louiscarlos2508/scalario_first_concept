import 'package:flutter/material.dart';

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
  State<_PrescriptionInputDialog> createState() => _PrescriptionInputDialogState();
}

class _PrescriptionInputDialogState extends State<_PrescriptionInputDialog> {
  final _numberCtrl = TextEditingController();
  final _prescriberCtrl = TextEditingController();

  bool get _isValid =>
      _numberCtrl.text.trim().isNotEmpty && _prescriberCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _prescriberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ordonnance requise'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Un ou plusieurs articles requièrent une ordonnance médicale.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('prescription_number_field'),
            controller: _numberCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Numéro d\'ordonnance *',
              hintText: 'Ex: ORD-2026-00123',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('prescriber_name_field'),
            controller: _prescriberCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom du prescripteur *',
              hintText: 'Ex: Dr. Ouédraogo',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          key: const Key('prescription_confirm_button'),
          onPressed: _isValid
              ? () => Navigator.pop(
                    context,
                    PrescriptionData(
                      number: _numberCtrl.text.trim(),
                      prescriberName: _prescriberCtrl.text.trim(),
                    ),
                  )
              : null,
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}
