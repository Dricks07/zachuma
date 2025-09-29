// screens/admin/admin_dash.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  int users = 0, topics = 0, alerts = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
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

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return AdminShell(
      title: "Admin Dashboard",
      currentIndex: 0,
      child: loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
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
            _buildAdminQuickActions(),

            const SizedBox(height: 30),

            Text("Recent Alerts", style: AppTextStyles.subHeading),
            const SizedBox(height: 14),
            _buildRecentAlerts(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminQuickActions() {
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
          "Manage Users",
          Icons.people,
          AppColors.primary,
              () => Navigator.pushNamed(context, '/admin/users'),
        ),
        _buildQuickAction(
          "View Analytics",
          Icons.analytics,
          AppColors.success,
              () => Navigator.pushNamed(context, '/admin/analytics'),
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

  Widget _buildRecentAlerts() {
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
      constraints: const BoxConstraints(minHeight: 200),
      child: StreamBuilder<QuerySnapshot>(
        stream: repo.streamAlerts(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final docs = snap.data!.docs.take(5).toList();
          if (docs.isEmpty) {
            return Center(
              child: Text("No alerts yet.", style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary)),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.background),
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.notifications, color: AppColors.secondary),
                title: Text(d['title'] ?? 'Alert', style: AppTextStyles.midFont),
                subtitle: Text(d['message'] ?? '', style: AppTextStyles.notificationText),
                trailing: Text(
                  _formatTimeAgo(d['createdAt']),
                  style: AppTextStyles.notificationText,
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
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.notifications,
                title: "System Alerts",
                value: "$alerts",
                onTap: () => Navigator.pushNamed(context, '/admin/alerts'),
                iconColor: AppColors.error,
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
      ],
    );
  }
}