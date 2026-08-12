import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../core/constants/api_constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

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

    // Add logging interceptor in debug mode
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => _logger.d(obj),
      ),
    );
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

    // If 401 error, try to refresh token.
    // Skipped when the failing request *is* the refresh call - otherwise this
    // interceptor would call itself on every attempt and recurse unbounded.
    if (error.response?.statusCode == 401 &&
        !error.requestOptions.path.contains(ApiConstants.refresh)) {
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
            final newAccessToken = response.data['access'];
            await _storage.saveAccessToken(newAccessToken);

            // The backend rotates refresh tokens and blacklists the previous
            // one, so the replacement must be stored or the next refresh
            // fails and the user is silently signed out.
            final newRefreshToken = response.data['refresh'] as String?;
            if (newRefreshToken != null) {
              await _storage.saveRefreshToken(newRefreshToken);
            }

            // Retry the original request
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';

            final cloneReq = await _dio.request(
              opts.path,
              options: Options(
                method: opts.method,
                headers: opts.headers,
              ),
              data: opts.data,
              queryParameters: opts.queryParameters,
            );

            return handler.resolve(cloneReq);
          }
        }
      } catch (e) {
        _logger.e('Token refresh failed: $e');
        // Clear tokens and redirect to login
        await _storage.clearUserData();
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
