import 'package:isar/isar.dart';
import 'package:frontend/core/models/sync_status.dart';

part 'pos_session.g.dart';

@collection
class PosSession {
  PosSession();
  
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String uuid = ''; 

  late String userId;
  late String tenantId;
  late double openingBalance;
  double? closingBalance;
  double? theoreticalBalance;
  double? variance;
  String? varianceExplanation;

  String? deviceId;

  // OPEN, CLOSED, SYNCED
  late String status;
  @Enumerated(EnumType.name)
  SyncStatus syncStatus = SyncStatus.pending;

  late DateTime openedAt;
  DateTime? closedAt;
  
  String get remoteId => uuid;

  Map<String, dynamic> toJson() {
    return {
      'id': uuid,
      'uuid': uuid,
      'userId': userId,
      'tenantId': tenantId,
      'openingBalance': openingBalance,
      'closingBalance': closingBalance,
      'theoreticalBalance': theoreticalBalance,
      'variance': variance,
      'deviceId': deviceId,
      'status': status,
      'syncStatus': syncStatus.name,
      'openedAt': openedAt.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
    };
  }

  factory PosSession.fromJson(Map<String, dynamic> json) {
    return PosSession()
      ..uuid = json['id']?.toString() ?? json['uuid']?.toString() ?? ''
      ..userId = json['user_id']?.toString() ?? json['userId']?.toString() ?? ''
      ..tenantId = json['tenant_id']?.toString() ?? json['tenantId']?.toString() ?? ''
      ..openingBalance = (json['opening_balance'] is num) ? (json['opening_balance'] as num).toDouble() : double.parse(json['opening_balance']?.toString() ?? '0')
      ..closingBalance = json['closing_balance'] != null ? ((json['closing_balance'] is num) ? (json['closing_balance'] as num).toDouble() : double.parse(json['closing_balance']?.toString() ?? '0')) : null
      ..theoreticalBalance = json['theoretical_balance'] != null ? ((json['theoretical_balance'] is num) ? (json['theoretical_balance'] as num).toDouble() : double.parse(json['theoretical_balance']?.toString() ?? '0')) : null
      ..variance = json['variance'] != null ? ((json['variance'] is num) ? (json['variance'] as num).toDouble() : double.parse(json['variance']?.toString() ?? '0')) : null
      ..varianceExplanation = json['variance_explanation']?.toString() ?? json['varianceExplanation']?.toString()
      ..deviceId = json['device_id']?.toString() ?? json['deviceId']?.toString()
      ..status = json['status']?.toString() ?? 'OPEN'
      ..syncStatus = SyncStatus.values.firstWhere((e) => e.name == json['syncStatus'], orElse: () => SyncStatus.synced)
      ..openedAt = DateTime.parse(json['opened_at']?.toString() ?? DateTime.now().toIso8601String())
      ..closedAt = json['closed_at'] != null ? DateTime.parse(json['closed_at'].toString()) : null;
  }
}
