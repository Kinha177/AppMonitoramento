import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/service_model.dart';
import '../models/service_log_model.dart'; // Importe o novo modelo

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('monitor.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // VERSÃO ATUALIZADA PARA 2
      onCreate: _createDB,
      onUpgrade: _onUpgrade, // Adicionado callback de atualização
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        lastStatus TEXT,
        lastLatencyMs INTEGER,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Criação da tabela de logs (para novas instalações)
    await _createLogsTable(db);
  }

  // Função separada para criar a tabela de logs
  Future<void> _createLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE service_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serviceId INTEGER NOT NULL,
        status TEXT NOT NULL,
        latencyMs INTEGER NOT NULL,
        checkedAt TEXT NOT NULL,
        FOREIGN KEY (serviceId) REFERENCES services (id) ON DELETE CASCADE
      )
    ''');
  }

  // Lógica para atualizar quem já tem o app instalado
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createLogsTable(db);
    }
  }

  // --- Métodos de User e Service (Mantenha os existentes igual ao original) ---
  Future<int> createUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<int> createService(ServiceModel service) async {
    final db = await database;
    return await db.insert('services', service.toMap());
  }

  Future<List<ServiceModel>> getServicesByUserId(int userId) async {
    final db = await database;
    final maps = await db.query('services', where: 'userId = ?', whereArgs: [userId], orderBy: 'createdAt DESC');
    return maps.map((map) => ServiceModel.fromMap(map)).toList();
  }

  Future<ServiceModel?> getServiceById(int id) async {
    final db = await database;
    final maps = await db.query('services', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ServiceModel.fromMap(maps.first);
  }

  Future<int> updateService(ServiceModel service) async {
    final db = await database;
    return await db.update('services', service.toMap(), where: 'id = ?', whereArgs: [service.id]);
  }

  Future<int> deleteService(int id) async {
    final db = await database;
    return await db.delete('services', where: 'id = ?', whereArgs: [id]);
  }

  // --- NOVOS MÉTODOS DE LOG ---

  Future<int> insertLog(ServiceLogModel log) async {
    final db = await database;
    return await db.insert('service_logs', log.toMap());
  }

  Future<List<ServiceLogModel>> getLogsByServiceId(int serviceId) async {
    final db = await database;
    // Pega os últimos 50 logs para não pesar a tela
    final maps = await db.query(
      'service_logs',
      where: 'serviceId = ?',
      whereArgs: [serviceId],
      orderBy: 'checkedAt DESC',
      limit: 50, 
    );
    return maps.map((map) => ServiceLogModel.fromMap(map)).toList();
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}