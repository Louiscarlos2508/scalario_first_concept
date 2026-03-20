import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart';
import 'package:frontend/features/retail/backoffice/presentation/screens/dashboard_screen.dart'
    show dashboardNavigationProvider;

/// Dashboard terminal status list panel.
/// Registered as SDUI type `terminal_status_list`.
/// Shows open POS sessions (cashiers currently working) from [activeSessionsProvider].
class TerminalStatusList extends ConsumerWidget {
  const TerminalStatusList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(activeSessionsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('État des caisses', style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),
          sessionsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return const Card(
                  child: ListTile(
                    title: Text(
                      'Aucune caisse active',
                      style: AppTextStyles.bodyMedium,
                    ),
                    subtitle: Text(
                      "Ouvrez une session caisse pour l'afficher ici",
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                );
              }
              return Column(
                children: sessions.map<Widget>((s) {
                  final openedAt = DateTime.parse(s['openedAt'] as String);
                  final openingBalance =
                      double.tryParse(s['openingBalance']?.toString() ?? '') ?? 0;
                  final fcfa = NumberFormat.currency(
                    locale: 'fr_FR',
                    symbol: 'FCFA',
                    decimalDigits: 0,
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.success.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.point_of_sale,
                          color: AppColors.success,
                        ),
                      ),
                      title: Text(
                        s['deviceId'] as String? ?? 'Terminal inconnu',
                        style: AppTextStyles.bodyMedium,
                      ),
                      subtitle: Text(
                        'Depuis : ${DateFormat('HH:mm').format(openedAt.toLocal())}  •  Fond : ${fcfa.format(openingBalance)}',
                        style: AppTextStyles.bodySmall,
                      ),
                      trailing: Chip(
                        label: const Text('EN COURS'),
                        backgroundColor:
                            AppColors.success.withValues(alpha: 0.1),
                        labelStyle: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.success),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('terminal_history_link'),
              onPressed: () {
                ref.read(showSessionHistoryProvider.notifier).state = true;
                ref.read(dashboardNavigationProvider.notifier).state =
                    'reports';
              },
              icon: const Icon(Icons.history, size: 16),
              label: const Text('Historique des sessions'),
            ),
          ),
        ],
      ),
    );
  }
}
