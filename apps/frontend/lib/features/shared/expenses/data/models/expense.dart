class Expense {
  final String id;
  final String tenantId;
  final String userId;
  final String label;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;

  const Expense({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.label,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? json['tenant_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.parse(json['amount']?.toString() ?? '0'),
      category: json['category']?.toString() ?? 'AUTRE',
      date: DateTime.parse(json['date']?.toString() ?? DateTime.now().toIso8601String()),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'tenantId': tenantId,
        'userId': userId,
        'label': label,
        'amount': amount,
        'category': category,
        'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        if (notes != null) 'notes': notes,
      };
}

/// Human-readable category labels.
const expenseCategoryLabels = {
  'LOYER': 'Loyer',
  'SALAIRE': 'Salaire',
  'ELECTRICITE': 'Électricité',
  'AUTRE': 'Autre',
};
