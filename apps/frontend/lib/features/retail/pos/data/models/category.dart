import 'package:isar/isar.dart';

part 'category.g.dart';

@collection
class Category {
  Category();

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String remoteId;

  late String name;
  late String tenantId;

  DateTime? lastUpdated;
  bool isDeleted = false;
  
  // For UI convenience
  @ignore
  int productCount = 0;

  Map<String, dynamic> toJson() {
    return {
      'id': remoteId,
      'name': name,
      'tenantId': tenantId,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category()
      ..remoteId = json['id'] as String
      ..name = json['name'] as String
      ..tenantId = json['tenantId'] as String;
  }
}
