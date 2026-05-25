import 'package:drift/drift.dart';

import 'tables/tenant_configs.dart';
import 'tables/cached_layouts.dart';
import 'tables/local_data.dart';
import 'tables/sync_queue_items.dart';
import 'tables/conflicts.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  TenantConfigs,
  CachedLayouts,
  LocalData,
  SyncQueueItems,
  Conflicts,
])
class ScalarioDatabase extends _$ScalarioDatabase {
  ScalarioDatabase({required QueryExecutor executor}) : super(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async => m.createAll(),
        onUpgrade: (Migrator m, int from, int to) async {
          // Slot vide pour migrations v2+
          for (int version = from + 1; version <= to; version++) {
            // ignore: dead_code
            if (false) {}
          }
        },
      );
}
