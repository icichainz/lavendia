import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/analytics_model.dart';
import '../services/analytics_service.dart';
import '../services/file_service.dart';

class AnalyticsProvider with ChangeNotifier {
  final _analyticsService = AnalyticsService();
  final _fileService = FileService();

  // State
  AnalyticsOverview? _overview;
  List<RevenueTrend> _revenueTrends = [];
  List<StatusDistribution> _statusDistribution = [];
  List<TopCustomer> _topCustomers = [];
  List<StaffPerformance> _staffPerformance = [];
  List<LaundromatComparison> _laundromatComparison = [];
  List<PeakHours> _peakHours = [];

  bool _isLoading = false;
  bool _isExporting = false;
  String? _errorMessage;
  String _currentTimeRange = 'month';

  // Getters
  AnalyticsOverview? get overview => _overview;
  List<RevenueTrend> get revenueTrends => _revenueTrends;
  List<StatusDistribution> get statusDistribution => _statusDistribution;
  List<TopCustomer> get topCustomers => _topCustomers;
  List<StaffPerformance> get staffPerformance => _staffPerformance;
  List<LaundromatComparison> get laundromatComparison => _laundromatComparison;
  List<PeakHours> get peakHours => _peakHours;
  bool get isLoading => _isLoading;
  bool get isExporting => _isExporting;
  String? get errorMessage => _errorMessage;
  String get currentTimeRange => _currentTimeRange;

  // Time range options
  static const List<Map<String, String>> timeRangeOptions = [
    {'value': 'today', 'label': 'Today'},
    {'value': 'week', 'label': 'Week'},
    {'value': 'month', 'label': 'Month'},
    {'value': 'quarter', 'label': 'Quarter'},
    {'value': 'year', 'label': 'Year'},
  ];

  /// Set time range and refresh data
  void setTimeRange(String timeRange) {
    if (_currentTimeRange != timeRange) {
      _currentTimeRange = timeRange;
      notifyListeners();
      fetchAllAnalytics();
    }
  }

  /// Fetch analytics overview
  Future<void> fetchOverview() async {
    try {
      final result = await _analyticsService.getOverview(
        timeRange: _currentTimeRange,
      );

      if (result['success']) {
        _overview = result['overview'];
      } else {
        _errorMessage = result['message'];
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  /// Fetch revenue trend
  Future<void> fetchRevenueTrend() async {
    try {
      final result = await _analyticsService.getRevenueTrend(
        timeRange: _currentTimeRange,
      );

      if (result['success']) {
        _revenueTrends = result['trends'] ?? [];
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  /// Fetch status distribution
  Future<void> fetchStatusDistribution() async {
    try {
      final result = await _analyticsService.getStatusDistribution(
        timeRange: _currentTimeRange,
      );

      if (result['success']) {
        _statusDistribution = result['distribution'] ?? [];
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  /// Fetch top customers
  Future<void> fetchTopCustomers() async {
    try {
      final result = await _analyticsService.getTopCustomers(
        timeRange: _currentTimeRange,
      );

      if (result['success']) {
        _topCustomers = result['customers'] ?? [];
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  /// Fetch staff performance
  Future<void> fetchStaffPerformance() async {
    try {
      final result = await _analyticsService.getStaffPerformance(
        timeRange: _currentTimeRange,
      );

      if (result['success']) {
        _staffPerformance = result['performance'] ?? [];
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  /// Fetch laundromat comparison (admin only)
  Future<void> fetchLaundromatComparison() async {
    try {
      final result = await _analyticsService.getLaundromatComparison(
        timeRange: _currentTimeRange,
      );

      if (result['success']) {
        _laundromatComparison = result['comparison'] ?? [];
      }
    } catch (e) {
      // Silently fail for non-admin users
    }
  }

  /// Fetch peak hours
  Future<void> fetchPeakHours() async {
    try {
      final result = await _analyticsService.getPeakHours(
        timeRange: _currentTimeRange,
      );

      if (result['success']) {
        _peakHours = result['peakHours'] ?? [];
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  /// Fetch all analytics data in parallel
  Future<void> fetchAllAnalytics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchOverview(),
        fetchRevenueTrend(),
        fetchStatusDistribution(),
        fetchTopCustomers(),
        fetchStaffPerformance(),
        fetchLaundromatComparison(),
        fetchPeakHours(),
      ]);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Export analytics as PDF
  Future<Map<String, dynamic>> exportPDF() async {
    _isExporting = true;
    notifyListeners();

    try {
      final result = await _analyticsService.exportPDF(
        timeRange: _currentTimeRange,
      );

      if (result['success']) {
        final Uint8List data = result['data'];
        final String filename = result['filename'];

        final saveResult = await _fileService.saveAndSharePDF(
          data,
          filename,
          subject: 'Lavendia Analytics Report',
        );

        _isExporting = false;
        notifyListeners();

        return saveResult;
      } else {
        _isExporting = false;
        notifyListeners();
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to export PDF',
        };
      }
    } catch (e) {
      _isExporting = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Export analytics as CSV
  Future<Map<String, dynamic>> exportCSV() async {
    _isExporting = true;
    notifyListeners();

    try {
      final result = await _analyticsService.exportCSV(
        timeRange: _currentTimeRange,
      );

      if (result['success']) {
        final String data = result['data'];
        final String filename = result['filename'];

        final saveResult = await _fileService.saveAndShareCSV(
          data,
          filename,
          subject: 'Lavendia Transaction Data',
        );

        _isExporting = false;
        notifyListeners();

        return saveResult;
      } else {
        _isExporting = false;
        notifyListeners();
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to export CSV',
        };
      }
    } catch (e) {
      _isExporting = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset all data
  void reset() {
    _overview = null;
    _revenueTrends = [];
    _statusDistribution = [];
    _topCustomers = [];
    _staffPerformance = [];
    _laundromatComparison = [];
    _peakHours = [];
    _isLoading = false;
    _isExporting = false;
    _errorMessage = null;
    _currentTimeRange = 'month';
    notifyListeners();
  }
}
