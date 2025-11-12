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
      'password': 'admin',
      'userType': 'admin',
    });

    await db.insert('users', {
      'name': 'Admin2',
      'surname': 'User',
      'email': 'admin@smart.com',
      'phone': '0000000000',
      'password': 'admin',
      'userType': 'admin',
    });

    // 3 Alunos - FATEC
    await db.insert('users', {
      'name': 'Ana',
      'surname': 'Silva',
      'email': 'ana.silva@fatec.com',
      'phone': '111111',
      'password': '123',
      'userType': 'student',
      'course': 'ADS',
      'registrationNumber': 'F001',
      'institution': 'FATEC',
      'route': '1',
      'period': '3º Semestre',
    });
    await db.insert('users', {
      'name': 'Bruno',
      'surname': 'Costa',
      'email': 'bruno.costa@fatec.com',
      'phone': '222222',
      'password': '123',
      'userType': 'student',
      'course': 'Logística',
      'registrationNumber': 'F002',
      'institution': 'FATEC',
      'route': '2',
      'period': '1º Semestre',
    });
    await db.insert('users', {
      'name': 'Carla',
      'surname': 'Dias',
      'email': 'carla.dias@fatec.com',
      'phone': '333333',
      'password': '123',
      'userType': 'student',
      'course': 'Gestão',
      'registrationNumber': 'F003',
      'institution': 'FATEC',
      'route': '1',
      'period': '5º Semestre',
    });

    // 3 Alunos - IFSP
    await db.insert('users', {
      'name': 'Daniel',
      'surname': 'Melo',
      'email': 'daniel.melo@ifsp.com',
      'phone': '444444',
      'password': '123',
      'userType': 'student',
      'course': 'Mecatrônica',
      'registrationNumber': 'I001',
      'institution': 'IFSP',
      'route': '2',
      'period': '2º Semestre',
    });
    await db.insert('users', {
      'name': 'Eduarda',
      'surname': 'Rocha',
      'email': 'eduarda.rocha@ifsp.com',
      'phone': '555555',
      'password': '123',
      'userType': 'student',
      'course': 'Engenharia',
      'registrationNumber': 'I002',
      'institution': 'IFSP',
      'route': '3',
      'period': '7º Semestre',
    });
    await db.insert('users', {
      'name': 'Fábio',
      'surname': 'Nunes',
      'email': 'fabio.nunes@ifsp.com',
      'phone': '666666',
      'password': '123',
      'userType': 'student',
      'course': 'Licenciatura',
      'registrationNumber': 'I003',
      'institution': 'IFSP',
      'route': '1',
      'period': '4º Semestre',
    });

    // 3 Alunos - CETEC
    await db.insert('users', {
      'name': 'Gabriela',
      'surname': 'Lima',
      'email': 'gabriela.lima@cetec.com',
      'phone': '777777',
      'password': '123',
      'userType': 'student',
      'course': 'Química',
      'registrationNumber': 'C001',
      'institution': 'CETEC',
      'route': '3',
      'period': '1º Semestre',
    });
    await db.insert('users', {
      'name': 'Hugo',
      'surname': 'Barros',
      'email': 'hugo.barros@cetec.com',
      'phone': '888888',
      'password': '123',
      'userType': 'student',
      'course': 'Farmácia',
      'registrationNumber': 'C002',
      'institution': 'CETEC',
      'route': '2',
      'period': '2º Semestre',
    });
    await db.insert('users', {
      'name': 'Isabela',
      'surname': 'Gomes',
      'email': 'isabela.gomes@cetec.com',
      'phone': '999999',
      'password': '123',
      'userType': 'student',
      'course': 'Nutrição',
      'registrationNumber': 'C003',
      'institution': 'CETEC',
      'route': '1',
      'period': '6º Semestre',
    });

    // 3 Alunos - UNIFIPA
    await db.insert('users', {
      'name': 'Julio',
      'surname': 'Martins',
      'email': 'julio.martins@unifipa.com',
      'phone': '101010',
      'password': '123',
      'userType': 'student',
      'course': 'Medicina',
      'registrationNumber': 'U001',
      'institution': 'UNIFIPA',
      'route': '1',
      'period': '8º Semestre',
    });
    await db.insert('users', {
      'name': 'Larissa',
      'surname': 'Alves',
      'email': 'larissa.alves@unifipa.com',
      'phone': '111222',
      'password': '123',
      'userType': 'student',
      'course': 'Direito',
      'registrationNumber': 'U002',
      'institution': 'UNIFIPA',
      'route': '2',
      'period': '9º Semestre',
    });
    await db.insert('users', {
      'name': 'Marcos',
      'surname': 'Pereira',
      'email': 'marcos.pereira@unifipa.com',
      'phone': '333444',
      'password': '123',
      'userType': 'student',
      'course': 'Ed. Física',
      'registrationNumber': 'U003',
      'institution': 'UNIFIPA',
      'route': '3',
      'period': '1º Semestre',
    });

    // 3 Alunos - ETEC
    await db.insert('users', {
      'name': 'Natália',
      'surname': 'Oliveira',
      'email': 'natalia.oliveira@etec.com',
      'phone': '555666',
      'password': '123',
      'userType': 'student',
      'course': 'Informática',
      'registrationNumber': 'E001',
      'institution': 'ETEC',
      'route': '1',
      'period': '2º Semestre',
    });
    await db.insert('users', {
      'name': 'Otávio',
      'surname': 'Ribeiro',
      'email': 'otavio.ribeiro@etec.com',
      'phone': '777888',
      'password': '123',
      'userType': 'student',
      'course': 'Administração',
      'registrationNumber': 'E002',
      'institution': 'ETEC',
      'route': '2',
      'period': '3º Semestre',
    });
    await db.insert('users', {
      'name': 'Paula',
      'surname': 'Campos',
      'email': 'paula.campos@etec.com',
      'phone': '999000',
      'password': '123',
      'userType': 'student',
      'course': 'Enfermagem',
      'registrationNumber': 'E003',
      'institution': 'ETEC',
      'route': '3',
      'period': '1º Semestre',
    });

    // 3 Alunos - IMES
    await db.insert('users', {
      'name': 'Ricardo',
      'surname': 'Santana',
      'email': 'ricardo.santana@imes.com',
      'phone': '121212',
      'password': '123',
      'userType': 'student',
      'course': 'Psicologia',
      'registrationNumber': 'M001',
      'institution': 'IMES',
      'route': '1',
      'period': '10º Semestre',
    });
    await db.insert('users', {
      'name': 'Sofia',
      'surname': 'Ferreira',
      'email': 'sofia.ferreira@imes.com',
      'phone': '343434',
      'password': '123',
      'userType': 'student',
      'course': 'Pedagogia',
      'registrationNumber': 'M002',
      'institution': 'IMES',
      'route': '2',
      'period': '4º Semestre',
    });
    await db.insert('users', {
      'name': 'Tiago',
      'surname': 'Moura',
      'email': 'tiago.moura@imes.com',
      'phone': '565656',
      'password': '123',
      'userType': 'student',
      'course': 'Ciências Contábeis',
      'registrationNumber': 'M003',
      'institution': 'IMES',
      'route': '3',
      'period': '8º Semestre',
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

  Future<Map<String, Map<String, int>>> getAttendanceReport(
    String institution,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await instance.database;

    // Formata as datas para o padrão do banco de dados (YYYY-MM-DD)
    final formatter = DateFormat('yyyy-MM-dd');
    final startDateString = formatter.format(startDate);
    final endDateString = formatter.format(endDate);

    // Query SQL atualizada para usar o BETWEEN com as datas fornecidas
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT a.date, a.status, COUNT(a.id) as count
      FROM attendance a
      JOIN users u ON u.id = a.userId
      WHERE u.institution = ? AND a.date BETWEEN ? AND ?
      GROUP BY a.date, a.status
      ORDER BY a.date ASC
    ''',
      [institution, startDateString, endDateString],
    );

    // Estrutura para organizar os dados: {'2025-10-14': {'present': 5, 'absent': 1}}
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

  Future<Map<String, Map<String, Map<String, int>>>> getGlobalAttendanceReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await instance.database;
    final formatter = DateFormat('yyyy-MM-dd');
    final startDateString = formatter.format(startDate);
    final endDateString = formatter.format(endDate);

    // Query que agrupa também por instituição
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT u.institution, a.date, a.status, COUNT(a.id) as count
      FROM attendance a
      JOIN users u ON u.id = a.userId
      WHERE a.date BETWEEN ? AND ?
      GROUP BY u.institution, a.date, a.status
      ORDER BY u.institution ASC, a.date ASC
    ''',
      [startDateString, endDateString],
    );

    // Estrutura de dados: { 'Instituição': { 'Data': { 'Status': Contagem } } }
    // Ex: { 'IFSP': { '2025-11-03': { 'present': 5, 'absent': 1 } } }
    final Map<String, Map<String, Map<String, int>>> reportData = {};

    for (var row in result) {
      final institution = row['institution'] as String? ?? 'Outros';
      final date = row['date'] as String;
      final status = row['status'] as String;
      final count = row['count'] as int;

      // Inicializa os mapas aninhados
      if (!reportData.containsKey(institution)) {
        reportData[institution] = {};
      }
      if (!reportData[institution]!.containsKey(date)) {
        reportData[institution]![date] = {'present': 0, 'absent': 0};
      }

      if (status == 'present' || status == 'absent') {
        reportData[institution]![date]![status] = count;
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

  Future<void> deleteUser(int id) async {
    final db = await instance.database;

    // Usamos uma transação para garantir que ambas as operações
    // de exclusão sejam concluídas com êxito.
    await db.transaction((txn) async {
      // 1. Deleta o usuário da tabela 'users'
      await txn.delete('users', where: 'id = ?', whereArgs: [id]);
      // 2. Deleta todos os registros de presença associados a esse usuário
      await txn.delete('attendance', where: 'userId = ?', whereArgs: [id]);
    });
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistoryForStudent(
    int userId,
  ) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result = await db.query(
      'attendance',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC', // Mais recentes primeiro
      limit: 30, // Limita aos últimos 30 registros
    );
    return result;
  }
}
