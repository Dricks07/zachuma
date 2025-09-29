import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../constants.dart';
import '../../services/admin_repository.dart';
import 'reviewer_shell.dart';

class ReviewerTopicReview extends StatefulWidget {
  final String topicId;
  final Map<String, dynamic> topicData;

  const ReviewerTopicReview({
    super.key,
    required this.topicId,
    required this.topicData,
  });

  @override
  State<ReviewerTopicReview> createState() => _ReviewerTopicReviewState();
}

class _ReviewerTopicReviewState extends State<ReviewerTopicReview> {
  final repo = AdminRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return ReviewerShell(
      title: "Review Topic",
      currentIndex: 1,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topic Title
            Text(
              widget.topicData['title'] ?? 'Untitled Topic',
              style: AppTextStyles.heading.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 16),

            // Topic Metadata
            _buildTopicMetadata(),
            const SizedBox(height: 24),

            // Content Section
            _buildContentSection(),
            const SizedBox(height: 24),

            // Quiz Questions (if any)
            if (widget.topicData.containsKey('quizQuestions') &&
                (widget.topicData['quizQuestions'] as List).isNotEmpty)
              _buildQuizSection(),

            if (widget.topicData.containsKey('quizQuestions') &&
                (widget.topicData['quizQuestions'] as List).isNotEmpty)
              const SizedBox(height: 24),

            // Feedback Section
            _buildFeedbackSection(),
            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicMetadata() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        Chip(
          label: Text(
            widget.topicData['category'] ?? 'Uncategorized',
            style: AppTextStyles.regular.copyWith(fontSize: 12),
          ),
          backgroundColor: AppColors.primary.withOpacity(0.2),
        ),
        Chip(
          label: Text(
            widget.topicData['level'] ?? 'beginner',
            style: AppTextStyles.regular.copyWith(fontSize: 12),
          ),
          backgroundColor: AppColors.accent.withOpacity(0.2),
        ),
        Chip(
          label: Text(
            widget.topicData['status'] ?? 'draft',
            style: AppTextStyles.regular.copyWith(
              fontSize: 12,
              color: _getStatusColor(widget.topicData['status'] ?? 'draft'),
            ),
          ),
          backgroundColor: _getStatusColor(widget.topicData['status'] ?? 'draft').withOpacity(0.2),
        ),
        if (widget.topicData['authorName'] != null)
          Chip(
            label: Text(
              'By: ${widget.topicData['authorName']}',
              style: AppTextStyles.regular.copyWith(fontSize: 12),
            ),
            backgroundColor: AppColors.surface,
          ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Content",
          style: AppTextStyles.subHeading,
        ),
        const SizedBox(height: 12),
        Text(
          widget.topicData['description'] ?? 'No description',
          style: AppTextStyles.regular,
        ),
        const SizedBox(height: 16),
        Divider(color: Colors.grey[300]),
        const SizedBox(height: 16),
        // Render Markdown content without card background
        _buildMarkdownContent(widget.topicData['content']),
      ],
    );
  }

  Widget _buildMarkdownContent(String? content) {
    if (content == null || content.isEmpty) {
      return Text(
        'No content available',
        style: AppTextStyles.regular.copyWith(
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return MarkdownBody(
      data: content,
      styleSheet: MarkdownStyleSheet(
        p: AppTextStyles.regular.copyWith(height: 1.6),
        h1: AppTextStyles.heading,
        h2: AppTextStyles.subHeading,
        h3: AppTextStyles.midFont.copyWith(fontSize: 20),
        h4: AppTextStyles.midFont,
        strong: const TextStyle(fontWeight: FontWeight.bold),
        em: const TextStyle(fontStyle: FontStyle.italic),
        blockquote: TextStyle(
          fontStyle: FontStyle.italic,
          color: AppColors.textSecondary,
        ),
        blockquoteDecoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(
            left: BorderSide(
              color: AppColors.primary,
              width: 4,
            ),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        code: TextStyle(
          backgroundColor: Colors.grey[100],
          color: AppColors.textPrimary,
          fontFamily: 'monospace',
        ),
        codeblockPadding: const EdgeInsets.all(16),
        codeblockDecoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        listIndent: 24.0,
        listBullet: TextStyle(color: AppColors.primary),
        tableHead: const TextStyle(fontWeight: FontWeight.bold),
        tableBody: AppTextStyles.regular,
        tableBorder: TableBorder.all(color: Colors.grey[300]!, width: 1),
        tableHeadAlign: TextAlign.center,
        tableColumnWidth: const FlexColumnWidth(),
      ),
      selectable: true,
    );
  }

  Widget _buildQuizSection() {
    final quizQuestions = List<Map<String, dynamic>>.from(widget.topicData['quizQuestions'] ?? []);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quiz Questions (${quizQuestions.length})",
              style: AppTextStyles.subHeading,
            ),
            const SizedBox(height: 12),
            ...quizQuestions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Q${index + 1}: ${question['question']}",
                      style: AppTextStyles.midFont.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...(question['options'] as List<dynamic>).asMap().entries.map((optionEntry) {
                      final optionIndex = optionEntry.key;
                      final option = optionEntry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              optionIndex == question['correctIndex']
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: optionIndex == question['correctIndex']
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option,
                                style: AppTextStyles.regular,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Reviewer Feedback",
              style: AppTextStyles.subHeading,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Enter your feedback here...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FilledButton.icon(
          onPressed: _isSubmitting ? null : () => _submitReview('rejected'),
          icon: const Icon(Icons.close),
          label: const Text("Reject"),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : () => _submitReview('published'),
          icon: const Icon(Icons.check),
          label: const Text("Approve"),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
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

  Future<void> _submitReview(String status) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUser = _auth.currentUser;
      final feedback = _feedbackController.text.trim();

      // Update the topic status and add feedback
      await _firestore.collection('topics').doc(widget.topicId).update({
        'status': status,
        'published': status == 'published',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': currentUser?.uid,
        'reviewerFeedback': FieldValue.arrayUnion([
          {
            'reviewerId': currentUser?.uid,
            'reviewerName': currentUser?.displayName ?? currentUser?.email,
            'message': feedback,
            'createdAt': Timestamp.now(),
            'status': status,
          }
        ]),
      });

      // Send notification to the author (content creator)
      if (widget.topicData['authorId'] != null) {
        await _firestore.collection('notifications').add({
          'userId': widget.topicData['authorId'],
          'title': 'Topic ${_capitalize(status)}',
          'message': 'Your topic "${widget.topicData['title']}" has been $status. ${feedback.isNotEmpty ? "Feedback: ${feedback.substring(0, feedback.length > 100 ? 100 : feedback.length)}${feedback.length > 100 ? '...' : ''}" : ""}',
          'type': 'feedback',
          'read': false,
          'createdAt': Timestamp.now(),
          'topicId': widget.topicId,
        });
      }

      // If published, send notification to all learners (users with role 'user')
      if (status == 'published') {
        try {
          // Get all learners (users with role 'user')
          final learnersQuery = await _firestore
              .collection('users')
              .where('role', isEqualTo: 'user')
              .get();

          // Send notification to each learner
          for (final learner in learnersQuery.docs) {
            await _firestore.collection('notifications').add({
              'userId': learner.id,
              'title': 'New Topic Available',
              'message': 'A new topic "${widget.topicData['title']}" in ${widget.topicData['category']} has been published and is now available to read.',
              'type': 'new_content',
              'read': false,
              'createdAt': Timestamp.now(),
              'topicId': widget.topicId,
            });
          }
        } catch (e) {
          // Don't fail the whole operation if we can't notify learners
          print('Error notifying learners: $e');
        }
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Topic $status successfully"),
          backgroundColor: status == 'published' ? AppColors.success : AppColors.error,
        ),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}