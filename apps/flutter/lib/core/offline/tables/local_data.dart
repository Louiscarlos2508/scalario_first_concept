import 'package:drift/drift.dart';

@DataClassName('LocalDataRecord')
class LocalData extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get moduleId => text()();
  TextColumn get entityType => text()();
  TextColumn get dataJson => text()();
  DateTimeColumn get baseUpdatedAt => dateTime().nullable()();
  DateTimeColumn get localUpdatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}
