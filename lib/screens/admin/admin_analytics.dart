import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import '../../services/admin_repository.dart';
import 'admin_shell.dart';

class AdminAnalytics extends StatefulWidget {
  const AdminAnalytics({super.key});

  @override
  State<AdminAnalytics> createState() => _AdminAnalyticsState();
}

class _AdminAnalyticsState extends State<AdminAnalytics> {
  final AdminRepository _repo = AdminRepository();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final cardWidth = isMobile ? screenWidth * 0.9 : 260.0;

    return AdminShell(
      title: "Analytics",
      currentIndex: 4,
      child: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Platform Analytics", style: AppTextStyles.heading.copyWith(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                "Real-time overview of system metrics and user engagement.",
                style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Stats Overview
              _buildStatsOverview(isMobile, cardWidth),
              const SizedBox(height: 28),

              // Analytics Placeholder (Charts)
              _buildAnalyticsChartPlaceholder(),
              const SizedBox(height: 28),

              // Recent Activity Logs
              _buildActivityLog(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview(bool isMobile, double cardWidth) {
    return StreamBuilder<Map<String, int>>(
      stream: _getCombinedStatsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text("No analytics data available."));
        }

        final stats = snapshot.data!;
        final totalUsers = stats['totalUsers'] ?? 0;
        final totalTopics = stats['totalTopics'] ?? 0;
        final publishedTopics = stats['publishedTopics'] ?? 0;
        final pendingTopics = stats['pendingTopics'] ?? 0;

        final statCards = [
          _buildStatCard("Total Users", totalUsers.toString(), Icons.people, AppColors.primary),
          _buildStatCard("Total Topics", totalTopics.toString(), Icons.article, AppColors.secondary),
          _buildStatCard("Published", publishedTopics.toString(), Icons.check_circle, AppColors.success),
          _buildStatCard("Pending Review", pendingTopics.toString(), Icons.hourglass_empty, AppColors.warning),
        ];

        return Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: statCards.map((card) {
              return SizedBox(width: cardWidth, child: card);
            }).toList(),
          ),
        );
      },
    );
  }

  Stream<Map<String, int>> _getCombinedStatsStream() {
    Stream<QuerySnapshot> usersStream = _repo.usersCol.snapshots();
    Stream<QuerySnapshot> topicsStream = _repo.topicsCol.snapshots();

    return usersStream.asyncMap((userSnapshot) async {
      final topicSnapshot = await topicsStream.first;

      final totalUsers = userSnapshot.size;
      final totalTopics = topicSnapshot.size;
      final publishedTopics = topicSnapshot.docs.where((doc) => doc['status'] == 'published').length;
      final pendingTopics = topicSnapshot.docs.where((doc) => doc['status'] == 'pending').length;

      return {
        'totalUsers': totalUsers,
        'totalTopics': totalTopics,
        'publishedTopics': publishedTopics,
        'pendingTopics': pendingTopics,
      };
    });
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {}, // reserved for future interactions
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 12),
              Text(
                value,
                style: AppTextStyles.heading.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsChartPlaceholder() {
    return Card(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          height: 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 50, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "User Engagement Charts (Coming Soon)",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.midFont.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Recent Activity Log", style: AppTextStyles.subHeading.copyWith(fontSize: 20)),
        const SizedBox(height: 12),
        Card(
          color: AppColors.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            height: 340,
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream: _repo.alertsCol.orderBy('createdAt', descending: true).limit(10).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No recent activity."));
                }

                final logs = snapshot.data!.docs;

                return ListView.separated(
                  itemCount: logs.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final log = logs[index].data() as Map<String, dynamic>;
                    final timestamp = log['createdAt'] as Timestamp?;
                    final date = timestamp != null
                        ? DateFormat('MMM d, yyyy - hh:mm a').format(timestamp.toDate())
                        : 'No date';
                    return ListTile(
                      leading: _getLogIcon(log['type']),
                      title: Text(
                        log['title'] ?? 'System Log',
                        style: AppTextStyles.midFont.copyWith(fontSize: 15),
                      ),
                      subtitle: Text(
                        log['message'] ?? 'No details',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        date,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Icon _getLogIcon(String? type) {
    switch (type) {
      case 'user':
        return const Icon(Icons.person_add, color: AppColors.success);
      case 'feedback':
        return const Icon(Icons.feedback, color: AppColors.accent);
      case 'new_content':
        return const Icon(Icons.article, color: AppColors.primary);
      default:
        return const Icon(Icons.notifications, color: AppColors.textSecondary);
    }
  }
}
