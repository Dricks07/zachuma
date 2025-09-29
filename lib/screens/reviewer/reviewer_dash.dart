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

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return ReviewerShell(
      title: "Reviewer Dashboard",
      currentIndex: 0,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Content Review Overview",
              style: AppTextStyles.heading.copyWith(fontSize: 26),
            ),
            const SizedBox(height: 20),

            // Overview Cards
            isMobile ? _buildMobileOverviewCards() : _buildDesktopOverviewCards(),

            const SizedBox(height: 30),

            // Quick Actions
            Text("Quick Actions", style: AppTextStyles.subHeading),
            const SizedBox(height: 14),
            _buildReviewerQuickActions(isMobile: isMobile),

            const SizedBox(height: 30),

            // Pending Reviews
            Text("Topics Needing Review", style: AppTextStyles.subHeading),
            const SizedBox(height: 14),
            _buildPendingReviews(),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewerQuickActions({required bool isMobile}) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 3.0 : 2.5,
      ),
      children: [
        _buildQuickAction(
          "Start Reviewing",
          Icons.rate_review,
          AppColors.primary,
              () => Navigator.pushNamed(context, '/reviewer/review'),
          isMobile: isMobile,
        ),
        _buildQuickAction(
          "Review Guidelines",
          Icons.description,
          AppColors.secondary,
              () => Navigator.pushNamed(context, '/reviewer/help'),
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildQuickAction(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap, {
        required bool isMobile,
      }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 20 : 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: isMobile ? 24 : 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.midFont.copyWith(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
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
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final topics = snapshot.data!.docs;
          if (topics.isEmpty) {
            return Center(
              child: Text("No topics pending review.",
                  style: AppTextStyles.regular),
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
              final authorId = data['authorId'] ?? '';

              return ListTile(
                leading: const Icon(Icons.hourglass_empty, color: AppColors.warning),
                title: Text(data['title'] ?? 'Untitled', style: AppTextStyles.regular),
                subtitle: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(authorId).get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return Text('Loading author...', style: AppTextStyles.notificationText);
                    }

                    if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return Text('By: Unknown', style: AppTextStyles.notificationText);
                    }

                    final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                    final authorName = userData['name'] ?? 'Unknown';
                    return Text('By: $authorName', style: AppTextStyles.notificationText);
                  },
                ),
                trailing: Text(_formatTimeAgo(data['createdAt']), style: AppTextStyles.notificationText),
                onTap: () => Navigator.pushNamed(context, '/reviewer/review', arguments: {'topicId': doc.id}),
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

  Stream<int> _countPending() {
    return repo.topicsCol
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _countReviewedToday() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    return repo.topicsCol
        .where('status', isNotEqualTo: 'pending')
        .where('reviewedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _countTotalReviewed() {
    return repo.topicsCol
        .where('status', isNotEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Widget _buildDesktopOverviewCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StreamBuilder<int>(
                stream: _countPending(),
                builder: (context, snapshot) {
                  final pending = snapshot.data ?? 0;
                  return _buildOverviewCard(
                    icon: Icons.hourglass_empty,
                    title: "Pending Review",
                    value: "$pending",
                    onTap: () => Navigator.pushNamed(context, '/reviewer/review'),
                    iconColor: AppColors.warning,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StreamBuilder<int>(
                stream: _countReviewedToday(),
                builder: (context, snapshot) {
                  final today = snapshot.data ?? 0;
                  return _buildOverviewCard(
                    icon: Icons.today,
                    title: "Reviewed Today",
                    value: "$today",
                    onTap: () => Navigator.pushNamed(context, '/reviewer/history?filter=today'),
                    iconColor: AppColors.success,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StreamBuilder<int>(
                stream: _countTotalReviewed(),
                builder: (context, snapshot) {
                  final total = snapshot.data ?? 0;
                  return _buildOverviewCard(
                    icon: Icons.checklist,
                    title: "Total Reviewed",
                    value: "$total",
                    onTap: () => Navigator.pushNamed(context, '/reviewer/history'),
                    iconColor: AppColors.primary,
                  );
                },
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
        StreamBuilder<int>(
          stream: _countPending(),
          builder: (context, snapshot) {
            final pending = snapshot.data ?? 0;
            return _buildOverviewCard(
              icon: Icons.hourglass_empty,
              title: "Pending Review",
              value: "$pending",
              onTap: () => Navigator.pushNamed(context, '/reviewer/review'),
              iconColor: AppColors.warning,
            );
          },
        ),
        const SizedBox(height: 16),
        StreamBuilder<int>(
          stream: _countReviewedToday(),
          builder: (context, snapshot) {
            final today = snapshot.data ?? 0;
            return _buildOverviewCard(
              icon: Icons.today,
              title: "Reviewed Today",
              value: "$today",
              onTap: () => Navigator.pushNamed(context, '/reviewer/history?filter=today'),
              iconColor: AppColors.success,
            );
          },
        ),
        const SizedBox(height: 16),
        StreamBuilder<int>(
          stream: _countTotalReviewed(),
          builder: (context, snapshot) {
            final total = snapshot.data ?? 0;
            return _buildOverviewCard(
              icon: Icons.checklist,
              title: "Total Reviewed",
              value: "$total",
              onTap: () => Navigator.pushNamed(context, '/reviewer/history'),
              iconColor: AppColors.primary,
            );
          },
        ),
      ],
    );
  }
}
