import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import '../../services/admin_repository.dart';
import 'admin_shell.dart';

class AdminDash extends StatefulWidget {
  const AdminDash({super.key});

  @override
  State<AdminDash> createState() => _AdminDashState();
}

class _AdminDashState extends State<AdminDash> {
  final repo = AdminRepository();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  int users = 0, topics = 0, alerts = 0;
  bool loading = true;
  int unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _loadUnreadNotifications();
  }

  Future<void> _loadCounts() async {
    try {
      final u = await repo.countCollection(repo.usersCol);
      final c = await repo.countCollection(repo.topicsCol);
      final a = await repo.countCollection(repo.alertsCol);

      setState(() {
        users = u;
        topics = c;
        alerts = a;
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  void _loadUnreadNotifications() {
    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: currentUser?.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          unreadNotifications = snapshot.docs.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return AdminShell(
      title: "Admin Dashboard",
      currentIndex: 0,
      unreadNotifications: unreadNotifications,
      child: loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("System Overview", style: AppTextStyles.heading.copyWith(fontSize: 26)),
                  const SizedBox(height: 20),

                  // Overview Cards
                  isMobile
                      ? _buildMobileOverviewCards()
                      : _buildDesktopOverviewCards(),

                  const SizedBox(height: 30),

                  // Quick Actions for Admin
                  Text("Quick Actions", style: AppTextStyles.subHeading),
                  const SizedBox(height: 14),
                  _buildAdminQuickActions(isMobile: isMobile),

                  const SizedBox(height: 30),

                  Text("Recent Alerts", style: AppTextStyles.subHeading),
                  const SizedBox(height: 14),
                  _buildRecentAlerts(),
                  const SizedBox(height: 20), // Added extra padding at bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminQuickActions({required bool isMobile}) {
    final actions = [
      _QuickActionData(
        title: "Manage Users",
        icon: Icons.people,
        color: AppColors.primary,
        route: '/admin/users',
      ),
      _QuickActionData(
        title: "Content Management",
        icon: Icons.article,
        color: AppColors.success,
        route: '/admin/topics',
      ),
      _QuickActionData(
        title: "View Analytics",
        icon: Icons.analytics,
        color: AppColors.accent,
        route: '/admin/analytics',
      ),
      _QuickActionData(
        title: "System Feedback",
        icon: Icons.feedback,
        color: AppColors.warning,
        route: '/admin/feedback',
      ),
    ];

    return SizedBox(
      height: isMobile ? 120 : 100, // Fixed height to prevent overflow
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isMobile ? 2 : 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isMobile ? 1.5 : 2.0, // Adjusted for better fit
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return _buildQuickActionCard(action);
        },
      ),
    );
  }

  Widget _buildQuickActionCard(_QuickActionData action) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, action.route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12), // Reduced padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32, // Smaller icon
                height: 32,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, color: action.color, size: 16),
              ),
              const SizedBox(height: 6), // Reduced spacing
              Text(
                action.title,
                style: AppTextStyles.regular.copyWith( // Smaller font
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAlerts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentUser?.uid)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildAlertsLoading();
        }

        if (snapshot.hasError) {
          return _buildAlertsError(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildNoAlerts();
        }

        final alerts = snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with view all button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Notifications",
                    style: AppTextStyles.subHeading.copyWith(fontSize: 18),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/admin/alerts'),
                    child: Text(
                      "View All",
                      style: AppTextStyles.regular.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Alerts list
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: alerts.length,
                separatorBuilder: (_, __) => const Divider(height: 16, color: AppColors.background),
                itemBuilder: (_, index) {
                  final alert = alerts[index];
                  final data = alert.data() as Map<String, dynamic>;
                  return _buildAlertListItem(alert.id, data);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertListItem(String alertId, Map<String, dynamic> data) {
    final isRead = data['isRead'] ?? false;
    final type = data['type'] ?? 'general';
    final title = data['title'] ?? 'Notification';
    final message = data['message'] ?? '';
    final timestamp = data['timestamp'] != null
        ? _formatTimeAgo((data['timestamp'] as Timestamp).toDate())
        : 'Recently';

    Color dotColor;
    switch (type) {
      case 'feedback':
        dotColor = AppColors.accent;
        break;
      case 'user':
        dotColor = AppColors.success;
        break;
      case 'system':
        dotColor = AppColors.warning;
        break;
      default:
        dotColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: () => _handleAlertTap(alertId, data, context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: isRead ? AppColors.textSecondary : dotColor,
              shape: BoxShape.circle,
            ),
          ),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.midFont.copyWith(
                          fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                          color: isRead ? AppColors.textPrimary : dotColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      timestamp,
                      style: AppTextStyles.notificationText.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTextStyles.regular.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsLoading() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildAlertsError(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            'Failed to load alerts',
            style: AppTextStyles.midFont,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoAlerts() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.notifications_off, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'No notifications',
            style: AppTextStyles.midFont,
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _handleAlertTap(String alertId, Map<String, dynamic> data, BuildContext context) async {
    // Mark as read if unread
    if (!(data['isRead'] ?? false)) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(alertId)
          .update({'isRead': true});
    }

    // Navigate based on type
    final type = data['type'];
    switch (type) {
      case 'feedback':
        Navigator.pushNamed(context, '/admin/feedback');
        break;
      case 'user':
        Navigator.pushNamed(context, '/admin/users');
        break;
      case 'system':
      // Show system alert details
        _showAlertDetails(data, context);
        break;
      default:
        Navigator.pushNamed(context, '/admin/alerts');
        break;
    }
  }

  void _showAlertDetails(Map<String, dynamic> data, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['title'] ?? 'Alert Details'),
        content: Text(data['message'] ?? 'No additional details available.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: AppTextStyles.regular),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${difference.inDays ~/ 7}w ago';
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: AppTextStyles.midFont.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(value, style: AppTextStyles.heading.copyWith(fontSize: 24, color: AppColors.primary)),
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
                icon: Icons.people,
                title: "Total Users",
                value: "$users",
                onTap: () => Navigator.pushNamed(context, '/admin/users'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.article,
                title: "Total Topics",
                value: "$topics",
                onTap: () => Navigator.pushNamed(context, '/admin/topics'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.notifications,
                title: "System Alerts",
                value: "$alerts",
                onTap: () => Navigator.pushNamed(context, '/admin/alerts'),
                iconColor: AppColors.error,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.feedback,
                title: "Unread Notifications",
                value: "$unreadNotifications",
                onTap: () => Navigator.pushNamed(context, '/admin/alerts'),
                iconColor: AppColors.warning,
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
          icon: Icons.people,
          title: "Total Users",
          value: "$users",
          onTap: () => Navigator.pushNamed(context, '/admin/users'),
        ),
        const SizedBox(height: 16),
        _buildOverviewCard(
          icon: Icons.article,
          title: "Total Topics",
          value: "$topics",
          onTap: () => Navigator.pushNamed(context, '/admin/topics'),
        ),
        const SizedBox(height: 16),
        _buildOverviewCard(
          icon: Icons.notifications,
          title: "System Alerts",
          value: "$alerts",
          onTap: () => Navigator.pushNamed(context, '/admin/alerts'),
          iconColor: AppColors.error,
        ),
        const SizedBox(height: 16),
        _buildOverviewCard(
          icon: Icons.feedback,
          title: "Unread Notifications",
          value: "$unreadNotifications",
          onTap: () => Navigator.pushNamed(context, '/admin/alerts'),
          iconColor: AppColors.warning,
        ),
      ],
    );
  }
}

class _QuickActionData {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  _QuickActionData({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });
}