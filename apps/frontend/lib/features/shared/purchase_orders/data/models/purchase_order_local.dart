class PurchaseOrderLineLocal {
  final String id;
  final String? catalogItemId;
  final String? itemName;
  final double expectedQuantity;
  final double? receivedQuantity;
  final String? qualityNotes;
  // variantId pre-selected when the PO was created with a specific variant
  final String? variantId;
  // Catalog item traceability flags — drive adaptive form fields
  final bool hasVariants;
  final bool trackSerialNumbers;
  final int? expiryDays;
  // [{id, sku, attributes: {size: 'M', color: 'Bleu'}}]
  final List<Map<String, dynamic>> variants;

  PurchaseOrderLineLocal({
    required this.id,
    this.catalogItemId,
    this.itemName,
    required this.expectedQuantity,
    this.receivedQuantity,
    this.qualityNotes,
    this.variantId,
    this.hasVariants = false,
    this.trackSerialNumbers = false,
    this.expiryDays,
    this.variants = const [],
  });

  factory PurchaseOrderLineLocal.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderLineLocal(
      id: json['id'] as String,
      catalogItemId: json['catalogItemId'] as String?,
      itemName: json['itemName'] as String?,
      expectedQuantity: _toDouble(json['expectedQuantity']),
      receivedQuantity: json['receivedQuantity'] != null
          ? _toDouble(json['receivedQuantity'])
          : null,
      qualityNotes: json['qualityNotes'] as String?,
      variantId: json['variantId'] as String?,
      hasVariants: json['hasVariants'] as bool? ?? false,
      trackSerialNumbers: json['trackSerialNumbers'] as bool? ?? false,
      expiryDays: json['expiryDays'] as int?,
      variants: (json['variants'] as List<dynamic>?)
              ?.map((v) => v as Map<String, dynamic>)
              .toList() ??
          const [],
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class PurchaseOrderLocal {
  final String id;
  final String status;
  final String? supplierId;
  final String? supplierName;
  final DateTime? expectedDate;
  final String? notes;
  final List<PurchaseOrderLineLocal> lines;
  final int lineCount;
  final String tenantId;
  final DateTime createdAt;

  PurchaseOrderLocal({
    required this.id,
    required this.status,
    this.supplierId,
    this.supplierName,
    this.expectedDate,
    this.notes,
    this.lines = const [],
    required this.lineCount,
    required this.tenantId,
    required this.createdAt,
  });

  factory PurchaseOrderLocal.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List<dynamic>?;
    return PurchaseOrderLocal(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'draft',
      supplierId: json['supplierId'] as String?,
      supplierName: json['supplierName'] as String?,
      expectedDate: json['expectedDate'] != null
          ? DateTime.tryParse(json['expectedDate'].toString())
          : null,
      notes: json['notes'] as String?,
      lines: rawLines != null
          ? rawLines
              .map((l) =>
                  PurchaseOrderLineLocal.fromJson(l as Map<String, dynamic>))
              .toList()
          : [],
      lineCount:
          json['lineCount'] as int? ?? rawLines?.length ?? 0,
      tenantId: json['tenantId'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }
}
