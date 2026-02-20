import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/receipt_model.dart';
import '../services/receipt_service.dart';
import '../database/tables/receipt_table.dart';
import '../database/tables/video_table.dart';
import '../database/tables/sync_meta_table.dart';

/// Repository for receipts with caching support
/// Uses stale-while-revalidate pattern for optimal UX
class ReceiptRepository {
  static final ReceiptRepository _instance = ReceiptRepository._internal();
  factory ReceiptRepository() => _instance;
  ReceiptRepository._internal();

  final _receiptService = ReceiptService();
  final _receiptTable = ReceiptTable();
  final _videoTable = VideoTable();
  final _syncMetaTable = SyncMetaTable();
  final _logger = Logger();

  // Cache TTL configurations
  static const Duration _myReceiptsTTL = Duration(seconds: 30);
  static const Duration _activeReceiptsTTL = Duration(seconds: 30);
  static const Duration _receiptDetailTTL = Duration(minutes: 1);
  static const Duration _allReceiptsTTL = Duration(minutes: 1);

  /// Callback for notifying when data is refreshed in background
  Function(List<ReceiptModel>)? onMyReceiptsRefreshed;
  Function(List<ReceiptModel>)? onActiveReceiptsRefreshed;
  Function(ReceiptModel)? onReceiptDetailRefreshed;

