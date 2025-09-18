// lib/screens/reviewer/reviewer_alerts.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import 'reviewer_shell.dart';

class ReviewerAlerts extends StatefulWidget {
  const ReviewerAlerts({super.key});

  @override
  State<ReviewerAlerts> createState() => _ReviewerAlertsState();
}

class _ReviewerAlertsState extends State<ReviewerAlerts> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filterType = 'all';

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return ReviewerShell(
        title: "Reviewer Alerts",
        currentIndex: 2,
        child: const Center(child: Text("Please sign in to view alerts")),
      );
    }

    return ReviewerShell(
      title: "Reviewer Alerts",
      currentIndex: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Review Notifications", style: AppTextStyles.heading.copyWith(fontSize: 24)),
            const SizedBox(height: 16),

            // Alert stats with real data
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('notifications')
                  .where('userId', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        CircularProgressIndicator(),
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data!.docs;
                final unreadCount = notifications.where((n) => !(n.data() as Map<String, dynamic>)['read']).length;
                final todayCount = notifications.where((n) {
                  final data = n.data() as Map<String, dynamic>;
                  final time = data['createdAt'] as Timestamp;
                  final now = DateTime.now();
                  final notificationDate = time.toDate();
                  return notificationDate.year == now.year &&
                      notificationDate.month == now.month &&
                      notificationDate.day == now.day;
                }).length;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Total', '${notifications.length}', AppColors.primary),
                      _buildStatItem('Unread', '$unreadCount', AppColors.warning),
                      _buildStatItem('Today', '$todayCount', AppColors.success),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Filter options
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filterType == 'all',
                  onSelected: (selected) {
                    setState(() {
                      _filterType = selected ? 'all' : _filterType;
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Unread'),
                  selected: _filterType == 'unread',
                  onSelected: (selected) {
                    setState(() {
                      _filterType = selected ? 'unread' : _filterType;
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Today'),
                  selected: _filterType == 'today',
                  onSelected: (selected) {
                    setState(() {
                      _filterType = selected ? 'today' : _filterType;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Alerts list header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Alerts",
                  style: AppTextStyles.subHeading.copyWith(fontSize: 20),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                  onPressed: () {
                    setState(() {});
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Alerts list with real data
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('notifications')
                    .where('userId', isEqualTo: currentUser.uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final notifications = snapshot.data!.docs;

                  // Apply filters
                  final filteredNotifications = notifications.where((notification) {
                    final data = notification.data() as Map<String, dynamic>;

                    if (_filterType == 'all') return true;
                    if (_filterType == 'unread') return !data['read'];
                    if (_filterType == 'today') {
                      final time = data['createdAt'] as Timestamp;
                      final now = DateTime.now();
                      final notificationDate = time.toDate();
                      return notificationDate.year == now.year &&
                          notificationDate.month == now.month &&
                          notificationDate.day == now.day;
                    }

                    return true;
                  }).toList();

                  if (filteredNotifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            "No notifications",
                            style: AppTextStyles.subHeading,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _filterType == 'all'
                                ? "You'll see notifications here when you receive them"
                                : "No ${_filterType} notifications",
                            style: AppTextStyles.regular.copyWith(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = filteredNotifications[index];
                      final data = notification.data() as Map<String, dynamic>;

                      return _buildAlertCard(notification.id, data);
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

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: AppTextStyles.regular.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.midFont.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(String id, Map<String, dynamic> alert) {
    IconData icon;
    Color color;

    switch (alert['type']) {
      case 'new':
        icon = Icons.new_releases;
        color = AppColors.warning;
        break;
      case 'completed':
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case 'metrics':
        icon = Icons.analytics;
        color = AppColors.primary;
        break;
      case 'feedback':
        icon = Icons.feedback;
        color = AppColors.accent;
        break;
      default:
        icon = Icons.notifications;
        color = AppColors.textSecondary;
    }

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _firestore.collection('notifications').doc(id).delete();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: !alert['read'] ? Border.all(color: color, width: 1) : null,
        ),
        child: InkWell(
          onTap: () {
            _firestore.collection('notifications').doc(id).update({'read': true});
          },
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert['title'] ?? 'Notification',
                      style: AppTextStyles.regular.copyWith(
                        fontWeight: FontWeight.w600,
                        color: alert['read'] ? AppColors.textPrimary : color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert['message'] ?? 'No message',
                      style: AppTextStyles.regular.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(alert['createdAt']),
                      style: AppTextStyles.regular.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!alert['read'])
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(Timestamp timestamp) {
    final now = DateTime.now();
    final time = timestamp.toDate();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${time.day}/${time.month}/${time.year}';
  }
}