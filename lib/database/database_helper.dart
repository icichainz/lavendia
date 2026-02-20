import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  final _logger = Logger();

  static const String _databaseName = 'lavendia.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String tableReceipts = 'receipts';
  static const String tableUsers = 'users';
  static const String tableLaundromats = 'laundromats';
  static const String tableVideos = 'videos';
  static const String tableSyncMeta = 'sync_meta';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    _logger.i('Initializing database at: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    _logger.i('Creating database tables...');

    // Create receipts table
    await db.execute('''
      CREATE TABLE $tableReceipts (
        id INTEGER PRIMARY KEY,
        receipt_number TEXT NOT NULL,
        laundromat_id INTEGER,
        laundromat_name TEXT,
        customer_id INTEGER,
        customer_name TEXT,
        staff_id INTEGER,
        status TEXT NOT NULL,
        drop_off_date TEXT NOT NULL,
        expected_pickup_date TEXT NOT NULL,
        actual_pickup_date TEXT,
        items_description TEXT,
        items_count INTEGER,
        special_instructions TEXT,
        price REAL,
        qr_code_url TEXT,
        is_active INTEGER DEFAULT 1,
        days_since_dropoff INTEGER,
        created_at TEXT,
        updated_at TEXT,
        cached_at TEXT NOT NULL
      )
    ''');

    // Create users table
    await db.execute('''
      CREATE TABLE $tableUsers (
        id INTEGER PRIMARY KEY,
        username TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        role TEXT NOT NULL,
        first_name TEXT,
        last_name TEXT,
        profile_picture_url TEXT,
        laundromat_id INTEGER,
        laundromat_name TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT,
        cached_at TEXT NOT NULL
      )
    ''');

    // Create laundromats table
    await db.execute('''
      CREATE TABLE $tableLaundromats (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        is_active INTEGER DEFAULT 1,
        staff_count INTEGER,
        active_receipts_count INTEGER,
        created_at TEXT,
        updated_at TEXT,
        cached_at TEXT NOT NULL
      )
    ''');

    // Create videos table
    await db.execute('''
      CREATE TABLE $tableVideos (
        id INTEGER PRIMARY KEY,
        receipt_id INTEGER NOT NULL,
        video_type TEXT NOT NULL,
        video_file_url TEXT NOT NULL,
        video_url TEXT,
        thumbnail_url TEXT,
        duration INTEGER,
        file_size INTEGER,
        file_size_mb REAL,
        uploaded_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        cached_at TEXT NOT NULL,
        FOREIGN KEY (receipt_id) REFERENCES $tableReceipts(id) ON DELETE CASCADE
      )
    ''');

    // Create sync_meta table for tracking last sync times
    await db.execute('''
      CREATE TABLE $tableSyncMeta (
        key TEXT PRIMARY KEY,
        last_sync TEXT NOT NULL,
        etag TEXT
      )
    ''');

    // Create indexes for common queries
    await db.execute('CREATE INDEX idx_receipts_customer_id ON $tableReceipts(customer_id)');
    await db.execute('CREATE INDEX idx_receipts_laundromat_id ON $tableReceipts(laundromat_id)');
    await db.execute('CREATE INDEX idx_receipts_status ON $tableReceipts(status)');
    await db.execute('CREATE INDEX idx_receipts_is_active ON $tableReceipts(is_active)');
    await db.execute('CREATE INDEX idx_videos_receipt_id ON $tableVideos(receipt_id)');
    await db.execute('CREATE INDEX idx_users_role ON $tableUsers(role)');

    _logger.i('Database tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.i('Upgrading database from version $oldVersion to $newVersion');
    // Add migration logic here for future versions
  }

  /// Clear all cached data (useful on logout)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(tableReceipts);
    await db.delete(tableUsers);
    await db.delete(tableLaundromats);
    await db.delete(tableVideos);
    await db.delete(tableSyncMeta);
    _logger.i('All cached data cleared');
  }

  /// Close the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _logger.i('Database connection closed');
    }
  }
}
