import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/retail/dashboard/presentation/providers/dashboard_providers.dart';

/// Dashboard terminal status list panel.
/// Registered as SDUI type `terminal_status_list`.
/// Reads [terminalStatusProvider] via ref.watch.
class TerminalStatusList extends ConsumerWidget {
  const TerminalStatusList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terminalsAsync = ref.watch(terminalStatusProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('État des caisses', style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),
          terminalsAsync.when(
            data: (terminals) {
              if (terminals.isEmpty) {
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
                children: terminals.map<Widget>((t) {
                  final lastSeen = DateTime.parse(t['lastSeen'] as String);
                  final isOnline =
                      t['status'] == 'ONLINE' &&
                      DateTime.now().difference(lastSeen).inMinutes < 5;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isOnline
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.border,
                        child: Icon(
                          Icons.computer,
                          color: isOnline
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                      title: Text(
                        t['deviceId'] as String,
                        style: AppTextStyles.bodyMedium,
                      ),
                      subtitle: Text(
                        'Vu à : ${DateFormat('HH:mm:ss').format(lastSeen)}',
                        style: AppTextStyles.bodySmall,
                      ),
                      trailing: Chip(
                        label: Text(isOnline ? 'EN LIGNE' : 'HORS LIGNE'),
                        backgroundColor: isOnline
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.border,
                        labelStyle: AppTextStyles.labelSmall.copyWith(
                          color: isOnline
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
