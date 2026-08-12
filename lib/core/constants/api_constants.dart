class ApiConstants {
  /// Base URL for the API.
  ///
  /// Override at build/run time without editing this file:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api
  ///   flutter build apk --dart-define=API_BASE_URL=https://api.lavendia.app/api
  ///
  /// The default targets the Android emulator loopback alias, which is the
  /// most common local setup. Other local targets:
  ///   iOS simulator:   http://localhost:8000/api
  ///   Physical device: `http://<your-computer-ip>:8000/api`
  ///
  /// Release builds must pass an https:// URL - see [isCleartext].
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  /// True when [baseUrl] uses unencrypted HTTP.
  ///
  /// Android only permits cleartext to the hosts allowlisted in
  /// android/app/src/main/res/xml/network_security_config.xml (localhost,
  /// 10.0.2.2 and private LAN ranges). A cleartext URL outside those hosts
  /// will fail at the platform level before the request is sent.
  static bool get isCleartext => baseUrl.startsWith('http://');

  // Auth Endpoints
  static const String login = '/auth/login/';
  static const String refresh = '/auth/refresh/';
  static const String register = '/users/';

  // User Endpoints
  static const String users = '/users/';
  static const String userMe = '/users/me/';
  static const String updateProfile = '/users/update_profile/';
  static const String changePassword = '/users/change_password/';
  static const String uploadProfilePicture = '/users/upload_profile_picture/';
  static const String customers = '/users/customers/';
  static const String staff = '/users/staff/';

  // Password Reset Endpoints
  static const String requestPasswordReset = '/users/request_password_reset/';
  static const String verifyResetToken = '/users/verify_reset_token/';
  static const String resetPassword = '/users/reset_password/';

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
