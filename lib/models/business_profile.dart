class BusinessProfile {
  final String id;
  final String ownerId;
  final String businessName;
  final String businessType;
  final String? taxNumber;
  final String? address;
  final String? phone;
  final String? email;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessProfile({
    required this.id,
    required this.ownerId,
    required this.businessName,
    required this.businessType,
    this.taxNumber,
    this.address,
    this.phone,
    this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) {
    return BusinessProfile(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      businessName: json['business_name'] as String,
      businessType: json['business_type'] as String,
      taxNumber: json['tax_number'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'business_name': businessName,
      'business_type': businessType,
      'tax_number': taxNumber,
      'address': address,
      'phone': phone,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
