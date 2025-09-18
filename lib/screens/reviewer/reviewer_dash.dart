// screens/reviewer/reviewer_dash.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/admin_repository.dart';
import '../reviewer/reviewer_shell.dart';

class ReviewerDash extends StatefulWidget {
  const ReviewerDash({super.key});

  @override
  State<ReviewerDash> createState() => _ReviewerDashState();
}

class _ReviewerDashState extends State<ReviewerDash> {
  final repo = AdminRepository();
  int pendingReviews = 0, reviewedToday = 0, totalReviewed = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadReviewStats();
  }

  Future<void> _loadReviewStats() async {
    try {
      // Get pending reviews
      final pendingSnapshot = await repo.topicsCol
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      // Get today's reviews (you'll need to track this in your data model)
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      // This would require a 'reviewedAt' timestamp field in your topics

      setState(() {
        pendingReviews = pendingSnapshot.count ?? 0;
        reviewedToday = 0; // Implement actual counting logic
        totalReviewed = 0; // Implement actual counting logic
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return ReviewerShell(
      title: "Reviewer Dashboard",
      currentIndex: 0,
      child: loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Content Review Overview", style: AppTextStyles.heading.copyWith(fontSize: 26)),
            const SizedBox(height: 20),

            // Overview Cards
            isMobile
                ? _buildMobileOverviewCards()
                : _buildDesktopOverviewCards(),

            const SizedBox(height: 30),

            // Quick Actions for Reviewer
            Text("Quick Actions", style: AppTextStyles.subHeading),
            const SizedBox(height: 14),
            _buildReviewerQuickActions(),

            const SizedBox(height: 30),

            Text("Topics Needing Review", style: AppTextStyles.subHeading),
            const SizedBox(height: 14),
            _buildPendingReviews(),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewerQuickActions() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.5,
      ),
      children: [
        _buildQuickAction(
          "Start Reviewing",
          Icons.rate_review,
          AppColors.primary,
              () => Navigator.pushNamed(context, '/reviewer/review'),
        ),
        _buildQuickAction(
          "Review Guidelines",
          Icons.description,
          AppColors.secondary,
              () => Navigator.pushNamed(context, '/reviewer/guidelines'),
        ),
        _buildQuickAction(
          "Quality Metrics",
          Icons.analytics,
          AppColors.success,
              () => Navigator.pushNamed(context, '/reviewer/metrics'),
        ),
        _buildQuickAction(
          "Feedback History",
          Icons.history,
          AppColors.accent,
              () => Navigator.pushNamed(context, '/reviewer/history'),
        ),
      ],
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.midFont,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingReviews() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: repo.topicsCol
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final topics = snapshot.data!.docs;
          if (topics.isEmpty) {
            return Center(
              child: Text("No topics pending review.", style: AppTextStyles.regular),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topics.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.background),
            itemBuilder: (_, i) {
              final doc = topics[i];
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.hourglass_empty, color: AppColors.warning),
                title: Text(data['title'] ?? 'Untitled', style: AppTextStyles.regular),
                subtitle: Text('By: ${data['authorName'] ?? 'Unknown'}', style: AppTextStyles.notificationText),
                trailing: Text(
                  _formatTimeAgo(data['createdAt']),
                  style: AppTextStyles.notificationText,
                ),
                onTap: () => Navigator.pushNamed(
                    context,
                    '/reviewer/review',
                    arguments: {'topicId': doc.id}
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    final time = timestamp is Timestamp ? timestamp.toDate() : DateTime.now();
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    Color iconColor = AppColors.primary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        color: AppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 30, color: iconColor),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: AppTextStyles.midFont.copyWith(color: AppColors.textSecondary)),
                  Text(value, style: AppTextStyles.heading.copyWith(fontSize: 24, color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopOverviewCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.hourglass_empty,
                title: "Pending Review",
                value: "$pendingReviews",
                onTap: () => Navigator.pushNamed(context, '/reviewer/review'),
                iconColor: AppColors.warning,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.today,
                title: "Reviewed Today",
                value: "$reviewedToday",
                onTap: () => Navigator.pushNamed(context, '/reviewer/history?filter=today'),
                iconColor: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.checklist,
                title: "Total Reviewed",
                value: "$totalReviewed",
                onTap: () => Navigator.pushNamed(context, '/reviewer/history'),
                iconColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.timer,
                title: "Avg. Time",
                value: "8min",
                onTap: () => Navigator.pushNamed(context, '/reviewer/metrics'),
                iconColor: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileOverviewCards() {
    return Column(
      children: [
        _buildOverviewCard(
          icon: Icons.hourglass_empty,
          title: "Pending Review",
          value: "$pendingReviews",
          onTap: () => Navigator.pushNamed(context, '/reviewer/review'),
          iconColor: AppColors.warning,
        ),
        const SizedBox(height: 16),
        _buildOverviewCard(
          icon: Icons.today,
          title: "Reviewed Today",
          value: "$reviewedToday",
          onTap: () => Navigator.pushNamed(context, '/reviewer/history?filter=today'),
          iconColor: AppColors.success,
        ),
        const SizedBox(height: 16),
        _buildOverviewCard(
          icon: Icons.checklist,
          title: "Total Reviewed",
          value: "$totalReviewed",
          onTap: () => Navigator.pushNamed(context, '/reviewer/history'),
          iconColor: AppColors.primary,
        ),
        const SizedBox(height: 16),
        _buildOverviewCard(
          icon: Icons.timer,
          title: "Avg. Time",
          value: "8min",
          onTap: () => Navigator.pushNamed(context, '/reviewer/metrics'),
          iconColor: AppColors.accent,
        ),
      ],
    );
  }
}