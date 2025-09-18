// lib/screens/reviewer/reviewer_review.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/admin_repository.dart';
import 'reviewer_shell.dart';
import 'reviewer_topic_review.dart'; // Import the new review screen

class ReviewerReview extends StatefulWidget {
  const ReviewerReview({super.key});

  @override
  State<ReviewerReview> createState() => _ReviewerReviewState();
}

class _ReviewerReviewState extends State<ReviewerReview> {
  final repo = AdminRepository();
  bool _isLoading = true;
  String? _errorMessage;
  int _streamKey = 0; // Key to refresh stream

  @override
  void initState() {
    super.initState();
    // Add a small delay to show loading state
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _refreshStream() {
    setState(() {
      _streamKey++; // Change key to refresh stream
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ReviewerShell(
      title: "Review Topics",
      currentIndex: 1,
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("Pending Review", style: AppTextStyles.heading.copyWith(fontSize: 24)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshStream,
                  tooltip: "Refresh",
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot>(
                key: Key(_streamKey.toString()), // Key to refresh stream
                stream: repo.streamTopicsForReview(),
                builder: (context, snap) {
                  // Handle errors
                  if (snap.hasError) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _errorMessage == null) {
                        setState(() {
                          _errorMessage = snap.error.toString();
                        });
                      }
                    });

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          const Text(
                            "Error loading topics",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              _errorMessage ?? "Unknown error",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_errorMessage?.contains("index") ?? false)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                "This error usually means you need to create a Firestore index. Check the console for a link to create it automatically.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _refreshStream,
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    );
                  }

                  // Handle connection state
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Handle no data
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                          const SizedBox(height: 16),
                          Text(
                            "No topics pending review",
                            style: AppTextStyles.subHeading,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "All topics have been reviewed",
                            style: AppTextStyles.regular.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // Display data
                  final docs = snap.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final topic = docs[index];
                      final data = topic.data() as Map<String, dynamic>;
                      return _ReviewTopicCard(
                        topicId: topic.id,
                        data: data,
                        onApprove: () => _updateStatus(context, topic.id, 'published'),
                        onReject: () => _updateStatus(context, topic.id, 'rejected'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String topicId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('topics')
          .doc(topicId)
          .update({
        'status': status,
        'published': status == 'published',
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Topic $status successfully"),
          backgroundColor: status == 'published' ? AppColors.success : AppColors.error,
        ),
      );

      // Refresh the stream to update the UI
      _refreshStream();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _ReviewTopicCard extends StatelessWidget {
  final String topicId;
  final Map<String, dynamic> data;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ReviewTopicCard({
    required this.topicId,
    required this.data,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Level row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    data['title'] ?? 'Untitled',
                    style: AppTextStyles.subHeading,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Chip(
                  label: Text(
                    (data['level']?.toString() ?? 'beginner').toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: AppColors.accent.withOpacity(0.2),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Category
            if (data['category'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Category: ${data['category']}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),

            // Description
            Text(
              data['description'] ?? 'No description',
              style: AppTextStyles.regular.copyWith(color: Colors.grey[700]),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // Quiz questions count
            if (data.containsKey('quizQuestions') && data['quizQuestions'] is List)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Quiz questions: ${(data['quizQuestions'] as List).length}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Buttons - responsive layout
            if (isSmallScreen)
            // Vertical layout for small screens
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewerTopicReview(
                            topicId: topicId,
                            topicData: data,
                          ),
                        ),
                      ),
                      child: const Text("Review Content"),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                          onPressed: onApprove,
                          child: const Text("Approve"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                          onPressed: onReject,
                          child: const Text("Reject"),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
            // Horizontal layout for larger screens
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewerTopicReview(
                          topicId: topicId,
                          topicData: data,
                        ),
                      ),
                    ),
                    child: const Text("Review Content"),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                    onPressed: onApprove,
                    child: const Text("Approve"),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                    onPressed: onReject,
                    child: const Text("Reject"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}