import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import 'creator_shell.dart';

class CreatorFeedback extends StatefulWidget {
  final String? topicId; // Optional topicId to filter feedback

  const CreatorFeedback({super.key, this.topicId});

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
      title: widget.topicId != null ? "Topic Feedback" : "Reviewer Feedback",
      currentIndex: 4,
      child: currentUser == null
          ? const Center(child: Text("Please sign in to view feedback"))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page heading
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
            child: Text(
              widget.topicId != null
                  ? "Topic Review Feedback"
                  : "Feedback from Reviewers",
              style: AppTextStyles.heading.copyWith(fontSize: 22),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              widget.topicId != null
                  ? "All feedback received for this topic from reviewers"
                  : "All feedback received across all your topics",
              style: AppTextStyles.regular.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Feedback list
          Expanded(
            child: _buildFeedbackList(currentUser.uid),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackList(String userId) {
    // If a specific topic is provided, only query that topic
    if (widget.topicId != null && widget.topicId!.isNotEmpty) {
      return StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('topics')
            .doc(widget.topicId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.feedback_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "Topic not found",
                    style: AppTextStyles.subHeading,
                  ),
                ],
              ),
            );
          }

          final topicData = snapshot.data!.data() as Map<String, dynamic>;
          final feedbackList = List<Map<String, dynamic>>.from(topicData['reviewerFeedback'] ?? []);

          if (feedbackList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.feedback_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "No feedback for this topic",
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

          // Prepare feedback items
          final List<Map<String, dynamic>> allFeedback = [];
          for (var feedback in feedbackList) {
            allFeedback.add({
              ...feedback,
              'topicTitle': topicData['title'] ?? 'Untitled Topic',
              'topicStatus': topicData['status'] ?? 'unknown',
            });
          }

          // Sort by createdAt (latest first)
          allFeedback.sort((a, b) {
            final dateA = a['createdAt'] is Timestamp
                ? (a['createdAt'] as Timestamp).toDate()
                : DateTime.tryParse(a['createdAt'].toString()) ?? DateTime(1970);
            final dateB = b['createdAt'] is Timestamp
                ? (b['createdAt'] as Timestamp).toDate()
                : DateTime.tryParse(b['createdAt'].toString()) ?? DateTime(1970);
            return dateB.compareTo(dateA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(5),
            itemCount: allFeedback.length,
            itemBuilder: (context, index) {
              final feedback = allFeedback[index];
              return _buildSingleFeedbackCard(feedback);
            },
          );
        },
      );
    }

    // If no specific topic is provided, query all topics by the user
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('topics')
          .where('authorId', isEqualTo: userId)
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
                  "No topics found",
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

        // Filter documents locally to only include those with non-empty feedback
        final topicsWithFeedback = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final feedback = data['reviewerFeedback'] ?? [];
          return feedback.isNotEmpty;
        }).toList();

        if (topicsWithFeedback.isEmpty) {
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

        // Flatten all feedback into a single list
        final List<Map<String, dynamic>> allFeedback = [];
        for (var doc in topicsWithFeedback) {
          final topicData = doc.data() as Map<String, dynamic>;
          final feedbackList =
          List<Map<String, dynamic>>.from(topicData['reviewerFeedback'] ?? []);

          for (var feedback in feedbackList) {
            allFeedback.add({
              ...feedback,
              'topicTitle': topicData['title'] ?? 'Untitled Topic',
              'topicStatus': topicData['status'] ?? 'unknown',
              'topicId': doc.id, // Add topic ID for reference
            });
          }
        }

        // Sort by createdAt (latest first)
        allFeedback.sort((a, b) {
          final dateA = a['createdAt'] is Timestamp
              ? (a['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(a['createdAt'].toString()) ?? DateTime(1970);
          final dateB = b['createdAt'] is Timestamp
              ? (b['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(b['createdAt'].toString()) ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(5),
          itemCount: allFeedback.length,
          itemBuilder: (context, index) {
            final feedback = allFeedback[index];
            return _buildSingleFeedbackCard(feedback);
          },
        );
      },
    );
  }

  Widget _buildSingleFeedbackCard(Map<String, dynamic> feedback) {
    // Get reviewer display name (name if available, otherwise email)
    String reviewerDisplayName = feedback['reviewerName'] ??
        feedback['reviewerEmail'] ??
        'Unknown Reviewer';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topic info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    feedback['topicTitle'] ?? 'Untitled Topic',
                    style: AppTextStyles.subHeading,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    (feedback['topicStatus'] ?? 'UNKNOWN')
                        .toString()
                        .toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(feedback['topicStatus']),
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor:
                  _getStatusColor(feedback['topicStatus']).withOpacity(0.2),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Reviewer + date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  reviewerDisplayName,
                  style: AppTextStyles.regular
                      .copyWith(fontWeight: FontWeight.bold),
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

            const Divider(),
            const SizedBox(height: 8),

            // Feedback message
            Text(
              feedback['message'] ?? 'No feedback message',
              style: AppTextStyles.regular,
            ),
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