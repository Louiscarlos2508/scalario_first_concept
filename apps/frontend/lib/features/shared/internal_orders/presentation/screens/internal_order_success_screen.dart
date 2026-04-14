import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/internal_orders/data/internal_order.dart';
import 'package:frontend/features/shared/internal_orders/presentation/widgets/internal_order_card.dart'
    show formatAmount;

/// Écran succès après validation — auto-retour après 3s.
class InternalOrderSuccessScreen extends StatefulWidget {
  final InternalOrder order;
  const InternalOrderSuccessScreen({super.key, required this.order});

  @override
  State<InternalOrderSuccessScreen> createState() =>
      _InternalOrderSuccessScreenState();
}

class _InternalOrderSuccessScreenState
    extends State<InternalOrderSuccessScreen> {
  late Timer _timer;
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment(0, 0.6),
            colors: [Color(0xFFE8F5E9), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 80),
                // Big green checkmark
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.3),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text('\u2713',
                      style: TextStyle(
                          fontSize: 72, color: Colors.white)),
                ),
                const SizedBox(height: 28),

                // Title
                const Text('Commande validée !',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    )),
                const SizedBox(height: 6),

                // Ticket + time
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Ticket '),
                    TextSpan(
                        text: order.id,
                        style: const TextStyle(
                            fontFamily: 'Cousine',
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    TextSpan(
                        text:
                            ' · ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}'),
                  ]),
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                // Summary card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      _Row(
                          label: order.title,
                          value: '${order.productCount} produits'),
                      const SizedBox(height: 8),
                      _Row(
                          label: 'Demandé par',
                          value: order.commercialName.split(' ').first),
                      const SizedBox(height: 8),
                      _Row(label: 'Approuvé par', value: 'Fatim · Toi'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.only(top: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                              top: BorderSide(
                                  color: AppColors.border, width: 0.8)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total estimé',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            Text('${formatAmount(order.estimatedAmount)} F',
                                style: const TextStyle(
                                  fontFamily: 'Cousine',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Notification banner
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border:
                        Border.all(color: const Color(0xFFA5D6A7), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Text('\u{1F514}',
                          style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('2 notifications envoyées',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                )),
                            const SizedBox(height: 2),
                            Text(
                              '${order.commercialName} · Fatim Diop · journal d\'audit tracé',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Text('\u2713',
                          style: TextStyle(
                              fontSize: 20, color: AppColors.success)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: navigate to detail
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.border, width: 0.8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.lg)),
                    ),
                    child: const Text('\u2295 Voir le détail',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 47,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.lg)),
                      elevation: 4,
                      shadowColor: AppColors.success.withValues(alpha: 0.25),
                    ),
                    child: const Text('\u21A9 Retour à la liste',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),

                // Auto-return
                Text('\u21BB Retour auto dans $_countdown s',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
