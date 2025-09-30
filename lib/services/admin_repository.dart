import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ----- Topics (replaced Courses) -----
  CollectionReference get topicsCol => _db.collection('topics');

  Future<String> createTopic(Map<String, dynamic> data) async {
    final doc = await topicsCol.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateTopic(String id, Map<String, dynamic> data) async {
    await topicsCol.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTopic(String id) async {
    await topicsCol.doc(id).delete();
  }

  Stream<QuerySnapshot> streamTopics() {
    return topicsCol.orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot> streamTopicsForReview() {
    return topicsCol
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> streamTopicsByStatus(String status) {
    return topicsCol
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ----- Quiz Questions (subcollection) -----
  CollectionReference quizCol(String topicId) =>
      topicsCol.doc(topicId).collection('quiz');

  Future<String> addQuizQuestion(String topicId, Map<String, dynamic> data) async {
    final doc = await quizCol(topicId).add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateQuizQuestion(
      String topicId, String questionId, Map<String, dynamic> data) async {
    await quizCol(topicId).doc(questionId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteQuizQuestion(String topicId, String questionId) async {
    await quizCol(topicId).doc(questionId).delete();
  }

  Stream<QuerySnapshot> streamQuizQuestions(String topicId) =>
      quizCol(topicId).orderBy('createdAt').snapshots();

  // ----- Users (updated for new roles) -----
  CollectionReference get usersCol => _db.collection('users');

  Future<void> setUserRole(String uid, String role) async {
    await usersCol.doc(uid).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setUserStatus(String uid, bool blocked) async {
    await usersCol.doc(uid).update({
      'blocked': blocked,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> streamUsers() =>
      usersCol.orderBy('createdAt', descending: true).snapshots();

  Stream<QuerySnapshot> streamUsersByRole(String role) {
    return usersCol
        .where('role', isEqualTo: role)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ----- Feedback (subcollection for topic ratings) -----
  CollectionReference feedbackCol(String topicId) =>
      topicsCol.doc(topicId).collection('feedback');

  Future<String> addFeedback(String topicId, Map<String, dynamic> data) async {
    final doc = await feedbackCol(topicId).add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<QuerySnapshot> streamFeedback(String topicId) =>
      feedbackCol(topicId).orderBy('createdAt', descending: true).snapshots();

  Future<double> getTopicRating(String topicId) async {
    final snapshot = await feedbackCol(topicId).get();
    if (snapshot.docs.isEmpty) return 0.0;

    double total = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['rating'] ?? 0).toDouble();
    }
    return total / snapshot.docs.length;
  }

  // ----- Alerts -----
  CollectionReference get alertsCol => _db.collection('alerts');

  Future<String> createAlert(Map<String, dynamic> data) async {
    final doc = await alertsCol.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<QuerySnapshot> streamAlerts() =>
      alertsCol.orderBy('createdAt', descending: true).snapshots();

  // Topic-specific alerts
  Future<String> createTopicAlert(String topicId, String type, String message) async {
    return createAlert({
      'type': type,
      'topicId': topicId,
      'message': message,
      'read': false,
    });
  }

  // ----- Settings (single doc) -----
  DocumentReference get settingsDoc => _db.collection('settings').doc('app');

  Future<void> updateSettings(Map<String, dynamic> data) async {
    await settingsDoc.set(data, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot> streamSettings() => settingsDoc.snapshots();

  // ----- Stats (for dashboard) -----
  Future<int> countCollection(CollectionReference col) async {
    final agg = await col.count().get();
    return agg.count ?? 0;
  }

  Future<Map<String, int>> getTopicStats() async {
    final stats = <String, int>{
      'total': 0,
      'published': 0,
      'pending': 0,
      'draft': 0,
      'rejected': 0,
    };

    // Get total count
    final totalAgg = await topicsCol.count().get();
    stats['total'] = totalAgg.count ?? 0;

    // Get counts by status
    final statuses = ['published', 'pending', 'draft', 'rejected'];
    for (final status in statuses) {
      final agg = await topicsCol.where('status', isEqualTo: status).count().get();
      stats[status] = agg.count ?? 0;
    }

    return stats;
  }

  Future<Map<String, int>> getUserStats() async {
    final stats = <String, int>{
      'total': 0,
      'admin': 0,
      'expert': 0,
      'reviewer': 0,
      'user': 0,
    };

    // Get total count
    final totalAgg = await usersCol.count().get();
    stats['total'] = totalAgg.count ?? 0;

    // Get counts by role
    final roles = ['admin', 'expert', 'reviewer', 'user'];
    for (final role in roles) {
      final agg = await usersCol.where('role', isEqualTo: role).count().get();
      stats[role] = agg.count ?? 0;
    }

    return stats;
  }

  // ----- Analytics -----
  Future<Map<String, dynamic>> getTopicAnalytics(String topicId) async {
    final topicDoc = await topicsCol.doc(topicId).get();
    final topicData = topicDoc.data() as Map<String, dynamic>? ?? {};

    // Get feedback count and average rating
    final feedbackSnapshot = await feedbackCol(topicId).get();
    final feedbackCount = feedbackSnapshot.docs.length;

    double totalRating = 0;
    for (final doc in feedbackSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalRating += (data['rating'] ?? 0).toDouble();
    }
    final averageRating = feedbackCount > 0 ? totalRating / feedbackCount : 0;

    return {
      'views': topicData['views'] ?? 0,
      'feedbackCount': feedbackCount,
      'averageRating': averageRating,
      'completionRate': topicData['completionRate'] ?? 0,
    };
  }

  // ----- Search -----
  Stream<QuerySnapshot> searchTopics(String query) {
    if (query.isEmpty) {
      return topicsCol.orderBy('createdAt', descending: true).snapshots();
    }

    return topicsCol
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots();
  }

  Stream<QuerySnapshot> searchTopicsByCategory(String category) {
    if (category.isEmpty) {
      return topicsCol.orderBy('createdAt', descending: true).snapshots();
    }

    return topicsCol
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> searchTopicsByLevel(String level) {
    if (level.isEmpty) {
      return topicsCol.orderBy('createdAt', descending: true).snapshots();
    }

    return topicsCol
        .where('level', isEqualTo: level)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getPublishedTopics() {
    return FirebaseFirestore.instance
        .collection('topics')
        .where('published', isEqualTo: true)
        .where('status', isEqualTo: 'published')
        .snapshots();
  }


// method for direct query
  Future<QuerySnapshot> getPublishedTopicsOnce() {
    return FirebaseFirestore.instance
        .collection('topics')
        .where('published', isEqualTo: true)
        .where('status', isEqualTo: 'published')
        .get();
  }


  Future<List<Map<String, dynamic>>> getUserActivityReport(DateTimeRange dateRange) async {
    final snapshot = await usersCol
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end))
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'UserID': doc.id,
        'Name': data['name'] ?? 'N/A',
        'Email': data['email'] ?? 'N/A',
        'Role': data['role'] ?? 'user',
        'Registered On': data['createdAt'],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getContentStatusReport(DateTimeRange dateRange) async {
    final snapshot = await topicsCol
        .where('updatedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
        .where('updatedAt', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end))
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'TopicID': doc.id,
        'Title': data['title'] ?? 'N/A',
        'Author': data['authorName'] ?? 'N/A',
        'Status': data['status'] ?? 'draft',
        'Category': data['category'] ?? 'N/A',
        'Level': data['level'] ?? 'N/A',
        'Last Updated': data['updatedAt'],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getSystemLogsReport(DateTimeRange dateRange) async {
    final snapshot = await alertsCol
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end))
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'Timestamp': data['createdAt'],
        'Type': data['type'] ?? 'LOG',
        'Title': data['title'] ?? 'System Log',
        'Message': data['message'] ?? 'No details',
      };
    }).toList();
  }
}