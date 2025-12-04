import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/storage_keys.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  // Initialize SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Ensure SharedPreferences is initialized
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ===== Secure Storage (for tokens) =====

  // Save access token
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: StorageKeys.accessToken, value: token);
  }

  // Get access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: StorageKeys.accessToken);
  }

  // Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: StorageKeys.refreshToken, value: token);
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: StorageKeys.refreshToken);
  }

  // Delete tokens
  Future<void> deleteTokens() async {
    await _secureStorage.delete(key: StorageKeys.accessToken);
    await _secureStorage.delete(key: StorageKeys.refreshToken);
  }

  // ===== SharedPreferences (for user data) =====

  // Save user ID
  Future<void> saveUserId(int id) async {
    await prefs.setInt(StorageKeys.userId, id);
  }

  // Get user ID
  int? getUserId() {
    return prefs.getInt(StorageKeys.userId);
  }

  // Save username
  Future<void> saveUsername(String username) async {
    await prefs.setString(StorageKeys.username, username);
  }

  // Get username
  String? getUsername() {
    return prefs.getString(StorageKeys.username);
  }

  // Save user role
  Future<void> saveUserRole(String role) async {
    await prefs.setString(StorageKeys.userRole, role);
  }

  // Get user role
  String? getUserRole() {
    return prefs.getString(StorageKeys.userRole);
  }

  // Save user email
  Future<void> saveUserEmail(String email) async {
    await prefs.setString(StorageKeys.userEmail, email);
  }

  // Get user email
  String? getUserEmail() {
    return prefs.getString(StorageKeys.userEmail);
  }

  // Save user phone
  Future<void> saveUserPhone(String phone) async {
    await prefs.setString(StorageKeys.userPhone, phone);
  }

  // Get user phone
  String? getUserPhone() {
    return prefs.getString(StorageKeys.userPhone);
  }

  // Save laundromat ID (for staff)
  Future<void> saveLaundromatId(int id) async {
    await prefs.setInt(StorageKeys.laundromatId, id);
  }

  // Get laundromat ID
  int? getLaundromatId() {
    return prefs.getInt(StorageKeys.laundromatId);
  }

  // Save login status
  Future<void> saveLoginStatus(bool isLoggedIn) async {
    await prefs.setBool(StorageKeys.isLoggedIn, isLoggedIn);
  }

  // Get login status
  bool getLoginStatus() {
    return prefs.getBool(StorageKeys.isLoggedIn) ?? false;
  }

  // ===== Clear all data =====

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await prefs.clear();
  }

  // Clear only user data (keep app settings)
  Future<void> clearUserData() async {
    await deleteTokens();
    await prefs.remove(StorageKeys.userId);
    await prefs.remove(StorageKeys.username);
    await prefs.remove(StorageKeys.userRole);
    await prefs.remove(StorageKeys.userEmail);
    await prefs.remove(StorageKeys.userPhone);
    await prefs.remove(StorageKeys.laundromatId);
    await prefs.setBool(StorageKeys.isLoggedIn, false);
  }
}
