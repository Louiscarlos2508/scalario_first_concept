import 'package:flutter/material.dart';

const _moduleCodeToLabel = {
  'catalog': 'Catalogue',
  'inventory': 'Inventaire',
  'retail': 'Point de vente',
  'reporting': 'Rapports',
  'purchase_orders': 'Commandes fournisseurs',
  'variants': 'Variantes',
  'pricing': 'Multi-tarifs',
  'promotions': 'Promotions',
  'returns': 'Retours',
  'reservations': 'Réservations',
};

Color _planColor(String plan) => switch (plan) {
      'standard' => Colors.blue,
      'premium' => Colors.purple,
      'enterprise' => const Color(0xFFB8860B),
      _ => Colors.grey,
    };

class PlanInfoCard extends StatelessWidget {
  final Map<String, dynamic> plan;

  const PlanInfoCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final code = plan['code'] as String? ?? 'free';
    final name = plan['name'] as String? ?? code;
    final price = double.tryParse(plan['monthlyPrice']?.toString() ?? '0') ?? 0;
    final maxUsers = plan['maxUsers'] as int? ?? 1;
    final modules = List<String>.from(plan['includedModules'] as List? ?? []);
    final color = _planColor(code);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(name,
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.bold)),
                  backgroundColor: color.withValues(alpha: 0.12),
                  side: BorderSide(color: color),
                ),
                const Spacer(),
                Text(
                  '${price.toStringAsFixed(0)} FCFA/mois',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Jusqu\'à $maxUsers utilisateur(s)',
                style: Theme.of(context).textTheme.bodySmall),
            if (modules.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Modules inclus',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: modules
                    .map((m) => Chip(
                          label: Text(
                              _moduleCodeToLabel[m] ?? m,
                              style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
