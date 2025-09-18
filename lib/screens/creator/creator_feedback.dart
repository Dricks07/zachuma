// lib/screens/creator/creator_feedback.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import 'creator_shell.dart';

class CreatorFeedback extends StatefulWidget {
  const CreatorFeedback({super.key});

  @override
  State<CreatorFeedback> createState() => _CreatorFeedbackState();
}

class _CreatorFeedbackState extends State<CreatorFeedback> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return CreatorShell(
      title: "Reviewer Feedback",
      currentIndex: 4,
      child: currentUser == null
          ? const Center(child: Text("Please sign in to view feedback"))
          : StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('topics')
            .where('authorId', isEqualTo: currentUser.uid)
            .where('reviewerFeedback', isNotEqualTo: [])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.feedback_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "No feedback yet",
                    style: AppTextStyles.subHeading,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Feedback from reviewers will appear here",
                    style: AppTextStyles.regular.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final topics = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              final data = topic.data() as Map<String, dynamic>;
              final feedbackList = List<Map<String, dynamic>>.from(data['reviewerFeedback'] ?? []);

              return _buildTopicFeedbackCard(topic.id, data, feedbackList);
            },
          );
        },
      ),
    );
  }

  Widget _buildTopicFeedbackCard(String topicId, Map<String, dynamic> topicData, List<Map<String, dynamic>> feedbackList) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              topicData['title'] ?? 'Untitled Topic',
              style: AppTextStyles.subHeading,
            ),
            const SizedBox(height: 8),

            // Topic status
            Chip(
              label: Text(
                topicData['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                style: TextStyle(
                  color: _getStatusColor(topicData['status']),
                  fontSize: 12,
                ),
              ),
              backgroundColor: _getStatusColor(topicData['status']).withOpacity(0.2),
            ),

            const SizedBox(height: 16),

            // Feedback list
            Text(
              "Reviewer Feedback (${feedbackList.length})",
              style: AppTextStyles.midFont.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...feedbackList.map((feedback) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(feedback['status']).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reviewer info and date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          feedback['reviewerName'] ?? 'Unknown Reviewer',
                          style: AppTextStyles.regular.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _formatDate(feedback['createdAt']),
                          style: AppTextStyles.regular.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Status
                    Chip(
                      label: Text(
                        feedback['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                        style: TextStyle(
                          color: _getStatusColor(feedback['status']),
                          fontSize: 10,
                        ),
                      ),
                      backgroundColor: _getStatusColor(feedback['status']).withOpacity(0.2),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),

                    const SizedBox(height: 8),

                    // Feedback message
                    Text(
                      feedback['message'] ?? 'No feedback message',
                      style: AppTextStyles.regular,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'published':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      case 'draft':
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'Invalid date';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}