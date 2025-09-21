// lib/services/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      version: 3, // Increment version for scrollProgress column
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
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
        currentSection INTEGER DEFAULT 0,
        scrollProgress REAL DEFAULT 0.0,
        FOREIGN KEY (topicId) REFERENCES topics (id)
      )
    ''');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add the missing currentSection column
      await db.execute('ALTER TABLE user_progress ADD COLUMN currentSection INTEGER DEFAULT 0');
    }
    if (oldVersion < 3) {
      // Add the missing scrollProgress column
      await db.execute('ALTER TABLE user_progress ADD COLUMN scrollProgress REAL DEFAULT 0.0');
    }
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
    } catch (e) {
      rethrow;
    }
  }

  // Retrieve topics from local DB
  Future<List<Map<String, dynamic>>> getTopics() async {
    try {
      final db = await database;
      final results = await db.query('topics', where: 'published = 1');
      return results;
    } catch (e) {
      return [];
    }
  }

  // Get single topic by ID
  Future<Map<String, dynamic>?> getTopic(String id) async {
    try {
      final db = await database;
      final results = await db.query('topics', where: 'id = ?', whereArgs: [id]);
      if (results.isNotEmpty) {
        return results.first;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // User progress methods
  Future<void> updateUserProgress(Map<String, dynamic> progress) async {
    try {
      final db = await database;
      await db.insert(
        'user_progress',
        progress,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProgress(String topicId) async {
    try {
      final db = await database;
      final results = await db.query('user_progress',
          where: 'topicId = ?', whereArgs: [topicId]);
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Mark topic as completed in both local DB and Firestore
  Future<void> markTopicAsCompleted({
    required String userId,
    required String topicId,
    required double finalScore,
    double? quizScore,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Update local database
      final progressData = {
        'topicId': topicId,
        'completed': 1,
        'progress': 1.0,
        'scrollProgress': 1.0,
        'lastAccessed': now,
        'currentSection': 0,
        'quizScore': quizScore ?? 0.0,
      };

      await updateUserProgress(progressData);

      // Update Firestore
      await _updateFirestoreProgress(
        userId: userId,
        topicId: topicId,
        finalScore: finalScore,
        quizScore: quizScore,
        completedAt: now,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update progress in Firestore
  Future<void> _updateFirestoreProgress({
    required String userId,
    required String topicId,
    required double finalScore,
    double? quizScore,
    required int completedAt,
  }) async {
    try {
      final userProgressRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(topicId);

      final progressData = {
        'topicId': topicId,
        'completed': true,
        'progress': 1.0,
        'finalScore': finalScore,
        'quizScore': quizScore ?? 0.0,
        'completedAt': Timestamp.fromMillisecondsSinceEpoch(completedAt),
        'lastAccessed': Timestamp.fromMillisecondsSinceEpoch(completedAt),
      };

      await userProgressRef.set(progressData, SetOptions(merge: true));

      // Also update user's overall stats
      await _updateUserStats(userId, finalScore, quizScore);
    } catch (e) {
      // Firestore update failed, but local update succeeded
      // This is acceptable for offline functionality
    }
  }

  /// Update user's overall statistics in Firestore
  Future<void> _updateUserStats(String userId, double finalScore, double? quizScore) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        Map<String, dynamic> userData = userDoc.exists ? userDoc.data()! : {};

        // Update completion stats
        int completedTopics = (userData['completedTopics'] as int? ?? 0) + 1;
        List<double> allScores = List<double>.from(userData['scores'] as List? ?? []);
        allScores.add(finalScore);

        if (quizScore != null) {
          List<double> allQuizScores = List<double>.from(userData['quizScores'] as List? ?? []);
          allQuizScores.add(quizScore);
          userData['quizScores'] = allQuizScores;
          userData['averageQuizScore'] = allQuizScores.reduce((a, b) => a + b) / allQuizScores.length;
        }

        // Calculate averages
        double averageScore = allScores.reduce((a, b) => a + b) / allScores.length;

        userData.addAll({
          'completedTopics': completedTopics,
          'scores': allScores,
          'averageScore': averageScore,
          'lastActivity': Timestamp.now(),
        });

        transaction.set(userRef, userData, SetOptions(merge: true));
      });
    } catch (e) {
      // Stats update failed, but main completion succeeded
    }
  }

  /// Get user's completion statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        return {
          'completedTopics': data['completedTopics'] ?? 0,
          'averageScore': data['averageScore'] ?? 0.0,
          'averageQuizScore': data['averageQuizScore'] ?? 0.0,
          'totalScores': (data['scores'] as List?)?.length ?? 0,
        };
      }

      return {
        'completedTopics': 0,
        'averageScore': 0.0,
        'averageQuizScore': 0.0,
        'totalScores': 0,
      };
    } catch (e) {
      return {
        'completedTopics': 0,
        'averageScore': 0.0,
        'averageQuizScore': 0.0,
        'totalScores': 0,
      };
    }
  }

  /// Get user's completed topics from Firestore
  Future<List<Map<String, dynamic>>> getCompletedTopics(String userId) async {
    try {
      final progressSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('progress')
          .where('completed', isEqualTo: true)
          .orderBy('completedAt', descending: true)
          .get();

      return progressSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'topicId': data['topicId'],
          'progress': data['progress'],
          'finalScore': data['finalScore'],
          'quizScore': data['quizScore'],
          'completedAt': (data['completedAt'] as Timestamp).millisecondsSinceEpoch,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Utility methods
  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete('topics');
      await db.delete('user_progress');
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> deleteDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'zachuma.db');
      await databaseFactory.deleteDatabase(path);
      _database = null;
    } catch (e) {
      // Handle error silently
    }
  }

  // Debug methods
  Future<void> debugDatabase() async {
    try {
      final db = await database;

      // Check topics table
      final topics = await db.query('topics');
      print('=== TOPICS TABLE (${topics.length} rows) ===');
      for (var topic in topics) {
        print('ID: ${topic['id']}, Title: ${topic['title']}, Content Length: ${topic['content']?.toString().length ?? 0}');
      }


      // Check database schema
      final tableInfo = await db.rawQuery("PRAGMA table_info(user_progress)");
      print('=== USER_PROGRESS SCHEMA ===');
      for (var column in tableInfo) {
        print('Column: ${column['name']}, Type: ${column['type']}, Default: ${column['dflt_value']}');
      }

    } catch (e) {
      print('Error debugging database: $e');
    }
  }
}