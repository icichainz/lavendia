import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/receipt_model.dart';

class ReceiptTable {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Convert ReceiptModel to Map for database storage
  Map<String, dynamic> toMap(ReceiptModel receipt) {
    return {
      'id': receipt.id,
      'receipt_number': receipt.receiptNumber,
      'laundromat_id': receipt.laundromatId ?? receipt.laundromat?.id,
      'laundromat_name': receipt.laundromatName ?? receipt.laundromat?.name,
      'customer_id': receipt.customerId ?? receipt.customer?.id,
      'customer_name': receipt.customerName ?? receipt.customer?.fullName,
      'staff_id': receipt.staffId ?? receipt.staff?.id,
      'status': receipt.status,
      'drop_off_date': receipt.dropOffDate.toIso8601String(),
      'expected_pickup_date': receipt.expectedPickupDate.toIso8601String(),
      'actual_pickup_date': receipt.actualPickupDate?.toIso8601String(),
      'items_description': receipt.itemsDescription,
      'items_count': receipt.itemsCount,
      'special_instructions': receipt.specialInstructions,
      'price': receipt.price,
      'qr_code_url': receipt.qrCodeUrl,
      'is_active': receipt.isActive ? 1 : 0,
      'days_since_dropoff': receipt.daysSinceDropoff,
      'created_at': receipt.createdAt.toIso8601String(),
      'updated_at': receipt.updatedAt.toIso8601String(),
      'cached_at': DateTime.now().toIso8601String(),
    };
  }

  /// Convert Map from database to ReceiptModel
  ReceiptModel fromMap(Map<String, dynamic> map) {
    return ReceiptModel(
      id: map['id'] as int,
      receiptNumber: map['receipt_number'] as String,
      laundromatId: map['laundromat_id'] as int?,
      laundromatName: map['laundromat_name'] as String?,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String?,
      staffId: map['staff_id'] as int?,
      status: map['status'] as String,
      dropOffDate: DateTime.parse(map['drop_off_date'] as String),
      expectedPickupDate: DateTime.parse(map['expected_pickup_date'] as String),
      actualPickupDate: map['actual_pickup_date'] != null
          ? DateTime.parse(map['actual_pickup_date'] as String)
          : null,
      itemsDescription: map['items_description'] as String? ?? '',
      itemsCount: map['items_count'] as int? ?? 0,
      specialInstructions: map['special_instructions'] as String?,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      qrCodeUrl: map['qr_code_url'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      daysSinceDropoff: map['days_since_dropoff'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Insert or replace a single receipt
  Future<int> insert(ReceiptModel receipt) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseHelper.tableReceipts,
      toMap(receipt),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert or replace multiple receipts
  Future<void> insertAll(List<ReceiptModel> receipts) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final receipt in receipts) {
      batch.insert(
        DatabaseHelper.tableReceipts,
        toMap(receipt),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get receipt by ID
  Future<ReceiptModel?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableReceipts,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return fromMap(maps.first);
  }

  /// Get all receipts
  Future<List<ReceiptModel>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableReceipts,
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => fromMap(map)).toList();
  }

  /// Get receipts by customer ID
  Future<List<ReceiptModel>> getByCustomerId(int customerId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableReceipts,
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => fromMap(map)).toList();
  }

  /// Get receipts by laundromat ID
  Future<List<ReceiptModel>> getByLaundromatId(int laundromatId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableReceipts,
      where: 'laundromat_id = ?',
      whereArgs: [laundromatId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => fromMap(map)).toList();
  }

  /// Get active receipts
  Future<List<ReceiptModel>> getActive() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableReceipts,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => fromMap(map)).toList();
  }

  /// Get receipts by status
  Future<List<ReceiptModel>> getByStatus(String status) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableReceipts,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => fromMap(map)).toList();
  }

  /// Get receipt statuses as a map (for foreground service comparison)
  Future<Map<String, String>> getStatusMap() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableReceipts,
      columns: ['id', 'status'],
    );

    return {
      for (final map in maps)
        map['id'].toString(): map['status'] as String
    };
  }

  /// Delete receipt by ID
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableReceipts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all receipts
  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return await db.delete(DatabaseHelper.tableReceipts);
  }

  /// Delete receipts by customer ID
  Future<int> deleteByCustomerId(int customerId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableReceipts,
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );
  }

  /// Check if cache is stale (older than given duration)
  Future<bool> isCacheStale(Duration maxAge) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableReceipts,
      columns: ['cached_at'],
      orderBy: 'cached_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return true;

    final cachedAt = DateTime.parse(maps.first['cached_at'] as String);
    return DateTime.now().difference(cachedAt) > maxAge;
  }
}
