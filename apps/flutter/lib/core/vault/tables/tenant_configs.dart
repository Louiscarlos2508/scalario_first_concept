import 'package:drift/drift.dart';

@DataClassName('TenantConfig')
class TenantConfigs extends Table {
  TextColumn get tenantId => text()();
  TextColumn get slug => text()();
  TextColumn get configJson => text()();
  IntColumn get cacheLimitMb => integer().withDefault(const Constant(500))();
  TextColumn get version => text().withDefault(const Constant('1'))();
  DateTimeColumn get lastFetchAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {tenantId};
}
