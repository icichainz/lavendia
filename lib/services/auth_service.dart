import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final _api = ApiService();
  final _storage = StorageService();

  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _api.post(
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
        },
        options: Options(headers: ApiConstants.headers),
      );

      if (response.statusCode == 200) {
        final accessToken = response.data['access'] as String;
        final refreshToken = response.data['refresh'] as String;

        // Save tokens
        await _storage.saveAccessToken(accessToken);
        await _storage.saveRefreshToken(refreshToken);
        await _storage.saveLoginStatus(true);

        return {
          'success': true,
          'access': accessToken,
          'refresh': refreshToken,
        };
      }

      return {
        'success': false,
        'message': 'Login failed',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _api.getErrorMessage(e),
      };
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _api.get(ApiConstants.userMe);

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data);

        // Save user data
        await _storage.saveUserId(user.id);
        await _storage.saveUsername(user.username);
        await _storage.saveUserRole(user.role);
        await _storage.saveUserEmail(user.email);
        await _storage.saveUserPhone(user.phone);

        if (user.laundromatId != null) {
          await _storage.saveLaundromatId(user.laundromatId!);
        }

        return {
          'success': true,
          'user': user,
        };
      }

      return {
        'success': false,
        'message': 'Failed to get user profile',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _api.getErrorMessage(e),
      };
    }
  }

  // Register new user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirm,
    String role = 'customer',
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.register,
        data: {
          'username': username,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirm': passwordConfirm,
          'role': role,
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
        },
        options: Options(headers: ApiConstants.headers),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Registration successful',
        };
      }

      return {
        'success': false,
        'message': 'Registration failed',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _api.getErrorMessage(e),
        'errors': e.response?.data,
      };
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.changePassword,
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
          'new_password_confirm': newPasswordConfirm,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Password changed successfully',
        };
      }

      return {
        'success': false,
        'message': 'Failed to change password',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _api.getErrorMessage(e),
        'errors': e.response?.data,
      };
    }
  }

  // Update profile
  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    try {
      final response = await _api.put(
        ApiConstants.updateProfile,
        data: {
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
        },
      );

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data);

        // Update stored user data
        await _storage.saveUserEmail(user.email);
        await _storage.saveUserPhone(user.phone);

        return {
          'success': true,
          'user': user,
          'message': 'Profile updated successfully',
        };
      }

      return {
        'success': false,
        'message': 'Failed to update profile',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _api.getErrorMessage(e),
        'errors': e.response?.data,
      };
    }
  }

  // Logout
  Future<void> logout() async {
    await _storage.clearUserData();
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _storage.getLoginStatus();
  }

  // Get stored user role
  String? getUserRole() {
    return _storage.getUserRole();
  }
}
