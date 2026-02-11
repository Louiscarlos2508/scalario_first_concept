import 'package:isar/isar.dart';

part 'customer.g.dart';

@collection
class Customer {
  Customer();

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? remoteId; // UUID from Supabase

  late String name;
  String? phone;
  String? email;
  String? address;
  double balance = 0.0;
  String? tenantId;
  
  DateTime? createdAt;
  DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': remoteId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'balance': balance,
      'tenantId': tenantId,
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer()
      ..remoteId = json['id']?.toString()
      ..name = json['name']?.toString() ?? 'Unknown'
      ..phone = json['phone']?.toString()
      ..email = json['email']?.toString()
      ..address = json['address']?.toString()
      ..balance = _toDouble(json['balance'])
      ..tenantId = (json['tenantId'] ?? json['tenant_id'])?.toString()
      ..createdAt = json['created_at'] != null ? DateTime.parse(json['created_at']) : null
      ..updatedAt = json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
