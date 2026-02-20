import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/video_model.dart';

class VideoTable {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Convert VideoModel to Map for database storage
  Map<String, dynamic> toMap(VideoModel video) {
    return {
      'id': video.id,
      'receipt_id': video.receiptId,
      'video_type': video.videoType,
      'video_file_url': video.videoFileUrl,
      'video_url': video.videoUrl,
      'thumbnail_url': video.thumbnailUrl,
      'duration': video.duration,
      'file_size': video.fileSize,
      'file_size_mb': video.fileSizeMb,
      'uploaded_at': video.uploadedAt.toIso8601String(),
      'updated_at': video.updatedAt.toIso8601String(),
      'cached_at': DateTime.now().toIso8601String(),
    };
  }

  /// Convert Map from database to VideoModel
  VideoModel fromMap(Map<String, dynamic> map) {
    return VideoModel(
      id: map['id'] as int,
      receiptId: map['receipt_id'] as int,
      videoType: map['video_type'] as String,
      videoFileUrl: map['video_file_url'] as String,
      videoUrl: map['video_url'] as String?,
      thumbnailUrl: map['thumbnail_url'] as String?,
      duration: map['duration'] as int?,
      fileSize: map['file_size'] as int?,
      fileSizeMb: (map['file_size_mb'] as num?)?.toDouble(),
      uploadedAt: DateTime.parse(map['uploaded_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Insert or replace a single video
  Future<int> insert(VideoModel video) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseHelper.tableVideos,
      toMap(video),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert or replace multiple videos
  Future<void> insertAll(List<VideoModel> videos) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final video in videos) {
      batch.insert(
        DatabaseHelper.tableVideos,
        toMap(video),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get video by ID
  Future<VideoModel?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableVideos,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return fromMap(maps.first);
  }

  /// Get all videos
  Future<List<VideoModel>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableVideos,
      orderBy: 'uploaded_at DESC',
    );

    return maps.map((map) => fromMap(map)).toList();
  }

  /// Get videos by receipt ID
  Future<List<VideoModel>> getByReceiptId(int receiptId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableVideos,
      where: 'receipt_id = ?',
      whereArgs: [receiptId],
      orderBy: 'uploaded_at ASC',
    );

    return maps.map((map) => fromMap(map)).toList();
  }

  /// Get intake video by receipt ID
  Future<VideoModel?> getIntakeVideo(int receiptId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableVideos,
      where: 'receipt_id = ? AND video_type = ?',
      whereArgs: [receiptId, 'intake'],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return fromMap(maps.first);
  }

  /// Get completion video by receipt ID
  Future<VideoModel?> getCompletionVideo(int receiptId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableVideos,
      where: 'receipt_id = ? AND video_type = ?',
      whereArgs: [receiptId, 'completion'],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return fromMap(maps.first);
  }

  /// Delete video by ID
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableVideos,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all videos
  Future<int> deleteAll() async {
    final db = await _dbHelper.database;
    return await db.delete(DatabaseHelper.tableVideos);
  }

  /// Delete videos by receipt ID
  Future<int> deleteByReceiptId(int receiptId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableVideos,
      where: 'receipt_id = ?',
      whereArgs: [receiptId],
    );
  }

  /// Check if cache is stale (older than given duration)
  Future<bool> isCacheStale(int receiptId, Duration maxAge) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableVideos,
      columns: ['cached_at'],
      where: 'receipt_id = ?',
      whereArgs: [receiptId],
      orderBy: 'cached_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return true;

    final cachedAt = DateTime.parse(maps.first['cached_at'] as String);
    return DateTime.now().difference(cachedAt) > maxAge;
  }
}
