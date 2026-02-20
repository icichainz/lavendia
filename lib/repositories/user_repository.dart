import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../database/tables/user_table.dart';
import '../database/tables/sync_meta_table.dart';

/// Repository for user data with caching support
class UserRepository {
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  final _authService = AuthService();
  final _userService = UserService();
  final _userTable = UserTable();
  final _syncMetaTable = SyncMetaTable();
  final _logger = Logger();

  // Cache TTL configurations
  static const Duration _currentUserTTL = Duration(minutes: 30);
  static const Duration _customersTTL = Duration(minutes: 5);
  static const Duration _staffTTL = Duration(minutes: 5);

  /// Callback for notifying when current user is refreshed
  Function(UserModel)? onCurrentUserRefreshed;

  /// Get current user with caching
  Future<Map<String, dynamic>> getCurrentUser({
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final currentUser = await _userTable.getCurrentUser();

        if (currentUser != null) {
          final isStale = await _userTable.isCacheStale(
            currentUser.id,
            _currentUserTTL,
          );

          if (!isStale) {
            _logger.d('Returning cached current user');
            return {
              'success': true,
              'user': currentUser,
              'fromCache': true,
            };
          }

          // Return cached and refresh in background
          _logger.d('Returning stale user cache, refreshing in background');
          _refreshCurrentUserInBackground();
          return {
            'success': true,
            'user': currentUser,
            'fromCache': true,
            'isRefreshing': true,
          };
        }
      }

      return await _fetchAndCacheCurrentUser();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        final cached = await _userTable.getCurrentUser();
        if (cached != null) {
          _logger.w('Network error, returning cached user');
          return {
            'success': true,
            'user': cached,
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
      _logger.e('Error getting current user: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  void _refreshCurrentUserInBackground() async {
    try {
      final result = await _fetchAndCacheCurrentUser();
      if (result['success'] == true) {
        onCurrentUserRefreshed?.call(result['user']);
      }
    } catch (e) {
      _logger.e('Background refresh failed: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchAndCacheCurrentUser() async {
    final result = await _authService.getCurrentUser();

    if (result['success'] == true) {
      final user = result['user'] as UserModel;
      await _userTable.insert(user);
      await _userTable.setCurrentUserId(user.id);
      await _syncMetaTable.setLastSync(SyncMetaTable.keyCurrentUser);

      _logger.d('Cached current user ${user.id}');
      return {
        'success': true,
        'user': user,
        'fromCache': false,
      };
    }

    return result;
  }

  /// Get all customers with caching
  Future<Map<String, dynamic>> getCustomers({
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final isStale = await _syncMetaTable.isStale(
          SyncMetaTable.keyCustomers,
          _customersTTL,
        );

        final cached = await _userTable.getCustomers();

        if (cached.isNotEmpty && !isStale) {
          _logger.d('Returning cached customers (${cached.length} items)');
          return {
            'success': true,
            'users': cached,
            'fromCache': true,
          };
        }
      }

      return await _fetchAndCacheCustomers();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        final cached = await _userTable.getCustomers();
        if (cached.isNotEmpty) {
          return {
            'success': true,
            'users': cached,
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
      _logger.e('Error getting customers: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _fetchAndCacheCustomers() async {
    try {
      final users = await _userService.getAllCustomers();
      await _userTable.insertAll(users);
      await _syncMetaTable.setLastSync(SyncMetaTable.keyCustomers);

      _logger.d('Cached ${users.length} customers');
      return {
        'success': true,
        'users': users,
        'fromCache': false,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Get all staff with caching
  Future<Map<String, dynamic>> getStaff({
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final isStale = await _syncMetaTable.isStale(
          SyncMetaTable.keyStaff,
          _staffTTL,
        );

        final cached = await _userTable.getStaff();

        if (cached.isNotEmpty && !isStale) {
          _logger.d('Returning cached staff (${cached.length} items)');
          return {
            'success': true,
            'users': cached,
            'fromCache': true,
          };
        }
      }

      return await _fetchAndCacheStaff();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        final cached = await _userTable.getStaff();
        if (cached.isNotEmpty) {
          return {
            'success': true,
            'users': cached,
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
      _logger.e('Error getting staff: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _fetchAndCacheStaff() async {
    try {
      final users = await _userService.getAllStaff();
      await _userTable.insertAll(users);
      await _syncMetaTable.setLastSync(SyncMetaTable.keyStaff);

      _logger.d('Cached ${users.length} staff');
      return {
        'success': true,
        'users': users,
        'fromCache': false,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Get user by ID with caching
  Future<UserModel?> getUserById(int id, {bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final cached = await _userTable.getById(id);
        if (cached != null) {
          final isStale = await _userTable.isCacheStale(id, _currentUserTTL);
          if (!isStale) {
            return cached;
          }
        }
      }

      // Fetch from API if not in cache
      // Note: This requires an API endpoint that might not exist
      // For now, return cached or null
      return await _userTable.getById(id);
    } catch (e) {
      _logger.e('Error getting user by ID: $e');
      return null;
    }
  }

  /// Clear all user cache
  Future<void> clearCache() async {
    await _userTable.deleteAll();
    await _syncMetaTable.delete(SyncMetaTable.keyCurrentUser);
    await _syncMetaTable.delete(SyncMetaTable.keyCustomers);
    await _syncMetaTable.delete(SyncMetaTable.keyStaff);
    await _syncMetaTable.delete('current_user_id');
    _logger.i('User cache cleared');
  }

  /// Cache a user (useful after login or profile update)
  Future<void> cacheUser(UserModel user, {bool isCurrentUser = false}) async {
    await _userTable.insert(user);
    if (isCurrentUser) {
      await _userTable.setCurrentUserId(user.id);
      await _syncMetaTable.setLastSync(SyncMetaTable.keyCurrentUser);
    }
    _logger.d('Cached user ${user.id}');
  }
}
