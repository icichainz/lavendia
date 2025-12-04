class AppConstants {
  // App Info
  static const String appName = 'Lavendia';
  static const String appVersion = '1.0.0';

  // Receipt Status
  static const String statusPending = 'pending';
  static const String statusWashing = 'washing';
  static const String statusDrying = 'drying';
  static const String statusReady = 'ready';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // User Roles
  static const String roleCustomer = 'customer';
  static const String roleStaff = 'staff';
  static const String roleAdmin = 'admin';

  // Video Types
  static const String videoTypeIntake = 'intake';
  static const String videoTypeCompletion = 'completion';

  // Video Settings
  static const int maxVideoSizeMB = 50;
  static const int maxVideoDurationSeconds = 60;

  // Pagination
  static const int defaultPageSize = 20;

  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';
  static const String timeFormat = 'HH:mm';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
}
