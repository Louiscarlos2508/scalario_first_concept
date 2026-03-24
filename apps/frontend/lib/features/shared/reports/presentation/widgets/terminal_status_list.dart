import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart';
import 'package:frontend/features/retail/backoffice/presentation/screens/dashboard_screen.dart'
    show dashboardNavigationProvider;

/// Dashboard terminal status list panel.
/// Registered as SDUI type `terminal_status_list`.
/// Shows open POS sessions from [activeSessionsProvider].
/// Section entière masquée si aucune session active.
class TerminalStatusList extends ConsumerWidget {
  const TerminalStatusList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(activeSessionsProvider);

    return sessionsAsync.when(
      data: (sessions) {
        // Masquer la section entière (titre inclus) si aucune caisse n'est active.
        if (sessions.isEmpty) return const SizedBox.shrink();

        final fcfa = NumberFormat.currency(
          locale: 'fr_FR',
          symbol: 'FCFA',
          decimalDigits: 0,
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Caisses ouvertes', style: AppTextStyles.titleLarge),
              const SizedBox(height: 12),
              ...sessions.map<Widget>((s) {
                final openedAt = DateTime.parse(s['openedAt'] as String);
                final openingBalance =
                    double.tryParse(s['openingBalance']?.toString() ?? '') ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.success.withValues(alpha: 0.1),
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
                      backgroundColor: AppColors.success.withValues(alpha: 0.1),
                      labelStyle:
                          AppTextStyles.labelSmall.copyWith(color: AppColors.success),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('terminal_history_link'),
                  onPressed: () {
                    ref.read(showSessionHistoryProvider.notifier).state = true;
                    ref.read(dashboardNavigationProvider.notifier).state = 'reports';
                  },
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('Historique des sessions'),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
