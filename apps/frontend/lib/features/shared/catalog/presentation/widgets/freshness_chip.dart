import 'package:flutter/material.dart';

/// AC1 (Story 24-2) — Freshness color-code chip shown on product cards.
///
/// Green  → freshnessPercent > greenThreshold (default 50%)
/// Orange → greenThreshold >= freshnessPercent >= orangeThreshold (default 20%)
/// Red    → freshnessPercent < orangeThreshold or already expired
class FreshnessChip extends StatelessWidget {
  final DateTime expiresAt;
  final int expiryDays;
  final double greenThreshold;
  final double orangeThreshold;

  const FreshnessChip({
    super.key,
    required this.expiresAt,
    required this.expiryDays,
    this.greenThreshold = 50.0,
    this.orangeThreshold = 20.0,
  });

  /// freshnessPercent = (expiresAt − now) / expiryDays × 100 (in days)
  double get freshnessPercent {
    if (expiryDays <= 0) return 100.0;
    final remainingHours = expiresAt.difference(DateTime.now()).inHours;
    final remainingDays = remainingHours / 24.0;
    if (remainingDays < 0) return 0.0;
    return (remainingDays / expiryDays * 100).clamp(0.0, 100.0);
  }

  Color get _chipColor {
    final percent = freshnessPercent;
    if (percent > greenThreshold) return Colors.green;
    if (percent >= orangeThreshold) return Colors.orange;
    return Colors.red;
  }

  String get _label {
    final daysLeft = expiresAt.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return 'Périmé';
    return '${daysLeft}j';
  }

  /// Returns true if this batch should be considered "urgent" (orange or red).
  bool get isUrgent => freshnessPercent < greenThreshold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: _chipColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
