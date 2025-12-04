import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final _authService = AuthService();
  final _storage = StorageService();

  UserModel? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // User role checks
  bool get isCustomer => _user?.isCustomer ?? false;
  bool get isStaff => _user?.isStaff ?? false;
  bool get isAdmin => _user?.isAdmin ?? false;

  // Initialize - check if user is logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = _authService.isLoggedIn();

      if (isLoggedIn) {
        // Fetch user profile
        final result = await _authService.getCurrentUser();

        if (result['success']) {
          _user = result['user'];
          _isAuthenticated = true;
        } else {
          _isAuthenticated = false;
          await _authService.logout();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(username, password);

      if (result['success']) {
        // Fetch user profile after successful login
        final userResult = await _authService.getCurrentUser();

        if (userResult['success']) {
          _user = userResult['user'];
          _isAuthenticated = true;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _errorMessage = result['message'] ?? 'Login failed';
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String username,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirm,
    String? firstName,
    String? lastName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        username: username,
        email: email,
        phone: phone,
        password: password,
        passwordConfirm: passwordConfirm,
        firstName: firstName,
        lastName: lastName,
      );

      if (result['success']) {
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = result['message'] ?? 'Registration failed';
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

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Update profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
      );

      if (result['success']) {
        _user = result['user'];
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = result['message'] ?? 'Failed to update profile';
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

  // Change password
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        newPasswordConfirm: newPasswordConfirm,
      );

      if (result['success']) {
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = result['message'] ?? 'Failed to change password';
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

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
