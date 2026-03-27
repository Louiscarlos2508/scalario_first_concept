import 'client_order_line.dart';

class ClientOrderKpis {
  final int inProgressCount;
  final double pendingRevenue;

  const ClientOrderKpis({
    required this.inProgressCount,
    required this.pendingRevenue,
  });

  factory ClientOrderKpis.fromJson(Map<String, dynamic> json) {
    return ClientOrderKpis(
      inProgressCount: (json['inProgressCount'] as num?)?.toInt() ?? 0,
      pendingRevenue: double.tryParse(json['pendingRevenue']?.toString() ?? '0') ?? 0.0,
    );
  }

  static const zero = ClientOrderKpis(inProgressCount: 0, pendingRevenue: 0);
}

class ClientOrder {
  final String id;
  final String orderNumber;
  final String tenantId;
  final String customerId;
  final String? customerName;
  final String status;
  final double? depositAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final List<ClientOrderLine> lines;

  const ClientOrder({
    required this.id,
    required this.orderNumber,
    required this.tenantId,
    required this.customerId,
    this.customerName,
    required this.status,
    this.depositAmount,
    this.notes,
    required this.createdAt,
    this.deliveredAt,
    required this.lines,
  });

  double get totalAmount =>
      lines.fold(0.0, (sum, l) => sum + l.quantity * l.unitPrice);

  factory ClientOrder.fromJson(Map<String, dynamic> json) {
    final linesJson = json['lines'] as List<dynamic>? ?? [];
    return ClientOrder(
      id: json['id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      customerName: json['customerName'] as String?,
      status: json['status'] as String? ?? 'draft',
      depositAmount: json['depositAmount'] != null
          ? double.tryParse(json['depositAmount'].toString())
          : null,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'].toString())
          : null,
      lines: linesJson
          .map((l) => ClientOrderLine.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }
}
