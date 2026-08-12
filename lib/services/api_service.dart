import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../core/constants/api_constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// RequestOptions.extra marker so a request is retried at most once after a
  /// token refresh.
  static const String _retriedKey = 'lavendia.retriedAfterRefresh';

  late final Dio _dio;

  /// Interceptor-free client used only for the token refresh call, so that a
  /// 401 on refresh cannot re-enter [_onError].
  late final Dio _refreshClient;

  final _storage = StorageService();
  final _logger = Logger();

  // Initialize Dio
  void init() {
    // Each Dio keeps a reference to the BaseOptions it is given, so build a
    // fresh instance per client rather than sharing one mutable object.
    BaseOptions buildOptions() => BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: ApiConstants.headers,
        );

    _dio = Dio(buildOptions());
    _refreshClient = Dio(buildOptions());

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    // Logging interceptor - debug builds only, and never headers or response
    // bodies. LogInterceptor defaults requestHeader to true, which printed
    // `Authorization: Bearer <token>` on every request; responseBody printed
    // the login response verbatim, i.e. both the access and refresh tokens.
    // Neither was gated on build mode, so it shipped in release.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: false,
          logPrint: (obj) => _logger.d(obj),
        ),
      );
    }
  }

  // Request interceptor - add auth token
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    _logger.i('REQUEST[${options.method}] => ${options.uri}');
    handler.next(options);
  }

  // Response interceptor
  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.i('RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}');
    handler.next(response);
  }

  // Error interceptor - handle token refresh
  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    _logger.e('ERROR[${error.response?.statusCode}] => ${error.requestOptions.uri}');

    // Attempt a refresh only for a 401 on a normal request that has not
    // already been retried once. Both guards matter:
    //  - the refresh path itself must never re-enter here, or the interceptor
    //    calls itself on every attempt and recurses unbounded;
    //  - the retry goes back through _dio, so a request that 401s again with
    //    a genuinely fresh token (deactivated user, a view returning 401
    //    rather than 403) would otherwise loop forever, burning one rotated
    //    refresh token per cycle.
    final isRefreshCall =
        error.requestOptions.path.contains(ApiConstants.refresh);
    final alreadyRetried = error.requestOptions.extra[_retriedKey] == true;

    if (error.response?.statusCode == 401 && !isRefreshCall && !alreadyRetried) {
      String? newAccessToken;

      try {
        final refreshToken = await _storage.getRefreshToken();
        if (refreshToken != null) {
          // Refresh over a bare client: _dio carries this interceptor, so
          // reusing it here is the other half of the recursion above.
          final response = await _refreshClient.post(
            ApiConstants.refresh,
            data: {'refresh': refreshToken},
            options: Options(headers: ApiConstants.headers),
          );

          if (response.statusCode == 200) {
            newAccessToken = response.data['access'] as String?;

            if (newAccessToken != null) {
              await _storage.saveAccessToken(newAccessToken);

              // The backend rotates refresh tokens and blacklists the
              // previous one, so the replacement must be stored or the next
              // refresh fails and the user is silently signed out.
              final newRefreshToken = response.data['refresh'] as String?;
              if (newRefreshToken != null) {
                await _storage.saveRefreshToken(newRefreshToken);
              }
            }
          }
        }
      } on DioException catch (e) {
        // Only an authoritative rejection means the session is over. A
        // timeout or connection error at the moment the token expires must
        // not log the user out.
        final status = e.response?.statusCode;
        if (status == 400 || status == 401) {
          _logger.w('Refresh token rejected ($status) - clearing session');
          await _storage.clearUserData();
        } else {
          _logger.e('Token refresh failed transiently: ${e.message}');
        }
      } catch (e) {
        _logger.e('Token refresh failed: $e');
      }

      // Retry outside the try above, so a failure in the retried request is
      // never mistaken for a refresh failure.
      if (newAccessToken != null) {
        try {
          final opts = error.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccessToken';
          opts.extra[_retriedKey] = true;

          // FormData is single-use: it is finalized on send, and reusing the
          // same instance throws StateError. Cloning is what dio provides for
          // exactly this retry case, and it keeps multipart uploads working.
          if (opts.data is FormData) {
            opts.data = (opts.data as FormData).clone();
          }

          // fetch(opts) replays the whole RequestOptions. Rebuilding it by
          // hand dropped responseType (breaking the bytes-mode PDF export),
          // onSendProgress (freezing upload progress UI), contentType and
          // timeouts.
          return handler.resolve(await _dio.fetch(opts));
        } on DioException catch (e) {
          return handler.next(e);
        }
      }
    }

    handler.next(error);
  }

  // ===== HTTP Methods =====

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  // PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  // Upload file (multipart)
  Future<Response> uploadFile(
    String path,
    String filePath,
    String fieldName, {
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...?data,
        fieldName: await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  // POST request with progress callback for multipart uploads
  Future<Response> postWithProgress(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        onSendProgress: onSendProgress,
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  // Handle errors and return user-friendly messages
  String getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        return _handleStatusCode(error.response?.statusCode);
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden. You don\'t have permission.';
      case 404:
        return 'Resource not found.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
