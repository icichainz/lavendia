class LaundromatModel {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String? email;
  final bool isActive;
  final int? staffCount;
  final int? activeReceiptsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  LaundromatModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.email,
    required this.isActive,
    this.staffCount,
    this.activeReceiptsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  // From JSON
  factory LaundromatModel.fromJson(Map<String, dynamic> json) {
    return LaundromatModel(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      staffCount: json['staff_count'] as int?,
      activeReceiptsCount: json['active_receipts_count'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Copy with
  LaundromatModel copyWith({
    int? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    bool? isActive,
    int? staffCount,
    int? activeReceiptsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LaundromatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      staffCount: staffCount ?? this.staffCount,
      activeReceiptsCount: activeReceiptsCount ?? this.activeReceiptsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
