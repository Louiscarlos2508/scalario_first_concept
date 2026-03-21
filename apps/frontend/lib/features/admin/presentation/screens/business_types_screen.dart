import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import '../providers/admin_providers.dart';
import '../../data/models/business_type_summary.dart';

IconData _iconFromName(String? name) {
  const map = {
    'store': Icons.store,
    'local_grocery_store': Icons.local_grocery_store,
    'phone_android': Icons.phone_android,
    'checkroom': Icons.checkroom,
    'local_pharmacy': Icons.local_pharmacy,
    'hardware': Icons.hardware,
    'kitchen': Icons.kitchen,
    'wine_bar': Icons.wine_bar,
    'diamond': Icons.diamond,
    'recycling': Icons.recycling,
    'bakery_dining': Icons.bakery_dining,
    'local_gas_station': Icons.local_gas_station,
    'warehouse': Icons.warehouse,
    'local_shipping': Icons.local_shipping,
    'restaurant': Icons.restaurant,
  };
  return map[name] ?? Icons.store;
}

String _sectionLabel(String section) {
  const labels = {
    'weight': 'Poids',
    'variants': 'Variantes',
    'serial': 'N° série',
    'warranty': 'Garantie',
    'expiry': 'Expiration',
    'freshness': 'Fraîcheur',
    'prescription': 'Ordonnance',
    'dynamic_pricing': 'Prix dynamique',
    'unique': 'Unique',
    'pricing': 'Multi-tarifs',
    'bestbefore': 'Garde',
    'batch': 'Lots',
    'consignment': 'Dépôt',
  };
  return labels[section] ?? section;
}

// ── List screen ───────────────────────────────────────────────────────────────

class BusinessTypesScreen extends ConsumerWidget {
  const BusinessTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(businessTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Types métier')),
      body: typesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (types) {
          final sorted = [...types]..sort((a, b) => a.name.compareTo(b.name));
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: sorted.length,
            itemBuilder: (context, i) => _BusinessTypeCard(
              type: sorted[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _BusinessTypeDetailPage(type: sorted[i]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _BusinessTypeCard extends StatelessWidget {
  final BusinessTypeSummary type;
  final VoidCallback onTap;

  const _BusinessTypeCard({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(_iconFromName(type.icon), color: AppColors.primary),
        ),
        title: Text(
          type.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (type.description != null) ...[
              const SizedBox(height: 2),
              Text(
                type.description!,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _InfoChip('${type.suggestedCategories.length} catégories'),
                ...type.visibleSections.map((s) => _InfoChip(_sectionLabel(s))),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right,
            color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11, color: AppColors.textSecondary)),
    );
  }
}

// ── Detail page ───────────────────────────────────────────────────────────────

class _BusinessTypeDetailPage extends StatelessWidget {
  final BusinessTypeSummary type;

  const _BusinessTypeDetailPage({required this.type});

  static const _roles = ['owner', 'manager', 'commercial', 'cashier'];

  String _docTypeLabel(String? dt) => switch (dt) {
        'receipt' => 'Ticket de caisse',
        'invoice' => 'Facture',
        'delivery_note' => 'Bon de livraison',
        _ => dt ?? '—',
      };

  String _defaultRoleLabel(String role) => switch (role) {
        'owner' => 'Propriétaire',
        'manager' => 'Gestionnaire',
        'commercial' => 'Commercial',
        'cashier' => 'Caissier',
        _ => role,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(type.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(_iconFromName(type.icon),
                    color: AppColors.primary, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    if (type.description != null)
                      Text(type.description!,
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Default flags
          if (type.defaultFlags.isNotEmpty) ...[
            _SectionTitle('Défauts produit'),
            const SizedBox(height: 8),
            ...type.defaultFlags.entries
                .map((e) => _DetailRow(e.key, '${e.value}')),
            const SizedBox(height: 20),
          ],

          // Visible sections
          if (type.visibleSections.isNotEmpty) ...[
            _SectionTitle('Sections visibles dans le formulaire produit'),
            const SizedBox(height: 8),
            ...type.visibleSections.map((s) => _CheckRow(_sectionLabel(s))),
            const SizedBox(height: 20),
          ],

          // Suggested categories
          if (type.suggestedCategories.isNotEmpty) ...[
            _SectionTitle('Catégories suggérées'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: type.suggestedCategories
                  .map((c) => Chip(
                      label: Text(c),
                      visualDensity: VisualDensity.compact))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Role labels
          _SectionTitle('Labels des rôles'),
          const SizedBox(height: 8),
          ..._roles.map((role) {
            final custom = type.roleLabels[role] as String?;
            final displayed = custom ?? _defaultRoleLabel(role);
            return _DetailRow(_defaultRoleLabel(role), displayed);
          }),
          const SizedBox(height: 20),

          // Document type
          _SectionTitle('Document'),
          const SizedBox(height: 8),
          _DetailRow('Type de document', _docTypeLabel(type.documentType)),
          const SizedBox(height: 32),

          // Read-only note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lecture seule — La modification se fait dans le seed backend.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;

  const _CheckRow(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
