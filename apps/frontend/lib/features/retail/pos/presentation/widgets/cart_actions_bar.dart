import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/cart_park_dialog.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/pos_reservations_sheet.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/reservation_deposit_dialog.dart';
import 'package:frontend/features/shared/client_orders/presentation/screens/client_orders_pos_sheet.dart';
import 'package:frontend/features/shared/reports/presentation/screens/sales_history_screen.dart';

class CartActionsBar extends ConsumerWidget {
  const CartActionsBar({
    super.key,
    required this.cartState,
    required this.userRole,
    required this.canAccessClientOrders,
    required this.userId,
  });

  final CartState cartState;
  final String userRole;
  final bool canAccessClientOrders;
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OverflowBar(
      spacing: 8,
      overflowSpacing: 4,
      children: [
        OutlinedButton.icon(
          onPressed: cartState.items.isEmpty
              ? null
              : () => showCartParkDialog(context, ref, cartState),
          icon: const Icon(Icons.pause),
          label: const Text('ATTENTE'),
        ),
        if (userRole != 'cashier')
          OutlinedButton.icon(
            onPressed: () {
              final isCommercial = userRole == 'commercial';
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SalesHistoryScreen(
                    fixedUserId: isCommercial ? userId : null,
                    initialPeriod: isCommercial ? 'today' : '7d',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.undo, color: Colors.orange),
            label: const Text(
              'RETOUR',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        OutlinedButton.icon(
          onPressed: cartState.items.isEmpty
              ? null
              : () => showDialog<void>(
                    context: context,
                    builder: (_) => ReservationDepositDialog(
                      cartState: cartState,
                    ),
                  ),
          icon: const Icon(Icons.bookmark_border, color: Colors.purple),
          label: const Text(
            'RÉSERVATION',
            style: TextStyle(color: Colors.purple),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            showDragHandle: true,
            builder: (_) => const FractionallySizedBox(
              heightFactor: 0.85,
              child: PosReservationsSheet(),
            ),
          ),
          icon: const Icon(Icons.bookmark_added_outlined,
              color: Colors.teal),
          label: const Text(
            'EN COURS',
            style: TextStyle(color: Colors.teal),
          ),
        ),
        if (canAccessClientOrders)
          OutlinedButton.icon(
            key: const Key('pos_client_order_button'),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              showDragHandle: true,
              builder: (_) => const FractionallySizedBox(
                heightFactor: 0.92,
                child: ClientOrdersPosSheet(),
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.indigo,
              side: const BorderSide(color: Colors.indigo),
            ),
            icon: const Icon(Icons.assignment_outlined, size: 18),
            label: const Text('Commande'),
          ),
      ],
    );
  }
}
