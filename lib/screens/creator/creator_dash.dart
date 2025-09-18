// screens/creator/creator_dash.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/admin_repository.dart';
import 'package:za_chuma/screens/creator/creator_shell.dart';

class CreatorDash extends StatefulWidget {
  const CreatorDash({super.key});

  @override
  State<CreatorDash> createState() => _CreatorDashState();
}

class _CreatorDashState extends State<CreatorDash> {
  final repo = AdminRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int myTopics = 0, published = 0, draft = 0, pending = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadMyTopics();
  }

  Future<void> _loadMyTopics() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() => loading = false);
        return;
      }

      // Get topics created by current user
      final topicsSnapshot = await _firestore
          .collection('topics')
          .where('authorId', isEqualTo: currentUser.uid)
          .get();

      final allTopics = topicsSnapshot.docs.length;
      final publishedCount = topicsSnapshot.docs
          .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'published')
          .length;
      final draftCount = topicsSnapshot.docs
          .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'draft')
          .length;
      final pendingCount = topicsSnapshot.docs
          .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'pending')
          .length;

      setState(() {
        myTopics = allTopics;
        published = publishedCount;
        draft = draftCount;
        pending = pendingCount;
        loading = false;
      });
    } catch (e) {
      print("Error loading topics: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return CreatorShell(
      title: "Creator Dashboard",
      currentIndex: 0,
      child: loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Overview", style: AppTextStyles.heading.copyWith(fontSize: isMobile ? 22 : 26)),
            const SizedBox(height: 10),

            // Overview Cards
            isMobile
                ? _buildMobileOverviewCards()
                : _buildDesktopOverviewCards(),

            const SizedBox(height: 20),

            // Quick Actions for Creator
            Text("Quick Actions", style: AppTextStyles.subHeading),
            const SizedBox(height: 14),
            _buildCreatorQuickActions(isMobile),

            const SizedBox(height: 20),

            Text("Recent Activity", style: AppTextStyles.subHeading),
            const SizedBox(height: 14),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatorQuickActions(bool isMobile) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 1.2 : 1.5,
      ),
      children: [
        _buildQuickAction(
          "New Topic",
          Icons.add_circle,
          AppColors.primary,
              () => Navigator.pushNamed(context, '/creator/add-content'),
        ),
        _buildQuickAction(
          "My Topics",
          Icons.list,
          AppColors.secondary,
              () => Navigator.pushNamed(context, '/creator/topics'),
        ),
        _buildQuickAction(
          "Drafts",
          Icons.edit,
          AppColors.warning,
              () => Navigator.pushNamed(context, '/creator/topics?filter=draft'),
        ),
        _buildQuickAction(
          "Feedback",
          Icons.feedback,
          AppColors.success,
              () => Navigator.pushNamed(context, '/creator/feedback'),
        ),
      ],
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTextStyles.midFont.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text("Please sign in to view your activity"),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Your recent topics:", style: AppTextStyles.midFont),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('topics')
                .where('authorId', isEqualTo: currentUser.uid)
                .orderBy('createdAt', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text("No topics created yet.", style: AppTextStyles.regular);
              }

              final topics = snapshot.data!.docs;
              return Column(
                children: topics.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final createdAt = data['createdAt'] is Timestamp
                      ? (data['createdAt'] as Timestamp).toDate()
                      : DateTime.now();

                  return ListTile(
                    leading: _getStatusIcon(data['status']),
                    title: Text(data['title'] ?? 'Untitled',
                        style: AppTextStyles.regular,
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      'Status: ${data['status']} • ${_formatDate(createdAt)}',
                      style: AppTextStyles.notificationText,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      // Navigate to topic detail
                      Navigator.pushNamed(
                          context,
                          '/creator/topics',
                          arguments: {'topicId': doc.id}
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
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

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'published':
        return Icon(Icons.check_circle, color: AppColors.success);
      case 'pending':
        return Icon(Icons.hourglass_empty, color: AppColors.warning);
      case 'draft':
        return Icon(Icons.edit, color: AppColors.accent);
      default:
        return Icon(Icons.circle, color: AppColors.textSecondary);
    }
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: AppTextStyles.midFont.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    )),
                    Text(value, style: AppTextStyles.heading.copyWith(
                        fontSize: 22,
                        color: AppColors.primary
                    )),
                  ],
                ),
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
                icon: Icons.article,
                title: "My Topics",
                value: "$myTopics",
                onTap: () => Navigator.pushNamed(context, '/creator/topics'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.check_circle,
                title: "Published",
                value: "$published",
                onTap: () => Navigator.pushNamed(context, '/creator/topics?filter=published'),
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
                icon: Icons.edit,
                title: "Drafts",
                value: "$draft",
                onTap: () => Navigator.pushNamed(context, '/creator/topics?filter=draft'),
                iconColor: AppColors.warning,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.hourglass_empty,
                title: "Pending",
                value: "$pending",
                onTap: () => Navigator.pushNamed(context, '/creator/topics?filter=pending'),
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
          icon: Icons.article,
          title: "My Topics",
          value: "$myTopics",
          onTap: () => Navigator.pushNamed(context, '/creator/topics'),
        ),
        const SizedBox(height: 16),
        _buildOverviewCard(
          icon: Icons.check_circle,
          title: "Published",
          value: "$published",
          onTap: () => Navigator.pushNamed(context, '/creator/topics?filter=published'),
          iconColor: AppColors.success,
        ),
        const SizedBox(height: 16),
        _buildOverviewCard(
          icon: Icons.edit,
          title: "Drafts",
          value: "$draft",
          onTap: () => Navigator.pushNamed(context, '/creator/topics?filter=draft'),
          iconColor: AppColors.warning,
        ),
        const SizedBox(height: 16),
        _buildOverviewCard(
          icon: Icons.hourglass_empty,
          title: "Pending",
          value: "$pending",
          onTap: () => Navigator.pushNamed(context, '/creator/topics?filter=pending'),
          iconColor: AppColors.accent,
        ),
      ],
    );
  }
}