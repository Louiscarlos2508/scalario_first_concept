import 'package:drift/drift.dart';

@DataClassName('ConflictRecord')
class Conflicts extends Table {
  TextColumn get id => text()();
  TextColumn get mutationId => text()();
  TextColumn get localStateJson => text()();
  TextColumn get serverStateJson => text()();
  DateTimeColumn get detectedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  TextColumn get resolution => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
