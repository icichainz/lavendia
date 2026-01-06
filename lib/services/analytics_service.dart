import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/analytics_model.dart';
import 'api_service.dart';

class AnalyticsService {
  final _apiService = ApiService();
  final _logger = Logger();

  /// Get analytics overview
  Future<Map<String, dynamic>> getOverview({String timeRange = 'month'}) async {
    try {
      final response = await _apiService.get(
        '/analytics/overview/',
        queryParameters: {'time_range': timeRange},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'overview': AnalyticsOverview.fromJson(response.data),
        };
      }

      return {
        'success': false,
        'message': 'Failed to fetch analytics overview',
      };
    } on DioException catch (e) {
      _logger.e('Error fetching analytics overview: $e');
      return {
        'success': false,
        'message': _apiService.getErrorMessage(e),
      };
    } catch (e) {
      _logger.e('Unexpected error fetching analytics overview: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get revenue trend data for charts
  Future<Map<String, dynamic>> getRevenueTrend({String timeRange = 'month'}) async {
    try {
      final response = await _apiService.get(
        '/analytics/revenue-trend/',
        queryParameters: {'time_range': timeRange},
      );

      if (response.statusCode == 200) {
        final List<RevenueTrend> trends = (response.data as List)
            .map((json) => RevenueTrend.fromJson(json))
            .toList();

        return {
          'success': true,
          'trends': trends,
        };
      }

      return {
        'success': false,
        'message': 'Failed to fetch revenue trend',
      };
    } on DioException catch (e) {
      _logger.e('Error fetching revenue trend: $e');
      return {
        'success': false,
        'message': _apiService.getErrorMessage(e),
      };
    } catch (e) {
      _logger.e('Unexpected error fetching revenue trend: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get order status distribution
  Future<Map<String, dynamic>> getStatusDistribution({String timeRange = 'month'}) async {
    try {
      final response = await _apiService.get(
        '/analytics/order-status-distribution/',
        queryParameters: {'time_range': timeRange},
      );

      if (response.statusCode == 200) {
        final List<StatusDistribution> distribution = (response.data as List)
            .map((json) => StatusDistribution.fromJson(json))
            .toList();

        return {
          'success': true,
          'distribution': distribution,
        };
      }

      return {
        'success': false,
        'message': 'Failed to fetch status distribution',
      };
    } on DioException catch (e) {
      _logger.e('Error fetching status distribution: $e');
      return {
        'success': false,
        'message': _apiService.getErrorMessage(e),
      };
    } catch (e) {
      _logger.e('Unexpected error fetching status distribution: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get top customers
  Future<Map<String, dynamic>> getTopCustomers({
    String timeRange = 'month',
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get(
        '/analytics/top-customers/',
        queryParameters: {
          'time_range': timeRange,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<TopCustomer> customers = (response.data as List)
            .map((json) => TopCustomer.fromJson(json))
            .toList();

        return {
          'success': true,
          'customers': customers,
        };
      }

      return {
        'success': false,
        'message': 'Failed to fetch top customers',
      };
    } on DioException catch (e) {
      _logger.e('Error fetching top customers: $e');
      return {
        'success': false,
        'message': _apiService.getErrorMessage(e),
      };
    } catch (e) {
      _logger.e('Unexpected error fetching top customers: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get staff performance metrics
  Future<Map<String, dynamic>> getStaffPerformance({String timeRange = 'month'}) async {
    try {
      final response = await _apiService.get(
        '/analytics/staff-performance/',
        queryParameters: {'time_range': timeRange},
      );

      if (response.statusCode == 200) {
        final List<StaffPerformance> performance = (response.data as List)
            .map((json) => StaffPerformance.fromJson(json))
            .toList();

        return {
          'success': true,
          'performance': performance,
        };
      }

      return {
        'success': false,
        'message': 'Failed to fetch staff performance',
      };
    } on DioException catch (e) {
      _logger.e('Error fetching staff performance: $e');
      return {
        'success': false,
        'message': _apiService.getErrorMessage(e),
      };
    } catch (e) {
      _logger.e('Unexpected error fetching staff performance: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get laundromat comparison (admin only)
  Future<Map<String, dynamic>> getLaundromatComparison({String timeRange = 'month'}) async {
    try {
      final response = await _apiService.get(
        '/analytics/laundromat-comparison/',
        queryParameters: {'time_range': timeRange},
      );

      if (response.statusCode == 200) {
        final List<LaundromatComparison> comparison = (response.data as List)
            .map((json) => LaundromatComparison.fromJson(json))
            .toList();

        return {
          'success': true,
          'comparison': comparison,
        };
      }

      return {
        'success': false,
        'message': 'Failed to fetch laundromat comparison',
      };
    } on DioException catch (e) {
      _logger.e('Error fetching laundromat comparison: $e');
      return {
        'success': false,
        'message': _apiService.getErrorMessage(e),
      };
    } catch (e) {
      _logger.e('Unexpected error fetching laundromat comparison: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get peak hours analysis
  Future<Map<String, dynamic>> getPeakHours({String timeRange = 'month'}) async {
    try {
      final response = await _apiService.get(
        '/analytics/peak-hours/',
        queryParameters: {'time_range': timeRange},
      );

      if (response.statusCode == 200) {
        final List<PeakHours> peakHours = (response.data as List)
            .map((json) => PeakHours.fromJson(json))
            .toList();

        return {
          'success': true,
          'peakHours': peakHours,
        };
      }

      return {
        'success': false,
        'message': 'Failed to fetch peak hours',
      };
    } on DioException catch (e) {
      _logger.e('Error fetching peak hours: $e');
      return {
        'success': false,
        'message': _apiService.getErrorMessage(e),
      };
    } catch (e) {
      _logger.e('Unexpected error fetching peak hours: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Export analytics as PDF
  Future<Map<String, dynamic>> exportPDF({String timeRange = 'month'}) async {
    try {
      final response = await _apiService.get(
        '/analytics/export/pdf/',
        queryParameters: {'time_range': timeRange},
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': Uint8List.fromList(response.data),
          'filename': 'lavendia_analytics_$timeRange.pdf',
        };
      }

      return {
        'success': false,
        'message': 'Failed to export PDF',
      };
    } on DioException catch (e) {
      _logger.e('Error exporting PDF: $e');
      return {
        'success': false,
        'message': _apiService.getErrorMessage(e),
      };
    } catch (e) {
      _logger.e('Unexpected error exporting PDF: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Export analytics as CSV
  Future<Map<String, dynamic>> exportCSV({String timeRange = 'month'}) async {
    try {
      final response = await _apiService.get(
        '/analytics/export/csv/',
        queryParameters: {'time_range': timeRange},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'filename': 'lavendia_transactions_$timeRange.csv',
        };
      }

      return {
        'success': false,
        'message': 'Failed to export CSV',
      };
    } on DioException catch (e) {
      _logger.e('Error exporting CSV: $e');
      return {
        'success': false,
        'message': _apiService.getErrorMessage(e),
      };
    } catch (e) {
      _logger.e('Unexpected error exporting CSV: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }
}
