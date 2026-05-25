import 'package:drift/drift.dart';

@DataClassName('CachedLayout')
class CachedLayouts extends Table {
  TextColumn get screenId => text()();
  TextColumn get tenantId => text()();
  TextColumn get layoutJson => text()();
  TextColumn get etag => text().nullable()();
  DateTimeColumn get lastFetchAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get bytesSize => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {screenId};
}
