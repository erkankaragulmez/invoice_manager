class Expense {
  final String id;
  final String businessId;
  final String category;
  final String description;
  final double amount;
  final DateTime expenseDate;
  final String? receiptUrl;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.businessId,
    required this.category,
    required this.description,
    required this.amount,
    required this.expenseDate,
    this.receiptUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      expenseDate: DateTime.parse(json['expense_date'] as String),
      receiptUrl: json['receipt_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'category': category,
      'description': description,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'receipt_url': receiptUrl,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
