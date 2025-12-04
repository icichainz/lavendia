import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/receipt_model.dart';
import 'api_service.dart';

class ReceiptService {
  final _api = ApiService();

  // Get all receipts (with optional filters)
  Future<Map<String, dynamic>> getReceipts({
    String? status,
    int? laundromatId,
    int? customerId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (laundromatId != null) queryParams['laundromat'] = laundromatId;
      if (customerId != null) queryParams['customer'] = customerId;

      final response = await _api.get(
        ApiConstants.receipts,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List receiptsData = response.data['results'] ?? response.data;
        final receipts = receiptsData
            .map((json) => ReceiptModel.fromJson(json))
            .toList();

        return {
          'success': true,
          'receipts': receipts,
        };
      }

      return {
        'success': false,
        'message': 'Failed to fetch receipts',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _api.getErrorMessage(e),
      };
    }
  }

  // Get my receipts (current user)
  Future<Map<String, dynamic>> getMyReceipts() async {
    try {
      final response = await _api.get(ApiConstants.myReceipts);

      if (response.statusCode == 200) {
        final List receiptsData = response.data is List
            ? response.data
            : response.data['results'] ?? [];
        final receipts = receiptsData
            .map((json) => ReceiptModel.fromJson(json))
            .toList();

        return {
          'success': true,
          'receipts': receipts,
        };
      }

      return {
        'success': false,
        'message': 'Failed to fetch your receipts',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _api.getErrorMessage(e),
      };
    }
  }

  // Get active receipts
  Future<Map<String, dynamic>> getActiveReceipts() async {
    try {
      final response = await _api.get(ApiConstants.activeReceipts);

      if (response.statusCode == 200) {
        final List receiptsData = response.data['results'] ?? response.data;
        final receipts = receiptsData
            .map((json) => ReceiptModel.fromJson(json))
            .toList();

        return {
          'success': true,
          'receipts': receipts,
        };
      }

      return {
        'success': false,
        'message': 'Failed to fetch active receipts',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _api.getErrorMessage(e),
      };
    }
  }

  // Get receipt details
  Future<Map<String, dynamic>> getReceiptDetail(int id) async {
    try {
      final response = await _api.get(ApiConstants.receiptDetail(id));

      if (response.statusCode == 200) {
        final receipt = ReceiptModel.fromJson(response.data);

        return {
          'success': true,
          'receipt': receipt,
        };
      }

      return {
        'success': false,
        'message': 'Failed to fetch receipt details',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _api.getErrorMessage(e),
      };
    }
  }

  // Create receipt
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
    try {
      final response = await _api.post(
        ApiConstants.receipts,
        data: {
          'customer_id': customerId,
          'laundromat_id': laundromatId,
          'staff_id': staffId,
          'expected_pickup_date': expectedPickupDate.toIso8601String(),
          'items_description': itemsDescription,
          'items_count': itemsCount,
          'price': price,
          if (specialInstructions != null)
            'special_instructions': specialInstructions,
        },
      );

      if (response.statusCode == 201) {
        final receipt = ReceiptModel.fromJson(response.data);

        return {
          'success': true,
          'receipt': receipt,
          'message': 'Receipt created successfully',
        };
      }

      return {
        'success': false,
        'message': 'Failed to create receipt',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _api.getErrorMessage(e),
        'errors': e.response?.data,
      };
    }
  }

  // Update receipt status
  Future<Map<String, dynamic>> updateReceiptStatus(
    int id,
    String status,
  ) async {
    try {
      final response = await _api.patch(
        ApiConstants.updateReceiptStatus(id),
        data: {'status': status},
      );

      if (response.statusCode == 200) {
        final receipt = ReceiptModel.fromJson(response.data);

        return {
          'success': true,
          'receipt': receipt,
          'message': 'Receipt status updated',
        };
      }

      return {
        'success': false,
        'message': 'Failed to update receipt status',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _api.getErrorMessage(e),
      };
    }
  }

  // Complete receipt (pickup)
  Future<Map<String, dynamic>> completeReceipt(int id) async {
    try {
      final response = await _api.post(
        ApiConstants.completeReceipt(id),
      );

      if (response.statusCode == 200) {
        final receipt = ReceiptModel.fromJson(response.data);

        return {
          'success': true,
          'receipt': receipt,
          'message': 'Receipt marked as completed',
        };
      }

      return {
        'success': false,
        'message': 'Failed to complete receipt',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _api.getErrorMessage(e),
      };
    }
  }

  // Get receipt QR code
  Future<Map<String, dynamic>> getReceiptQrCode(int id) async {
    try {
      final response = await _api.get(ApiConstants.receiptQrCode(id));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'qr_code_url': response.data['qr_code_url'],
          'receipt_number': response.data['receipt_number'],
        };
      }

      return {
        'success': false,
        'message': 'Failed to get QR code',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _api.getErrorMessage(e),
      };
    }
  }
}
