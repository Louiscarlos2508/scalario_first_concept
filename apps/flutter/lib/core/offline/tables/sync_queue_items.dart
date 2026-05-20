import 'package:drift/drift.dart';

@DataClassName('SyncQueueItem')
class SyncQueueItems extends Table {
  TextColumn get mutationId => text()();
  TextColumn get tenantId => text()();
  TextColumn get moduleId => text()();
  TextColumn get action => text()();
  TextColumn get payloadJson => text()();
  TextColumn get idempotencyKey => text().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {mutationId};
}
