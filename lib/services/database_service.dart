// lib/services/database_service.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:smart_uniway/models/user_model.dart';
import 'package:intl/intl.dart';

// Custom exception class for user creation errors
class UserCreationException implements Exception {
  final String message;
  UserCreationException(this.message);
}

class DatabaseService {
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smart_uniway.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const nullableTextType = 'TEXT';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE users ( 
        id $idType, 
        name $textType,
        surname $textType,
        email $textType UNIQUE,
        phone $textType,
        password $textType,
        userType $textType,
        course $nullableTextType,
        registrationNumber $nullableTextType UNIQUE,
        institution $nullableTextType,
        route $nullableTextType,
        period $nullableTextType
      )
    ''');

    // --- NEW TABLE ADDED ---
    await db.execute('''
      CREATE TABLE attendance (
        id $idType,
        userId $integerType,
        date $textType,
        status $textType,
        UNIQUE(userId, date) ON CONFLICT REPLACE
      )
    ''');

    await db.insert('users', {
      'name': 'Admin',
      'surname': 'User',
      'email': 'admin@smartuniway.com',
      'phone': '0000000000',
      'password': 'admin', // Senha simples para teste
      'userType': 'admin',
    });
  }

  Future<int> createUser(User user) async {
    final db = await instance.database;
    try {
      return await db.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw UserCreationException('Este email ou matrícula já está em uso.');
      } else {
        rethrow;
      }
    }
  }

  Future<User?> loginUser(String email, String password) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllStudents() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'userType = ?',
      whereArgs: ['student'],
      orderBy: 'name ASC',
    );

    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<List<User>> getStudentsByInstitution(String institution) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'userType = ? AND institution = ?',
      whereArgs: ['student', institution],
      orderBy: 'name ASC',
    );

    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<Map<String, int>> getStudentCountByInstitution() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT institution, COUNT(*) as count 
      FROM users 
      WHERE userType = 'student' AND institution IS NOT NULL
      GROUP BY institution
    ''');
    return {
      for (var item in result)
        item['institution'] as String: item['count'] as int,
    };
  }

  // --- NEW FUNCTIONS ADDED ---

  // Saves or updates an attendance record
  Future<void> saveAttendanceRecord(
    int userId,
    String date,
    String status,
  ) async {
    final db = await instance.database;
    await db.insert('attendance', {
      'userId': userId,
      'date': date,
      'status': status,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Fetches all attendance records for a specific date
  Future<Map<int, String>> getAttendanceForDate(String date) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance',
      where: 'date = ?',
      whereArgs: [date],
    );

    return {
      for (var item in maps) item['userId'] as int: item['status'] as String,
    };
  }

  // --- NEW FUNCTION ADDED ---
  // Fetches attendance data to generate a report
  Future<Map<String, Map<String, int>>> getAttendanceReport(
    String institution,
    int days,
  ) async {
    final db = await instance.database;
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));

    // Formats dates to the database standard (YYYY-MM-DD)
    final formatter = DateFormat('yyyy-MM-dd');
    final startDateString = formatter.format(startDate);
    final endDateString = formatter.format(endDate);

    // Complex SQL query to group and count
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT a.date, a.status, COUNT(a.id) as count
      FROM attendance a
      JOIN users u ON u.id = a.userId
      WHERE u.institution = ? AND a.date BETWEEN ? AND ?
      GROUP BY a.date, a.status
    ''',
      [institution, startDateString, endDateString],
    );

    // Structure to organize the data: {'2025-10-14': {'present': 5, 'absent': 1}}
    final Map<String, Map<String, int>> reportData = {};

    for (var row in result) {
      final date = row['date'] as String;
      final status = row['status'] as String;
      final count = row['count'] as int;

      if (!reportData.containsKey(date)) {
        reportData[date] = {'present': 0, 'absent': 0};
      }
      if (status == 'present' || status == 'absent') {
        reportData[date]![status] = count;
      }
    }
    return reportData;
  }

  Future<int> updateUser(User user) async {
    final db = await instance.database;

    // db.update atualiza o registro na tabela 'users'
    // A cláusula 'where' garante que estamos atualizando o usuário correto pelo seu 'id'
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
}
