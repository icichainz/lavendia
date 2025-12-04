import 'package:flutter/material.dart';
import '../models/receipt_model.dart';
import '../services/receipt_service.dart';

class ReceiptProvider with ChangeNotifier {
  final _receiptService = ReceiptService();

  List<ReceiptModel> _receipts = [];
  ReceiptModel? _selectedReceipt;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ReceiptModel> get receipts => _receipts;
  ReceiptModel? get selectedReceipt => _selectedReceipt;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get active receipts
  List<ReceiptModel> get activeReceipts {
    return _receipts.where((r) => r.isActive).toList();
  }

  // Get completed receipts
  List<ReceiptModel> get completedReceipts {
    return _receipts.where((r) => r.isCompleted).toList();
  }

  // Fetch all receipts
  Future<void> fetchReceipts({
    String? status,
    int? laundromatId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _receiptService.getReceipts(
        status: status,
        laundromatId: laundromatId,
      );

      if (result['success']) {
        _receipts = result['receipts'];
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

  // Fetch my receipts (for customers)
  Future<void> fetchMyReceipts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _receiptService.getMyReceipts();

      if (result['success']) {
        _receipts = result['receipts'];
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

  // Fetch active receipts
  Future<void> fetchActiveReceipts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _receiptService.getActiveReceipts();

      if (result['success']) {
        _receipts = result['receipts'];
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

  // Fetch receipt detail
  Future<bool> fetchReceiptDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _receiptService.getReceiptDetail(id);

      if (result['success']) {
        _selectedReceipt = result['receipt'];
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
      final result = await _receiptService.updateReceiptStatus(id, status);

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
      final result = await _receiptService.completeReceipt(id);

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
}
