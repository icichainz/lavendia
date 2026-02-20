import 'package:flutter/material.dart';
import '../models/receipt_model.dart';
import '../repositories/receipt_repository.dart';

class ReceiptProvider with ChangeNotifier {
  final _receiptRepository = ReceiptRepository();

  List<ReceiptModel> _receipts = [];
  ReceiptModel? _selectedReceipt;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOffline = false;
  bool _isFromCache = false;

  // Getters
  List<ReceiptModel> get receipts => _receipts;
  ReceiptModel? get selectedReceipt => _selectedReceipt;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;
  bool get isFromCache => _isFromCache;

  // Current user ID for caching
  int? _currentUserId;

  void setCurrentUserId(int userId) {
    _currentUserId = userId;
  }

  // Get active receipts
  List<ReceiptModel> get activeReceipts {
    return _receipts.where((r) => r.isActive).toList();
  }

  // Get completed receipts
  List<ReceiptModel> get completedReceipts {
    return _receipts.where((r) => r.isCompleted).toList();
  }

  // Initialize background refresh callbacks
  void _setupBackgroundRefresh() {
    _receiptRepository.onMyReceiptsRefreshed = (receipts) {
      _receipts = receipts;
      _isFromCache = false;
      notifyListeners();
    };

    _receiptRepository.onActiveReceiptsRefreshed = (receipts) {
      _receipts = receipts;
      _isFromCache = false;
      notifyListeners();
    };
  }

  // Fetch all receipts
  Future<void> fetchReceipts({
    String? status,
    int? laundromatId,
    String? search,
    bool forceRefresh = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _receiptRepository.getReceipts(
        status: status,
        laundromatId: laundromatId,
        search: search,
        forceRefresh: forceRefresh,
      );

      if (result['success']) {
        _receipts = result['receipts'];
        _isFromCache = result['fromCache'] ?? false;
        _isOffline = result['offline'] ?? false;
      } else {
        _errorMessage = result['message'];
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch my receipts (for customers) - with caching
  Future<void> fetchMyReceipts({
    String? search,
    bool forceRefresh = false,
  }) async {
    _setupBackgroundRefresh();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _receiptRepository.getMyReceipts(
        search: search,
        forceRefresh: forceRefresh,
        currentUserId: _currentUserId,
      );

      if (result['success']) {
        _receipts = result['receipts'];
        _isFromCache = result['fromCache'] ?? false;
        _isOffline = result['offline'] ?? false;
      } else {
        _errorMessage = result['message'];
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch active receipts - with caching
  Future<void> fetchActiveReceipts({bool forceRefresh = false}) async {
    _setupBackgroundRefresh();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _receiptRepository.getActiveReceipts(
        forceRefresh: forceRefresh,
      );

      if (result['success']) {
        _receipts = result['receipts'];
        _isFromCache = result['fromCache'] ?? false;
        _isOffline = result['offline'] ?? false;
      } else {
        _errorMessage = result['message'];
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch receipt detail - with caching
  Future<bool> fetchReceiptDetail(int id, {bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _receiptRepository.getReceiptDetail(
        id,
        forceRefresh: forceRefresh,
      );

      if (result['success']) {
        _selectedReceipt = result['receipt'];
        _isFromCache = result['fromCache'] ?? false;
        _isOffline = result['offline'] ?? false;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create receipt
  Future<ReceiptModel?> createReceipt({
    required int customerId,
    required int laundromatId,
    required int staffId,
    required DateTime expectedPickupDate,
    required String itemsDescription,
    required int itemsCount,
    required double price,
    String? specialInstructions,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _receiptRepository.createReceipt(
        customerId: customerId,
        laundromatId: laundromatId,
        staffId: staffId,
        expectedPickupDate: expectedPickupDate,
        itemsDescription: itemsDescription,
        itemsCount: itemsCount,
        price: price,
        specialInstructions: specialInstructions,
      );

      if (result['success']) {
        final receipt = result['receipt'] as ReceiptModel;
        _receipts.insert(0, receipt);
        _isLoading = false;
        notifyListeners();
        return receipt;
      }

      _errorMessage = result['message'];
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Update receipt status
  Future<bool> updateReceiptStatus(int id, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _receiptRepository.updateReceiptStatus(id, status);

      if (result['success']) {
        final updatedReceipt = result['receipt'] as ReceiptModel;

        // Update in list
        final index = _receipts.indexWhere((r) => r.id == id);
        if (index != -1) {
          _receipts[index] = updatedReceipt;
        }

        // Update selected receipt
        if (_selectedReceipt?.id == id) {
          _selectedReceipt = updatedReceipt;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Complete receipt
  Future<bool> completeReceipt(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _receiptRepository.completeReceipt(id);

      if (result['success']) {
        final updatedReceipt = result['receipt'] as ReceiptModel;

        // Update in list
        final index = _receipts.indexWhere((r) => r.id == id);
        if (index != -1) {
          _receipts[index] = updatedReceipt;
        }

        // Update selected receipt
        if (_selectedReceipt?.id == id) {
          _selectedReceipt = updatedReceipt;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear selected receipt
  void clearSelectedReceipt() {
    _selectedReceipt = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all cache (on logout)
  Future<void> clearCache() async {
    await _receiptRepository.clearCache();
    _receipts = [];
    _selectedReceipt = null;
    _isFromCache = false;
    _isOffline = false;
    notifyListeners();
  }
}
