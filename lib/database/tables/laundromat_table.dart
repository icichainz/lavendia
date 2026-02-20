import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/laundromat_model.dart';

class LaundromatTable {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Convert LaundromatModel to Map for database storage
  Map<String, dynamic> toMap(LaundromatModel laundromat) {
    return {
      'id': laundromat.id,
      'name': laundromat.name,
      'address': laundromat.address,
      'phone': laundromat.phone,
      'email': laundromat.email,
      'is_active': laundromat.isActive ? 1 : 0,
      'staff_count': laundromat.staffCount,
      'active_receipts_count': laundromat.activeReceiptsCount,
      'created_at': laundromat.createdAt.toIso8601String(),
      'updated_at': laundromat.updatedAt.toIso8601String(),
      'cached_at': DateTime.now().toIso8601String(),
    };
  }

  /// Convert Map from database to LaundromatModel
  LaundromatModel fromMap(Map<String, dynamic> map) {
    return LaundromatModel(
      id: map['id'] as int,
      name: map['name'] as String,
      address: map['address'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      staffCount: map['staff_count'] as int?,
      activeReceiptsCount: map['active_receipts_count'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Insert or replace a single laundromat
  Future<int> insert(LaundromatModel laundromat) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseHelper.tableLaundromats,
      toMap(laundromat),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert or replace multiple laundromats
  Future<void> insertAll(List<LaundromatModel> laundromats) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final laundromat in laundromats) {
      batch.insert(
        DatabaseHelper.tableLaundromats,
        toMap(laundromat),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get laundromat by ID
  Future<LaundromatModel?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableLaundromats,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return fromMap(maps.first);
  }

  /// Get all laundromats
  Future<List<LaundromatModel>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableLaundromats,
      orderBy: 'name ASC',
    );

    return maps.map((map) => fromMap(map)).toList();
  }

  /// Get active laundromats
  Future<List<LaundromatModel>> getActive() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableLaundromats,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    return maps.map((map) => fromMap(map)).toList();
  }

  /// Delete laundromat by ID
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableLaundromats,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all laundromats
  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return await db.delete(DatabaseHelper.tableLaundromats);
  }

  /// Check if cache is stale (older than given duration)
  Future<bool> isCacheStale(Duration maxAge) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableLaundromats,
      columns: ['cached_at'],
      orderBy: 'cached_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return true;

    final cachedAt = DateTime.parse(maps.first['cached_at'] as String);
    return DateTime.now().difference(cachedAt) > maxAge;
  }
}
