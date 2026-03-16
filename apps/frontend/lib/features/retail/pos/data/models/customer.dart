import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'customer.g.dart';

@collection
class Customer {
  Customer();

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index(unique: true, replace: true)
  String? remoteId; // UUID from Supabase

  late String name;
  String? phone;
  String? email;
  String? address;
  double balance = 0.0;
  String? tenantId;

  // Contact schema alignment (added Story 8.2)
  String? contactType; // default: 'customer'
  bool isSynced = false;
  DateTime? lastUpdated;

  DateTime? createdAt;
  DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'id': remoteId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'balance': balance,
      'tenantId': tenantId,
      'contactType': contactType ?? 'customer',
      if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer()
      ..uuid = json['uuid']?.toString() ?? const Uuid().v4()
      ..remoteId = json['id']?.toString()
      ..name = json['name']?.toString() ?? 'Unknown'
      ..phone = json['phone']?.toString()
      ..email = json['email']?.toString()
      ..address = json['address']?.toString()
      ..balance = _toDouble(json['balance'])
      ..tenantId = (json['tenantId'] ?? json['tenant_id'])?.toString()
      ..contactType = json['contactType']?.toString() ??
          json['contact_type']?.toString() ??
          'customer'
      ..isSynced = true // server response means it's synced
      ..lastUpdated = json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : (json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : null)
      ..createdAt = json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null
      ..updatedAt = json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
