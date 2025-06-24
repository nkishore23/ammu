import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

// User Model
class User {
  final int? id;
  final String mobileNumber;
  final String email;
  final String passwordHash;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  User({
    this.id,
    required this.mobileNumber,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
    this.lastLoginAt,
  });

  // Convert User to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mobile_number': mobileNumber,
      'email': email,
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  // Create User from Map (database result)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toInt(),
      mobileNumber: map['mobile_number'] ?? '',
      email: map['email'] ?? '',
      passwordHash: map['password_hash'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      lastLoginAt: map['last_login_at'] != null 
          ? DateTime.parse(map['last_login_at']) 
          : null,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, mobileNumber: $mobileNumber, email: $email, createdAt: $createdAt}';
  }
}

// Database Helper Class
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  // Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ammu_users.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mobile_number TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_login_at TEXT
      )
    ''');

    // Create index for faster lookups
    await db.execute('CREATE INDEX idx_email ON users(email)');
    await db.execute('CREATE INDEX idx_mobile ON users(mobile_number)');
  }

  // Hash password using SHA-256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Register new user
  Future<Map<String, dynamic>> registerUser({
    required String mobileNumber,
    required String email,
    required String password,
  }) async {
    try {
      final db = await database;
      
      // Check if user already exists
      final existingUser = await db.query(
        'users',
        where: 'email = ? OR mobile_number = ?',
        whereArgs: [email, mobileNumber],
      );

      if (existingUser.isNotEmpty) {
        return {
          'success': false,
          'message': 'User already exists with this email or mobile number',
        };
      }

      // Create new user
      final user = User(
        mobileNumber: mobileNumber,
        email: email,
        passwordHash: _hashPassword(password),
        createdAt: DateTime.now(),
      );

      final id = await db.insert('users', user.toMap());
      
      return {
        'success': true,
        'message': 'User registered successfully',
        'userId': id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}',
      };
    }
  }

  // Login user
  Future<Map<String, dynamic>> loginUser({
    required String emailOrMobile,
    required String password,
  }) async {
    try {
      final db = await database;
      
      // Check if input is email or mobile
      bool isEmail = emailOrMobile.contains('@');
      String whereClause = isEmail ? 'email = ?' : 'mobile_number = ?';
      
      final result = await db.query(
        'users',
        where: whereClause,
        whereArgs: [emailOrMobile],
      );

      if (result.isEmpty) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      final user = User.fromMap(result.first);
      
      // Verify password
      if (user.passwordHash != _hashPassword(password)) {
        return {
          'success': false,
          'message': 'Invalid password',
        };
      }

      // Update last login time
      await db.update(
        'users',
        {'last_login_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [user.id],
      );

      return {
        'success': true,
        'message': 'Login successful',
        'user': user,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed: ${e.toString()}',
      };
    }
  }

  // Get user by ID
  Future<User?> getUserById(int id) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  // Get user by email
  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  // Get all users (for admin/debugging purposes)
  Future<List<User>> getAllUsers() async {
    final db = await database;
    final result = await db.query('users', orderBy: 'created_at DESC');
    
    return result.map((map) => User.fromMap(map)).toList();
  }

  // Update user password
  Future<bool> updatePassword({
    required String emailOrMobile,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final db = await database;
      
      // Verify current password first
      final loginResult = await loginUser(
        emailOrMobile: emailOrMobile,
        password: oldPassword,
      );

      if (!loginResult['success']) {
        return false;
      }

      final user = loginResult['user'] as User;
      
      // Update password
      await db.update(
        'users',
        {'password_hash': _hashPassword(newPassword)},
        where: 'id = ?',
        whereArgs: [user.id],
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete user account
  Future<bool> deleteUser(int userId) async {
    try {
      final db = await database;
      final result = await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      return result > 0;
    } catch (e) {
      return false;
    }
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  // Check if mobile number exists
  Future<bool> mobileExists(String mobile) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'mobile_number = ?',
      whereArgs: [mobile],
    );
    return result.isNotEmpty;
  }

  // Get user count
  Future<int> getUserCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    db.close();
  }

  // Clear all data (for testing/development)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('users');
  }
}