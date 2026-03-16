import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class ParkedCartsDialog extends ConsumerWidget {
  const ParkedCartsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parked = ref.watch(parkedCartsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Ventes en attente',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Expanded(
            child: parked.isEmpty
                ? const Center(child: Text('Aucune vente en attente'))
                : ListView.builder(
                    itemCount: parked.length,
                    itemBuilder: (context, index) {
                      final cart = parked[index];
                      return ListTile(
                        title: Text(cart.name ?? 'Sans nom'),
                        subtitle: Text(
                          '${cart.items.length} article(s) — ${_fcfa(cart.totalAmount)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ref
                              .read(cartProvider.notifier)
                              .replaceCart(cart);
                          ref
                              .read(parkedCartsProvider.notifier)
                              .removeParkedCart(cart);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
