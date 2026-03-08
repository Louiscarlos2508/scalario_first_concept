import 'package:isar/isar.dart';

part 'sync_metadata.g.dart';

@collection
class SyncMetadata {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String key = '';
  
  DateTime? lastSync;

  SyncMetadata({this.key = '', this.lastSync});
}
