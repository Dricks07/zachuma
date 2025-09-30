import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import 'admin_shell.dart';

class AdminAlerts extends StatefulWidget {
  const AdminAlerts({super.key});

  @override
  State<AdminAlerts> createState() => _AdminAlertsState();
}

class _AdminAlertsState extends State<AdminAlerts> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _filterType = 'all';

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: "Alerts",
      currentIndex: 3,
      child: Padding(
        padding: const EdgeInsets.all(16), // FIX: Added padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text("Notifications", style: AppTextStyles.heading.copyWith(fontSize: 24)),
            const SizedBox(height: 16),
            Text(
              "Manage and review system alerts and notifications",
              style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Statistics
            _buildStatistics(),
            const SizedBox(height: 16),

            // Filter and actions
            _buildFilterBar(),
            const SizedBox(height: 16),

            // Alerts list - FIX: Added Expanded
            Expanded(
              child: _buildNotificationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildStatsLoading();
        }

        final notifications = snapshot.data!.docs;
        final total = notifications.length;
        final unread = notifications.where((doc) => !(doc['isRead'] ?? false)).length;
        final feedbackCount = notifications.where((doc) => doc['type'] == 'feedback').length;

        // FIX: Removed priority field check since it doesn't exist
        final urgent = notifications.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Check if it's unread and of important types
          return !(data['isRead'] ?? false) &&
              (data['type'] == 'system' || data['type'] == 'feedback');
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
              _buildStatItem('Total', total.toString(), AppColors.primary),
              _buildStatItem('Unread', unread.toString(), AppColors.secondary),
              _buildStatItem('Feedback', feedbackCount.toString(), AppColors.accent),
              _buildStatItem('Urgent', urgent.toString(), AppColors.error),
            ],
          ),
        );
      },
    );
  }

  // ... rest of your AdminAlerts methods remain the same
  Widget _buildStatsLoading() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', '...', AppColors.primary),
          _buildStatItem('Unread', '...', AppColors.secondary),
          _buildStatItem('Feedback', '...', AppColors.accent),
          _buildStatItem('Urgent', '...', AppColors.error),
        ],
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
            fontSize: 12,
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

  Widget _buildFilterBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Recent Alerts",
          style: AppTextStyles.subHeading.copyWith(fontSize: 20),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.mark_email_read, color: AppColors.primary),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.filter_list, color: AppColors.primary),
              onSelected: (value) {
                setState(() {
                  _filterType = value;
                });
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'all', child: Text('All Notifications')),
                PopupMenuItem(value: 'unread', child: Text('Unread Only')),
                PopupMenuItem(value: 'feedback', child: Text('Feedback')),
                PopupMenuItem(value: 'user', child: Text('User Activity')),
                PopupMenuItem(value: 'system', child: Text('System')),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationsList() {
    Query query = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: currentUser?.uid)
        .orderBy('timestamp', descending: true);

    if (_filterType == 'unread') {
      query = query.where('isRead', isEqualTo: false);
    } else if (_filterType != 'all') {
      query = query.where('type', isEqualTo: _filterType);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading notifications: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final notifications = snapshot.data!.docs;

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final data = notification.data() as Map<String, dynamic>;

            return _buildNotificationCard(
              notification.id,
              data,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: AppTextStyles.midFont.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            _filterType == 'all'
                ? 'You\'re all caught up!'
                : 'No ${_filterType == 'unread' ? 'unread' : _filterType} notifications',
            style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(String notificationId, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Notification';
    final message = data['message'] ?? '';
    final type = data['type'] ?? 'general';
    final isRead = data['isRead'] ?? false;
    final timestamp = data['timestamp'] != null
        ? DateFormat('MMM dd, yyyy • HH:mm').format(
        (data['timestamp'] as Timestamp).toDate())
        : 'Unknown time';
    final feedbackId = data['feedbackId'];

    // FIX: Removed priority field since it doesn't exist
    final hasHighPriority = type == 'system' || !isRead;

    IconData icon;
    Color color;
    Color backgroundColor;

    switch (type) {
      case 'feedback':
        icon = Icons.feedback;
        color = AppColors.accent;
        backgroundColor = AppColors.accent.withOpacity(0.2);
        break;
      case 'user':
        icon = Icons.person_add;
        color = AppColors.success;
        backgroundColor = AppColors.success.withOpacity(0.2);
        break;
      case 'system':
        icon = Icons.system_update;
        color = AppColors.warning;
        backgroundColor = AppColors.warning.withOpacity(0.2);
        break;
      case 'course':
        icon = Icons.library_books;
        color = AppColors.primary;
        backgroundColor = AppColors.primary.withOpacity(0.2);
        break;
      default:
        icon = Icons.notifications;
        color = AppColors.textSecondary;
        backgroundColor = AppColors.textSecondary.withOpacity(0.2);
    }

    return GestureDetector(
      onTap: () => _handleNotificationTap(notificationId, data, context),
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
          border: hasHighPriority
              ? Border.all(color: AppColors.error, width: 2)
              : (!isRead ? Border.all(color: color, width: 1) : null),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.regular.copyWith(
                            fontWeight: FontWeight.w600,
                            color: !isRead ? color : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (hasHighPriority)
                        Icon(Icons.priority_high, color: AppColors.error, size: 16),
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
                  const SizedBox(height: 4),
                  Text(
                    timestamp,
                    style: AppTextStyles.regular.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            if (!isRead)
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
    );
  }

  void _handleNotificationTap(String notificationId, Map<String, dynamic> data, BuildContext context) async {
    if (!(data['isRead'] ?? false)) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    }

    final type = data['type'];
    final feedbackId = data['feedbackId'];

    switch (type) {
      case 'feedback':
        if (feedbackId != null) {
          Navigator.pushNamed(context, '/admin/feedback');
        } else {
          Navigator.pushNamed(context, '/admin/feedback');
        }
        break;
      case 'user':
        Navigator.pushNamed(context, '/admin/users');
        break;
      case 'course':
        Navigator.pushNamed(context, '/admin/content');
        break;
      case 'system':
        _showSystemAlertDialog(data, context);
        break;
      default:
        _showNotificationDetails(data, context);
        break;
    }
  }

  void _showSystemAlertDialog(Map<String, dynamic> data, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['title'] ?? 'System Alert'),
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

  void _showNotificationDetails(Map<String, dynamic> data, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['title'] ?? 'Notification Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(data['message'] ?? 'No message content.'),
              const SizedBox(height: 16),
              if (data['timestamp'] != null)
                Text(
                  'Received: ${DateFormat('MMM dd, yyyy • HH:mm:ss').format((data['timestamp'] as Timestamp).toDate())}',
                  style: AppTextStyles.regular.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: AppTextStyles.regular),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    try {
      final unreadNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentUser?.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Marked all notifications as read',
            style: AppTextStyles.regular.copyWith(color: AppColors.surface),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error marking notifications as read: ${e.toString()}',
            style: AppTextStyles.regular.copyWith(color: AppColors.surface),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}