  /// Get my receipts (for customers)
  /// Returns cached data immediately, then refreshes in background
  Future<Map<String, dynamic>> getMyReceipts({
    String? search,
    bool forceRefresh = false,
    int? currentUserId,
  }) async {
    try {
      // Check cache first
      if (!forceRefresh && currentUserId != null) {
        final isStale = await _syncMetaTable.isStale(
          SyncMetaTable.keyMyReceipts,
          _myReceiptsTTL,
        );

        final cached = await _receiptTable.getByCustomerId(currentUserId);

        if (cached.isNotEmpty) {
          if (!isStale) {
            _logger.d('Returning cached my receipts (${cached.length} items)');
            return {
              'success': true,
              'receipts': cached,
              'fromCache': true,
            };
          }

          // Return cached data and refresh in background
          _logger.d('Returning stale cache, refreshing in background');
          _refreshMyReceiptsInBackground(search: search, currentUserId: currentUserId);
          return {
            'success': true,
            'receipts': cached,
            'fromCache': true,
            'isRefreshing': true,
          };
        }
      }

      // Fetch from API
      return await _fetchAndCacheMyReceipts(search: search, currentUserId: currentUserId);
    } on DioException catch (e) {
      // On network error, return cached data if available
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        if (currentUserId != null) {
          final cached = await _receiptTable.getByCustomerId(currentUserId);
          if (cached.isNotEmpty) {
            _logger.w('Network error, returning cached data');
            return {
              'success': true,
              'receipts': cached,
              'fromCache': true,
              'offline': true,
            };
          }
        }
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      _logger.e('Error getting my receipts: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Background refresh for my receipts
  void _refreshMyReceiptsInBackground({String? search, int? currentUserId}) async {
    try {
      final result = await _fetchAndCacheMyReceipts(
        search: search,
        currentUserId: currentUserId,
      );
      if (result['success'] == true) {
        onMyReceiptsRefreshed?.call(result['receipts']);
      }
    } catch (e) {
      _logger.e('Background refresh failed: $e');
    }
  }

  /// Fetch and cache my receipts
  Future<Map<String, dynamic>> _fetchAndCacheMyReceipts({
    String? search,
    int? currentUserId,
  }) async {
    final result = await _receiptService.getMyReceipts(search: search);

    if (result['success'] == true) {
      final receipts = result['receipts'] as List<ReceiptModel>;

      // Cache the receipts
      await _receiptTable.insertAll(receipts);

      // Cache videos if present
      for (final receipt in receipts) {
        if (receipt.videos != null && receipt.videos!.isNotEmpty) {
          await _videoTable.insertAll(receipt.videos!);
        }
      }

      // Update sync metadata
      await _syncMetaTable.setLastSync(SyncMetaTable.keyMyReceipts);

      _logger.d('Cached ${receipts.length} my receipts');
      return {
        'success': true,
        'receipts': receipts,
        'fromCache': false,
      };
    }

    return result;
  }

  /// Get active receipts (for staff)
  Future<Map<String, dynamic>> getActiveReceipts({
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final isStale = await _syncMetaTable.isStale(
          SyncMetaTable.keyActiveReceipts,
          _activeReceiptsTTL,
        );

        final cached = await _receiptTable.getActive();

        if (cached.isNotEmpty) {
          if (!isStale) {
            _logger.d('Returning cached active receipts (${cached.length} items)');
            return {
              'success': true,
              'receipts': cached,
              'fromCache': true,
            };
          }

          _logger.d('Returning stale cache, refreshing in background');
          _refreshActiveReceiptsInBackground();
          return {
            'success': true,
            'receipts': cached,
            'fromCache': true,
            'isRefreshing': true,
          };
        }
      }

      return await _fetchAndCacheActiveReceipts();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        final cached = await _receiptTable.getActive();
        if (cached.isNotEmpty) {
          _logger.w('Network error, returning cached data');
          return {
            'success': true,
            'receipts': cached,
            'fromCache': true,
            'offline': true,
          };
        }
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      _logger.e('Error getting active receipts: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  void _refreshActiveReceiptsInBackground() async {
    try {
      final result = await _fetchAndCacheActiveReceipts();
      if (result['success'] == true) {
        onActiveReceiptsRefreshed?.call(result['receipts']);
      }
    } catch (e) {
      _logger.e('Background refresh failed: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchAndCacheActiveReceipts() async {
    final result = await _receiptService.getActiveReceipts();

    if (result['success'] == true) {
      final receipts = result['receipts'] as List<ReceiptModel>;
      await _receiptTable.insertAll(receipts);

      for (final receipt in receipts) {
        if (receipt.videos != null && receipt.videos!.isNotEmpty) {
          await _videoTable.insertAll(receipt.videos!);
        }
      }

      await _syncMetaTable.setLastSync(SyncMetaTable.keyActiveReceipts);
      _logger.d('Cached ${receipts.length} active receipts');

      return {
        'success': true,
        'receipts': receipts,
        'fromCache': false,
      };
    }

    return result;
  }

  /// Get all receipts with optional filters
  Future<Map<String, dynamic>> getReceipts({
    String? status,
    int? laundromatId,
    String? search,
    bool forceRefresh = false,
  }) async {
    try {
      // For filtered queries, always fetch from API but cache results
      if (status != null || laundromatId != null || search != null) {
        return await _fetchAndCacheReceipts(
          status: status,
          laundromatId: laundromatId,
          search: search,
        );
      }

      if (!forceRefresh) {
        final isStale = await _syncMetaTable.isStale(
          SyncMetaTable.keyAllReceipts,
          _allReceiptsTTL,
        );

        final cached = await _receiptTable.getAll();

        if (cached.isNotEmpty && !isStale) {
          _logger.d('Returning cached all receipts (${cached.length} items)');
          return {
            'success': true,
            'receipts': cached,
            'fromCache': true,
          };
        }
      }

      return await _fetchAndCacheReceipts(
        status: status,
        laundromatId: laundromatId,
        search: search,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        final cached = await _receiptTable.getAll();
        if (cached.isNotEmpty) {
          return {
            'success': true,
            'receipts': cached,
            'fromCache': true,
            'offline': true,
          };
        }
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      _logger.e('Error getting receipts: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _fetchAndCacheReceipts({
    String? status,
    int? laundromatId,
    String? search,
  }) async {
    final result = await _receiptService.getReceipts(
      status: status,
      laundromatId: laundromatId,
      search: search,
    );

    if (result['success'] == true) {
      final receipts = result['receipts'] as List<ReceiptModel>;
      await _receiptTable.insertAll(receipts);

      for (final receipt in receipts) {
        if (receipt.videos != null && receipt.videos!.isNotEmpty) {
          await _videoTable.insertAll(receipt.videos!);
        }
      }

      if (status == null && laundromatId == null && search == null) {
        await _syncMetaTable.setLastSync(SyncMetaTable.keyAllReceipts);
      }

      _logger.d('Cached ${receipts.length} receipts');
      return {
        'success': true,
        'receipts': receipts,
        'fromCache': false,
      };
    }

    return result;
  }

  /// Get receipt detail
  Future<Map<String, dynamic>> getReceiptDetail(
    int id, {
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final key = SyncMetaTable.keyReceiptDetail(id);
        final isStale = await _syncMetaTable.isStale(key, _receiptDetailTTL);

        final cached = await _receiptTable.getById(id);

        if (cached != null && !isStale) {
          // Also get cached videos
          final videos = await _videoTable.getByReceiptId(id);
          final receiptWithVideos = cached.copyWith(videos: videos);

          _logger.d('Returning cached receipt detail for $id');
          return {
            'success': true,
            'receipt': receiptWithVideos,
            'fromCache': true,
          };
        }
      }

      return await _fetchAndCacheReceiptDetail(id);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        final cached = await _receiptTable.getById(id);
        if (cached != null) {
          final videos = await _videoTable.getByReceiptId(id);
          return {
            'success': true,
            'receipt': cached.copyWith(videos: videos),
            'fromCache': true,
            'offline': true,
          };
        }
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    } catch (e) {
      _logger.e('Error getting receipt detail: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _fetchAndCacheReceiptDetail(int id) async {
    final result = await _receiptService.getReceiptDetail(id);

    if (result['success'] == true) {
      final receipt = result['receipt'] as ReceiptModel;
      await _receiptTable.insert(receipt);

      if (receipt.videos != null && receipt.videos!.isNotEmpty) {
        await _videoTable.insertAll(receipt.videos!);
      }

      await _syncMetaTable.setLastSync(SyncMetaTable.keyReceiptDetail(id));
      _logger.d('Cached receipt detail for $id');

      return {
        'success': true,
        'receipt': receipt,
        'fromCache': false,
      };
    }

    return result;
  }

  /// Create receipt (always goes to API, then caches result)
  Future<Map<String, dynamic>> createReceipt({
    required int customerId,
    required int laundromatId,
    required int staffId,
    required DateTime expectedPickupDate,
    required String itemsDescription,
    required int itemsCount,
    required double price,
    String? specialInstructions,
  }) async {
    final result = await _receiptService.createReceipt(
      customerId: customerId,
      laundromatId: laundromatId,
      staffId: staffId,
      expectedPickupDate: expectedPickupDate,
      itemsDescription: itemsDescription,
      itemsCount: itemsCount,
      price: price,
      specialInstructions: specialInstructions,
    );

    if (result['success'] == true) {
      final receipt = result['receipt'] as ReceiptModel;
      await _receiptTable.insert(receipt);
      _logger.d('Cached new receipt ${receipt.id}');
    }

    return result;
  }

  /// Update receipt status (always goes to API, then updates cache)
  Future<Map<String, dynamic>> updateReceiptStatus(int id, String status) async {
    final result = await _receiptService.updateReceiptStatus(id, status);

    if (result['success'] == true) {
      final receipt = result['receipt'] as ReceiptModel;
      await _receiptTable.insert(receipt);
      _logger.d('Updated cached receipt $id status to $status');
    }

    return result;
  }

  /// Complete receipt (always goes to API, then updates cache)
  Future<Map<String, dynamic>> completeReceipt(int id) async {
    final result = await _receiptService.completeReceipt(id);

    if (result['success'] == true) {
      final receipt = result['receipt'] as ReceiptModel;
      await _receiptTable.insert(receipt);
      _logger.d('Marked cached receipt $id as completed');
    }

    return result;
  }

  /// Get cached receipt statuses (for foreground service)
  Future<Map<String, String>> getCachedReceiptStatuses() async {
    return await _receiptTable.getStatusMap();
  }

  /// Clear all receipt cache
  Future<void> clearCache() async {
    await _receiptTable.deleteAll();
    await _videoTable.deleteAll();
    await _syncMetaTable.delete(SyncMetaTable.keyMyReceipts);
    await _syncMetaTable.delete(SyncMetaTable.keyActiveReceipts);
    await _syncMetaTable.delete(SyncMetaTable.keyAllReceipts);
    _logger.i('Receipt cache cleared');
  }
}
