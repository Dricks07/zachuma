// lib/services/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'zachuma.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE topics(
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        content TEXT,
        category TEXT,
        level TEXT,
        imageUrl TEXT,
        status TEXT,
        published INTEGER,
        duration TEXT,
        rating REAL,
        createdAt INTEGER,
        lastUpdated INTEGER,
        quizQuestions TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_progress(
        topicId TEXT PRIMARY KEY,
        completed INTEGER,
        progress REAL,
        lastAccessed INTEGER,
        quizScore REAL,
        FOREIGN KEY (topicId) REFERENCES topics (id)
      )
    ''');
  }

  // Add topic to local DB
  Future<void> insertOrUpdateTopic(Map<String, dynamic> topic) async {
    try {
      final db = await database;
      await db.insert(
        'topics',
        topic,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Topic ${topic['id']} saved to local database');
    } catch (e) {
      print('Error saving topic to local database: $e');
      rethrow;
    }
  }

  // Retrieve topics from local DB
  Future<List<Map<String, dynamic>>> getTopics() async {
    try {
      final db = await database;
      final results = await db.query('topics', where: 'published = 1');
      print('Retrieved ${results.length} topics from local database');
      return results;
    } catch (e) {
      print('Error retrieving topics from local database: $e');
      return [];
    }
  }


  Future<Map<String, dynamic>?> getTopic(String id) async {
    final db = await database;
    final results = await db.query('topics', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  // User progress methods
  Future<void> updateUserProgress(Map<String, dynamic> progress) async {
    final db = await database;
    await db.insert(
      'user_progress',
      progress,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserProgress(String topicId) async {
    final db = await database;
    final results = await db.query('user_progress',
        where: 'topicId = ?', whereArgs: [topicId]);
    return results.isNotEmpty ? results.first : null;
  }





}