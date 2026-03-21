import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

String _fcfa(double v) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(v);

class DailySalesPage extends ConsumerStatefulWidget {
  const DailySalesPage({super.key});

  @override
  ConsumerState<DailySalesPage> createState() => _DailySalesPageState();
}

class _DailySalesPageState extends ConsumerState<DailySalesPage> {
  Map<String, dynamic>? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary =
          await ref.read(sessionProvider.notifier).calculateSessionSummary();
      if (mounted) {
        setState(() {
          _summary = summary;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes ventes du jour'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _build(),
    );
  }

  Widget _build() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Erreur : $_error',
                style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    final summary = _summary;
    if (summary == null) {
      return const Center(
        child: Text(
          'Aucune session active',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final totalSales = (summary['totalSales'] as num?)?.toDouble() ?? 0.0;
    final totalsByMethod =
        (summary['totalsByMethod'] as Map<String, dynamic>?) ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Total CA
          _KpiCard(
            label: 'Chiffre d\'affaires',
            value: _fcfa(totalSales),
            icon: Icons.receipt_long,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),

          // Par méthode de paiement
          if (totalsByMethod.isNotEmpty) ...[
            Text('Répartition par méthode',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...totalsByMethod.entries.map((e) {
              final label = _methodLabel(e.key);
              final amount = (e.value as num).toDouble();
              return _MethodRow(label: label, amount: amount);
            }),
          ],
        ],
      ),
    );
  }

  String _methodLabel(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return 'Espèces';
      case 'MOBILE_MONEY':
        return 'Mobile Money';
      case 'CARD':
        return 'Carte';
      case 'TRANSFER':
        return 'Virement';
      default:
        return method;
    }
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: AppColors.textSecondary)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  final String label;
  final double amount;

  const _MethodRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(_fcfa(amount),
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
