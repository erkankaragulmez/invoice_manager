class Customer {
  final String id;
  final String businessId;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? taxNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.businessId,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.taxNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      taxNumber: json['tax_number'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'tax_number': taxNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
