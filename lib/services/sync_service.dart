// lib/services/sync_service.dart
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:za_chuma/services/database_helper.dart';
import 'package:za_chuma/services/admin_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AdminRepository _repo = AdminRepository();
  bool _isSyncing = false;

  // 🔹 Helper to sanitize Firestore data (convert Timestamp → millis, recursive)
  dynamic _sanitizeData(dynamic value) {
    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    } else if (value is Map) {
      return value.map((k, v) => MapEntry(k, _sanitizeData(v)));
    } else if (value is List) {
      return value.map(_sanitizeData).toList();
    }
    return value;
  }

  Future<void> syncData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult != ConnectivityResult.none) {
      try {
        print('🔄 Starting data sync...');

        // Use get() to get all documents
        final QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('topics')
            .where('published', isEqualTo: true)
            .where('status', isEqualTo: 'published')
            .get();

        final topics = snapshot.docs;
        print('📊 Found ${topics.length} published topics to sync');

        if (topics.isEmpty) {
          print('⚠️ No published topics found in Firestore');
          _isSyncing = false;
          return;
        }

        // Save to local database
        for (var doc in topics) {
          final data = doc.data() as Map<String, dynamic>;

          print('📝 Topic: ${data['title']} (ID: ${doc.id})');
          print('   Content length: ${data['content']?.toString().length ?? 0} chars');

          // Convert Timestamp to milliseconds for createdAt and lastUpdated
          int? createdAtMillis;
          int? lastUpdatedMillis;

          if (data['createdAt'] is Timestamp) {
            createdAtMillis = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
          } else if (data['createdAt'] != null) {
            createdAtMillis = data['createdAt'];
          }

          if (data['lastUpdated'] is Timestamp) {
            lastUpdatedMillis = (data['lastUpdated'] as Timestamp).millisecondsSinceEpoch;
          } else if (data['lastUpdated'] != null) {
            lastUpdatedMillis = data['lastUpdated'];
          }

          // Sanitize quizQuestions data (convert any Timestamps to milliseconds)
          String quizQuestionsJson = '[]';
          if (data.containsKey('quizQuestions') && data['quizQuestions'] != null) {
            try {
              final sanitizedQuizQuestions = _sanitizeData(data['quizQuestions']);
              quizQuestionsJson = jsonEncode(sanitizedQuizQuestions);
              print('   Quiz questions: ${sanitizedQuizQuestions.length} questions');
            } catch (e) {
              print('   ❌ Error sanitizing quiz questions: $e');
              quizQuestionsJson = '[]';
            }
          }

          final topicData = {
            'id': doc.id,
            'title': data['title'] ?? '',
            'description': data['description'] ?? '',
            'content': data['content'] ?? '',
            'category': data['category'] ?? '',
            'level': data['level'] ?? 'beginner',
            'imageUrl': data['imageUrl'] ?? '',
            'status': data['status'] ?? '',
            'published': (data['published'] ?? false) ? 1 : 0,
            'duration': data['duration'] ?? '30m',
            'rating': (data['rating'] ?? 4.0).toDouble(),
            'createdAt': createdAtMillis,
            'lastUpdated': lastUpdatedMillis,
            'quizQuestions': quizQuestionsJson,
          };

          await _dbHelper.insertOrUpdateTopic(topicData);
          print('✅ Synced topic: ${data['title']}');
        }

        print('🎉 Data sync completed successfully');

      } catch (e) {
        print('❌ Sync error: $e');
        print('Stack trace: ${e.toString()}');
        rethrow;
      } finally {
        _isSyncing = false;
      }
    } else {
      print('🌐 No internet connection, skipping sync');
      _isSyncing = false;
    }
  }

  Future<List<Map<String, dynamic>>> getTopics() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      // If online, sync data first
      if (connectivityResult != ConnectivityResult.none) {
        await syncData();
      }

      // Return data from local database
      final topics = await _dbHelper.getTopics();
      print('📚 Retrieved ${topics.length} topics from local database');

      if (topics.isEmpty) {
        print('⚠️ No topics found in local database');
      } else {
        for (var topic in topics) {
          print('   - ${topic['title']} (ID: ${topic['id']})');
          print('     Content length: ${topic['content']?.toString().length ?? 0} chars');
        }
      }

      return topics;
    } catch (e) {
      print('❌ Error getting topics: $e');
      return [];
    }
  }

  Future<void> forceSync() async {
    await syncData();
  }

  bool get isSyncing => _isSyncing;

  // Debug method to check database state
  Future<void> debugDatabase() async {
    print('🔍 Debugging database...');
    final topics = await _dbHelper.getTopics();
    print('Total topics in DB: ${topics.length}');

    for (var topic in topics) {
      print('--- Topic: ${topic['title']} ---');
      print('ID: ${topic['id']}');
      print('Content: ${topic['content']?.toString().substring(0, 100)}...');
      print('Published: ${topic['published']}');
      print('Status: ${topic['status']}');

      // Check if quizQuestions is stored properly
      if (topic['quizQuestions'] != null) {
        try {
          final quizData = jsonDecode(topic['quizQuestions']);
          print('Quiz questions: ${quizData.length}');
        } catch (e) {
          print('Error parsing quiz questions: $e');
        }
      }

      print('----------------------------');
    }
  }
}