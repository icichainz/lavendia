import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class UserService {
  final _api = ApiService();

  /// Search customers by phone, name, username, or email
  Future<List<UserModel>> searchCustomers(String query) async {
    try {
      final response = await _api.get(
        ApiConstants.customers,
        queryParameters: {'search': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => UserModel.fromJson(json)).toList();
      }
      return [];
    } on DioException {
      rethrow;
    }
  }

  /// Get all customers
  Future<List<UserModel>> getAllCustomers() async {
    try {
      final response = await _api.get(ApiConstants.customers);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => UserModel.fromJson(json)).toList();
      }
      return [];
    } on DioException {
      rethrow;
    }
  }

  /// Get customer by ID
  Future<UserModel?> getCustomerById(int id) async {
    try {
      final response = await _api.get('${ApiConstants.users}$id/');

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      }
      return null;
    } on DioException {
      rethrow;
    }
  }
}
