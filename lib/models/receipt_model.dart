import 'user_model.dart';
import 'laundromat_model.dart';
import 'video_model.dart';

class ReceiptModel {
  final int id;
  final String receiptNumber;
  final LaundromatModel? laundromat;
  final int? laundromatId;
  final String? laundromatName;
  final UserModel? customer;
  final int? customerId;
  final String? customerName;
  final UserModel? staff;
  final int? staffId;
  final String status;
  final DateTime dropOffDate;
  final DateTime expectedPickupDate;
  final DateTime? actualPickupDate;
  final String itemsDescription;
  final int itemsCount;
  final String? specialInstructions;
  final double price;
  final String? qrCodeUrl;
  final List<VideoModel>? videos;
  final bool isActive;
  final int? daysSinceDropoff;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReceiptModel({
    required this.id,
    required this.receiptNumber,
    this.laundromat,
    this.laundromatId,
    this.laundromatName,
    this.customer,
    this.customerId,
    this.customerName,
    this.staff,
    this.staffId,
    required this.status,
    required this.dropOffDate,
    required this.expectedPickupDate,
    this.actualPickupDate,
    required this.itemsDescription,
    required this.itemsCount,
    this.specialInstructions,
    required this.price,
    this.qrCodeUrl,
    this.videos,
    required this.isActive,
    this.daysSinceDropoff,
    required this.createdAt,
    required this.updatedAt,
  });

  // Status checks
  bool get isPending => status == 'pending';
  bool get isWashing => status == 'washing';
  bool get isDrying => status == 'drying';
  bool get isReady => status == 'ready';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  // Get status display
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'washing':
        return 'Washing';
      case 'drying':
        return 'Drying';
      case 'ready':
        return 'Ready for Pickup';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  // Get intake video
  VideoModel? get intakeVideo {
    return videos?.firstWhere(
      (v) => v.videoType == 'intake',
      orElse: () => videos!.first,
    );
  }

  // Get completion video
  VideoModel? get completionVideo {
    return videos?.firstWhere(
      (v) => v.videoType == 'completion',
      orElse: () => videos!.first,
    );
  }

  // Check if has videos
  bool get hasVideos => videos != null && videos!.isNotEmpty;

  // From JSON
  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      id: json['id'] as int,
      receiptNumber: json['receipt_number'] as String,
      laundromat: json['laundromat'] != null && json['laundromat'] is Map
          ? LaundromatModel.fromJson(json['laundromat'] as Map<String, dynamic>)
          : null,
      laundromatId: json['laundromat'] is int ? json['laundromat'] as int : null,
      laundromatName: json['laundromat_name'] as String?,
      customer: json['customer'] != null && json['customer'] is Map
          ? UserModel.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      customerId: json['customer'] is int ? json['customer'] as int : null,
      customerName: json['customer_name'] as String?,
      staff: json['staff'] != null && json['staff'] is Map
          ? UserModel.fromJson(json['staff'] as Map<String, dynamic>)
          : null,
      staffId: json['staff'] is int ? json['staff'] as int : null,
      status: json['status'] as String,
      dropOffDate: DateTime.parse(json['drop_off_date'] as String),
      expectedPickupDate: DateTime.parse(json['expected_pickup_date'] as String),
      actualPickupDate: json['actual_pickup_date'] != null
          ? DateTime.parse(json['actual_pickup_date'] as String)
          : null,
      // Handle minimal list response (may not include items_description/items_count)
      itemsDescription: json['items_description'] as String? ?? '',
      itemsCount: json['items_count'] as int? ?? 0,
      specialInstructions: json['special_instructions'] as String?,
      price: json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      qrCodeUrl: json['qr_code_url'] as String?,
      videos: json['videos'] != null
          ? (json['videos'] as List).map((v) => VideoModel.fromJson(v as Map<String, dynamic>)).toList()
          : null,
      isActive: json['is_active'] as bool? ?? true,
      daysSinceDropoff: json['days_since_dropoff'] as int?,
      // Handle minimal list response (may not include created_at/updated_at)
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  // To JSON (for creating/updating)
  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'staff_id': staffId,
      'laundromat_id': laundromatId,
      'expected_pickup_date': expectedPickupDate.toIso8601String(),
      'items_description': itemsDescription,
      'items_count': itemsCount,
      'special_instructions': specialInstructions,
      'price': price,
    };
  }

  // Copy with
  ReceiptModel copyWith({
    int? id,
    String? receiptNumber,
    LaundromatModel? laundromat,
    int? laundromatId,
    String? laundromatName,
    UserModel? customer,
    int? customerId,
    String? customerName,
    UserModel? staff,
    int? staffId,
    String? status,
    DateTime? dropOffDate,
    DateTime? expectedPickupDate,
    DateTime? actualPickupDate,
    String? itemsDescription,
    int? itemsCount,
    String? specialInstructions,
    double? price,
    String? qrCodeUrl,
    List<VideoModel>? videos,
    bool? isActive,
    int? daysSinceDropoff,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReceiptModel(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      laundromat: laundromat ?? this.laundromat,
      laundromatId: laundromatId ?? this.laundromatId,
      laundromatName: laundromatName ?? this.laundromatName,
      customer: customer ?? this.customer,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      staff: staff ?? this.staff,
      staffId: staffId ?? this.staffId,
      status: status ?? this.status,
      dropOffDate: dropOffDate ?? this.dropOffDate,
      expectedPickupDate: expectedPickupDate ?? this.expectedPickupDate,
      actualPickupDate: actualPickupDate ?? this.actualPickupDate,
      itemsDescription: itemsDescription ?? this.itemsDescription,
      itemsCount: itemsCount ?? this.itemsCount,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      price: price ?? this.price,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      videos: videos ?? this.videos,
      isActive: isActive ?? this.isActive,
      daysSinceDropoff: daysSinceDropoff ?? this.daysSinceDropoff,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
