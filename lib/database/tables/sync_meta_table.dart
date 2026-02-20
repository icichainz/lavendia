import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

/// Class to manage sync metadata for cache invalidation
class SyncMetaTable {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Set last sync time for a key
  Future<void> setLastSync(String key, {String? etag}) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableSyncMeta,
      {
        'key': key,
        'last_sync': DateTime.now().toIso8601String(),
        'etag': etag,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get last sync time for a key
  Future<DateTime?> getLastSync(String key) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableSyncMeta,
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isEmpty) return null;
    return DateTime.parse(maps.first['last_sync'] as String);
  }

  /// Get ETag for a key
  Future<String?> getEtag(String key) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableSyncMeta,
      columns: ['etag'],
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isEmpty) return null;
    return maps.first['etag'] as String?;
  }

  /// Check if a key's cache is stale
  Future<bool> isStale(String key, Duration maxAge) async {
    final lastSync = await getLastSync(key);
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > maxAge;
  }

  /// Delete sync meta for a key
  Future<int> delete(String key) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableSyncMeta,
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  /// Delete all sync meta
  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return await db.delete(DatabaseHelper.tableSyncMeta);
  }

  /// Common sync keys
  static const String keyMyReceipts = 'my_receipts';
  static const String keyActiveReceipts = 'active_receipts';
  static const String keyAllReceipts = 'all_receipts';
  static const String keyCurrentUser = 'current_user';
  static const String keyLaundromats = 'laundromats';
  static const String keyCustomers = 'customers';
  static const String keyStaff = 'staff';

  /// Generate key for receipt detail
  static String keyReceiptDetail(int id) => 'receipt_$id';

  /// Generate key for receipt videos
  static String keyReceiptVideos(int id) => 'receipt_videos_$id';

  /// Generate key for user detail
  static String keyUserDetail(int id) => 'user_$id';
}
