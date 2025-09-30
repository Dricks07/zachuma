import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import 'admin_shell.dart';

class AdminFeedback extends StatelessWidget {
  const AdminFeedback({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: "Feedback",
      currentIndex: 5,
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("User Feedback", style: AppTextStyles.heading.copyWith(fontSize: 24)),
            const SizedBox(height: 20),

            // Feedback Statistics
            _buildStatistics(),
            const SizedBox(height: 20),

            // Feedback List
            Expanded(
              child: _buildFeedbackList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedback')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final feedbacks = snapshot.data!.docs;
        final bugReports = feedbacks.where((doc) => doc['type'] == 'Bug Report').length;
        final suggestions = feedbacks.where((doc) => doc['type'] == 'Suggestion').length;
        final pending = feedbacks.where((doc) => doc['status'] != 'resolved').length;

        return Row(
          children: [
            _StatCard(
              title: "Total Feedback",
              count: feedbacks.length,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            _StatCard(
              title: "Bug Reports",
              count: bugReports,
              color: AppColors.error,
            ),
            const SizedBox(width: 12),
            _StatCard(
              title: "Suggestions",
              count: suggestions,
              color: AppColors.success,
            ),
            const SizedBox(width: 12),
            _StatCard(
              title: "Pending",
              count: pending,
              color: AppColors.warning,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeedbackList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedback')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading feedback: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No feedback submitted yet.'),
          );
        }

        final feedbacks = snapshot.data!.docs;

        return ListView.builder(
          itemCount: feedbacks.length,
          itemBuilder: (context, index) {
            final feedback = feedbacks[index];
            final data = feedback.data() as Map<String, dynamic>;

            return _FeedbackCard(
              feedbackId: feedback.id,
              data: data,
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _StatCard({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: AppTextStyles.heading.copyWith(
                  fontSize: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTextStyles.regular.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final String feedbackId;
  final Map<String, dynamic> data;

  const _FeedbackCard({
    required this.feedbackId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final userName = data['userName'] ?? 'Anonymous User';
    final userEmail = data['userEmail'] ?? 'No email';
    final type = data['type'] ?? 'Suggestion';
    final message = data['message'] ?? '';
    final timestamp = data['timestamp'] != null
        ? DateFormat('MMM dd, yyyy • HH:mm').format(
        (data['timestamp'] as Timestamp).toDate())
        : 'Unknown date';
    final status = data['status'] ?? 'new';
    final appVersion = data['appVersion'] ?? 'Unknown';
    final deviceInfo = data['deviceInfo'] ?? 'Unknown device';

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: AppTextStyles.midFont.copyWith(color: AppColors.surface),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: AppTextStyles.midFont),
                      Text(userEmail, style: AppTextStyles.notificationText),
                      Text(timestamp, style: AppTextStyles.notificationText),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Chip(
                      label: Text(
                        type,
                        style: AppTextStyles.notificationText.copyWith(
                          color: AppColors.surface,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: type == 'Bug Report' ? AppColors.error : AppColors.primary,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: AppTextStyles.notificationText.copyWith(
                          color: AppColors.surface,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.regular,
            ),
            const SizedBox(height: 12),

            // Additional info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'App Version: $appVersion • $deviceInfo',
                    style: AppTextStyles.notificationText,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                if (status != 'resolved') ...[
                  FilledButton(
                    onPressed: () => _markAsResolved(context, feedbackId),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text("Mark as Resolved"),
                  ),
                  const SizedBox(width: 8),
                ],
                FilledButton(
                  onPressed: () => _showFeedbackDetails(context, data),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text("View Details"),
                ),
                const SizedBox(width: 8),
                if (status == 'resolved')
                  Icon(Icons.check_circle, color: AppColors.success, size: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'resolved':
        return AppColors.success;
      case 'in-progress':
        return AppColors.warning;
      case 'new':
      default:
        return AppColors.primary;
    }
  }

  void _markAsResolved(BuildContext context, String feedbackId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Mark as Resolved", style: AppTextStyles.midFont),
        content: Text("Are you sure you want to mark this feedback as resolved?",
            style: AppTextStyles.regular),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: AppTextStyles.regular),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('feedback')
                    .doc(feedbackId)
                    .update({
                  'status': 'resolved',
                  'resolvedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Feedback marked as resolved",
                        style: AppTextStyles.regular.copyWith(color: AppColors.surface)),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error: ${e.toString()}",
                        style: AppTextStyles.regular.copyWith(color: AppColors.surface)),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text("Mark Resolved",
                style: AppTextStyles.regular.copyWith(color: AppColors.surface)),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Feedback Details", style: AppTextStyles.heading),
              const SizedBox(height: 20),

              _DetailRow("User", data['userName'] ?? 'Anonymous'),
              _DetailRow("Email", data['userEmail'] ?? 'No email'),
              _DetailRow("Type", data['type'] ?? 'Suggestion'),
              _DetailRow("Status", data['status'] ?? 'new'),
              _DetailRow("App Version", data['appVersion'] ?? 'Unknown'),
              _DetailRow("Device", data['deviceInfo'] ?? 'Unknown'),
              _DetailRow(
                  "Submitted",
                  data['timestamp'] != null
                      ? DateFormat('MMM dd, yyyy • HH:mm:ss').format(
                      (data['timestamp'] as Timestamp).toDate())
                      : 'Unknown'
              ),

              if (data['resolvedAt'] != null)
                _DetailRow(
                    "Resolved",
                    DateFormat('MMM dd, yyyy • HH:mm:ss').format(
                        (data['resolvedAt'] as Timestamp).toDate())
                ),

              const SizedBox(height: 20),
              Text("Message:", style: AppTextStyles.midFont),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(data['message'] ?? '', style: AppTextStyles.regular),
              ),

              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close", style: AppTextStyles.regular),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text("$label:",
                style: AppTextStyles.regular.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: AppTextStyles.regular)),
        ],
      ),
    );
  }
}