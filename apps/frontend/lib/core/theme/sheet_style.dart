import 'package:flutter/material.dart';

// ── Palette ─────────────────────────────────────────────────────────────────
const kSheetSlate900 = Color(0xFF0F172A);
const kSheetSlate500 = Color(0xFF64748B);
const kSheetSlate200 = Color(0xFFE2E8F0);
const kSheetSlate50  = Color(0xFFF8FAFC);
const kSheetBlue     = Color(0xFF1A73E8);
const kSheetGreen    = Color(0xFF34A853);
const kSheetRed      = Color(0xFFEA4335);
const kSheetAmber    = Color(0xFFFBBF24);

// ── Dialog shape ─────────────────────────────────────────────────────────────
const ShapeBorder kSheetDialogShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
);

// ── Input decoration ─────────────────────────────────────────────────────────
InputDecoration sheetInputDecoration({
  required String label,
  String? suffix,
  String? hint,
  Widget? prefixIcon,
}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: kSheetSlate50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kSheetSlate200, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kSheetSlate200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kSheetBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kSheetRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kSheetRed, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );

// ── Button styles ─────────────────────────────────────────────────────────────
ButtonStyle sheetPrimaryButtonStyle({Color? color}) => FilledButton.styleFrom(
      backgroundColor: color ?? kSheetBlue,
      padding: const EdgeInsets.symmetric(vertical: 13),
      minimumSize: Size.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );

ButtonStyle sheetCancelButtonStyle() => TextButton.styleFrom(
      foregroundColor: kSheetSlate500,
      padding: const EdgeInsets.symmetric(vertical: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: kSheetSlate200),
      ),
    );

// ── Icon header (for Dialog widgets) ─────────────────────────────────────────
class SheetDialogHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color? iconBgColor;

  const SheetDialogHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtitle; // local binding — enables null promotion
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBgColor ?? iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: kSheetSlate900)),
              if (sub != null)
                Text(sub,
                    style: const TextStyle(fontSize: 12, color: kSheetSlate500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Bottom sheet title row ────────────────────────────────────────────────────
class SheetTitleRow extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;

  const SheetTitleRow({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final ic = iconColor ?? kSheetBlue;
    final ic2 = icon; // local binding for null promotion
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          if (ic2 != null) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ic.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(ic2, color: ic, size: 17),
            ),
            const SizedBox(width: 10),
          ],
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: kSheetSlate900)),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

// ── Action row (cancel + confirm) ────────────────────────────────────────────
class SheetActionRow extends StatelessWidget {
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final Color? confirmColor;

  const SheetActionRow({
    super.key,
    this.cancelLabel = 'Annuler',
    required this.confirmLabel,
    this.onCancel,
    required this.onConfirm,
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            style: sheetCancelButtonStyle(),
            onPressed: onCancel ?? () => Navigator.pop(context),
            child: Text(cancelLabel),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            style: sheetPrimaryButtonStyle(color: confirmColor),
            onPressed: onConfirm,
            child: Text(confirmLabel),
          ),
        ),
      ],
    );
  }
}

// ── Divider with color ────────────────────────────────────────────────────────
class SheetDivider extends StatelessWidget {
  const SheetDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: kSheetSlate200);
}

// ── Section label ─────────────────────────────────────────────────────────────
class SheetSectionLabel extends StatelessWidget {
  final String label;
  const SheetSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: kSheetSlate500,
        letterSpacing: 0.5,
      ),
    );
  }
}
