import './customer.dart';

class Invoice {
  final String id;
  final String businessId;
  final String? customerId;
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime? dueDate;
  final String status;
  final String paymentStatus;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double totalAmount;
  final String? notes;
  final String paymentTerms;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Customer? customer;
  final List<InvoiceLineItem>? lineItems;

  Invoice({
    required this.id,
    required this.businessId,
    this.customerId,
    required this.invoiceNumber,
    required this.issueDate,
    this.dueDate,
    required this.status,
    required this.paymentStatus,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.totalAmount,
    this.notes,
    required this.paymentTerms,
    required this.createdAt,
    required this.updatedAt,
    this.customer,
    this.lineItems,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      customerId: json['customer_id'] as String?,
      invoiceNumber: json['invoice_number'] as String,
      issueDate: DateTime.parse(json['issue_date'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      status: json['status'] as String,
      paymentStatus: json['payment_status'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      taxRate: (json['tax_rate'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      notes: json['notes'] as String?,
      paymentTerms: json['payment_terms'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      customer: json['customers'] != null
          ? Customer.fromJson(json['customers'] as Map<String, dynamic>)
          : null,
      lineItems: json['invoice_line_items'] != null
          ? (json['invoice_line_items'] as List)
              .map((item) =>
                  InvoiceLineItem.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'customer_id': customerId,
      'invoice_number': invoiceNumber,
      'issue_date': issueDate.toIso8601String().split('T')[0],
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'status': status,
      'payment_status': paymentStatus,
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'notes': notes,
      'payment_terms': paymentTerms,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class InvoiceLineItem {
  final String id;
  final String invoiceId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  final DateTime createdAt;

  InvoiceLineItem({
    required this.id,
    required this.invoiceId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.createdAt,
  });

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
      id: json['id'] as String,
      invoiceId: json['invoice_id'] as String,
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      lineTotal: (json['line_total'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'line_total': lineTotal,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
