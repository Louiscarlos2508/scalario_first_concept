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
    final style = OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          OutlinedButton.icon(
            style: style,
            onPressed: cartState.items.isEmpty
                ? null
                : () => showCartParkDialog(context, ref, cartState),
            icon: const Icon(Icons.pause, size: 16),
            label: const Text('ATTENTE'),
          ),
          if (userRole != 'cashier') ...[
            const SizedBox(width: 6),
            OutlinedButton.icon(
              style: style.copyWith(
                foregroundColor: WidgetStatePropertyAll(Colors.orange),
                side: const WidgetStatePropertyAll(BorderSide(color: Colors.orange)),
              ),
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
              icon: const Icon(Icons.undo, size: 16),
              label: const Text('RETOUR'),
            ),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              style: style.copyWith(
                foregroundColor: WidgetStatePropertyAll(Colors.purple),
                side: const WidgetStatePropertyAll(BorderSide(color: Colors.purple)),
              ),
              onPressed: cartState.items.isEmpty
                  ? null
                  : () => showDialog<void>(
                        context: context,
                        builder: (_) => ReservationDepositDialog(cartState: cartState),
                      ),
              icon: const Icon(Icons.bookmark_border, size: 16),
              label: const Text('RÉSA'),
            ),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              style: style.copyWith(
                foregroundColor: WidgetStatePropertyAll(Colors.teal),
                side: const WidgetStatePropertyAll(BorderSide(color: Colors.teal)),
              ),
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
              icon: const Icon(Icons.bookmark_added_outlined, size: 16),
              label: const Text('EN COURS'),
            ),
          ],
          if (canAccessClientOrders) ...[
            const SizedBox(width: 6),
            OutlinedButton.icon(
              key: const Key('pos_client_order_button'),
              style: style.copyWith(
                foregroundColor: const WidgetStatePropertyAll(Colors.indigo),
                side: const WidgetStatePropertyAll(BorderSide(color: Colors.indigo)),
              ),
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
              icon: const Icon(Icons.assignment_outlined, size: 16),
              label: const Text('COMMANDE'),
            ),
          ],
        ],
      ),
    );
  }
}
