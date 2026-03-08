import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/features/pos/presentation/providers/pos_providers.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(syncStatusProvider);
    
    return statusAsync.when(
      data: (status) {
        Color color;
        IconData icon;
        String tooltip;

        switch (status) {
          case SyncUiStatus.connected:
            color = Colors.green;
            icon = Icons.cloud_done;
            tooltip = 'Online & Synced';
            break;
          case SyncUiStatus.syncing:
            color = Colors.orange;
            icon = Icons.sync;
            tooltip = 'Syncing...';
            break;
          case SyncUiStatus.error:
            color = Colors.red;
            icon = Icons.cloud_off;
            tooltip = 'Sync Error';
            break;
          case SyncUiStatus.disconnected:
          default:
            color = Colors.grey;
            icon = Icons.cloud_off;
            tooltip = 'Offline';
            break;

        }

        return IconButton(
          icon: Icon(icon, color: color),
          tooltip: tooltip,
          onPressed: () {
            if (status == SyncUiStatus.error || status == SyncUiStatus.disconnected) {
              ref.read(syncServiceProvider).forceSync();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Retrying sync...')),
              );
            }
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 24, 
          height: 24, 
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const Icon(Icons.error_outline, color: Colors.red),
    );
  }
}
