import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/customer_selection_dialog.dart';

class CartCustomerHeader extends ConsumerWidget {
  const CartCustomerHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCustomer = ref.watch(selectedCustomerProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: selectedCustomer == null
                ? const Text('Aucun client',
                    style: TextStyle(color: Colors.grey, fontSize: 13))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedCustomer.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Text(selectedCustomer.phone ?? 'Sans téléphone',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                    ],
                  ),
          ),
          TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const CustomerSelectionDialog(),
            ),
            child: Text(
              selectedCustomer == null ? 'CHOISIR' : 'CHANGER',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (selectedCustomer != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.red),
              onPressed: () =>
                  ref.read(selectedCustomerProvider.notifier).state = null,
            ),
        ],
      ),
    );
  }
}
