class ApiConstants {
  // Base URL - change for production
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator
  // For iOS simulator: 'http://localhost:8000/api'
  // For physical device: 'http://YOUR_COMPUTER_IP:8000/api'

  // Auth Endpoints
  static const String login = '/auth/login/';
  static const String refresh = '/auth/refresh/';
  static const String register = '/users/';

  // User Endpoints
  static const String users = '/users/';
  static const String userMe = '/users/me/';
  static const String updateProfile = '/users/update_profile/';
  static const String changePassword = '/users/change_password/';
  static const String customers = '/users/customers/';
  static const String staff = '/users/staff/';

  // Laundromat Endpoints
  static const String laundromats = '/laundromats/';
  static String laundromatReceipts(int id) => '/laundromats/$id/receipts/';
  static String laundromatStaff(int id) => '/laundromats/$id/staff/';

  // Receipt Endpoints
  static const String receipts = '/receipts/';
  static const String activeReceipts = '/receipts/active/';
  static const String myReceipts = '/receipts/my_receipts/';
  static String receiptDetail(int id) => '/receipts/$id/';
  static String updateReceiptStatus(int id) => '/receipts/$id/update_status/';
  static String completeReceipt(int id) => '/receipts/$id/complete/';
  static String receiptQrCode(int id) => '/receipts/$id/qr_code/';

  // Video Endpoints
  static const String videos = '/videos/';
  static const String videosByReceipt = '/videos/by_receipt/';
  static String videoDetail(int id) => '/videos/$id/';

  // Headers
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Map<String, String> authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Map<String, String> multipartHeaders(String token) => {
        'Authorization': 'Bearer $token',
      };
}
