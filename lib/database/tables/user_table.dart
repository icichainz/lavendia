import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/user_model.dart';

class UserTable {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Convert UserModel to Map for database storage
  Map<String, dynamic> toMap(UserModel user) {
    return {
      'id': user.id,
      'username': user.username,
      'email': user.email,
      'phone': user.phone,
      'role': user.role,
      'first_name': user.firstName,
      'last_name': user.lastName,
      'profile_picture_url': user.profilePictureUrl,
      'laundromat_id': user.laundromatId,
      'laundromat_name': user.laundromatName,
      'is_active': user.isActive ? 1 : 0,
      'created_at': user.createdAt.toIso8601String(),
      'updated_at': user.updatedAt.toIso8601String(),
      'cached_at': DateTime.now().toIso8601String(),
    };
  }

  /// Convert Map from database to UserModel
  UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      username: map['username'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      role: map['role'] as String,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      profilePictureUrl: map['profile_picture_url'] as String?,
      laundromatId: map['laundromat_id'] as int?,
      laundromatName: map['laundromat_name'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Insert or replace a single user
  Future<int> insert(UserModel user) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseHelper.tableUsers,
      toMap(user),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert or replace multiple users
  Future<void> insertAll(List<UserModel> users) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final user in users) {
      batch.insert(
        DatabaseHelper.tableUsers,
        toMap(user),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get user by ID
  Future<UserModel?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return fromMap(maps.first);
  }

  /// Get all users
  Future<List<UserModel>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableUsers,
      orderBy: 'username ASC',
    );

    return maps.map((map) => fromMap(map)).toList();
  }

  /// Get users by role
  Future<List<UserModel>> getByRole(String role) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableUsers,
      where: 'role = ?',
      whereArgs: [role],
      orderBy: 'username ASC',
    );

    return maps.map((map) => fromMap(map)).toList();
  }

  /// Get customers only
  Future<List<UserModel>> getCustomers() async {
    return getByRole('customer');
  }

  /// Get staff only
  Future<List<UserModel>> getStaff() async {
    return getByRole('staff');
  }

  /// Get current user (usually stored with a specific key in sync_meta)
  Future<UserModel?> getCurrentUser() async {
    final db = await _dbHelper.database;

    // Get current user ID from sync_meta
    final meta = await db.query(
      DatabaseHelper.tableSyncMeta,
      where: 'key = ?',
      whereArgs: ['current_user_id'],
    );

    if (meta.isEmpty) return null;

    final userId = int.tryParse(meta.first['last_sync'] as String);
    if (userId == null) return null;

    return getById(userId);
  }

  /// Set current user ID
  Future<void> setCurrentUserId(int userId) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableSyncMeta,
      {
        'key': 'current_user_id',
        'last_sync': userId.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete user by ID
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all users
  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return await db.delete(DatabaseHelper.tableUsers);
  }

  /// Check if cache is stale (older than given duration)
  Future<bool> isCacheStale(int userId, Duration maxAge) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableUsers,
      columns: ['cached_at'],
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) return true;

    final cachedAt = DateTime.parse(maps.first['cached_at'] as String);
    return DateTime.now().difference(cachedAt) > maxAge;
  }
}
