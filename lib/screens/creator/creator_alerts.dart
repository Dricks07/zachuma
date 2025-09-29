// lib/screens/creator/creator_alerts.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import 'creator_shell.dart';
import 'creator_feedback.dart'; // Import the feedback screen

class CreatorAlerts extends StatefulWidget {
  const CreatorAlerts({super.key});

  @override
  State<CreatorAlerts> createState() => _CreatorAlertsState();
}

class _CreatorAlertsState extends State<CreatorAlerts> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filterType = 'all';

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return CreatorShell(
        title: "My Alerts",
        currentIndex: 3,
        child: const Center(child: Text("Please sign in to view alerts")),
      );
    }

    final currentUserId = currentUser.uid;

    return CreatorShell(
      title: "My Alerts",
      currentIndex: 3,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("My Notifications", style: AppTextStyles.heading.copyWith(fontSize: 24)),
            const SizedBox(height: 16),

            // Alert stats
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('notifications')
                  .where('userId', isEqualTo: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifications = snapshot.data!.docs;
                final unreadCount = notifications.where((n) => !(n.data() as Map<String, dynamic>)['read']).length;
                final feedbackCount = notifications.where((n) =>
                (n.data() as Map<String, dynamic>)['type'] == 'feedback' &&
                    !(n.data() as Map<String, dynamic>)['read']).length;

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
                      _buildStatItem('Unread', '$unreadCount', AppColors.secondary),
                      _buildStatItem('Feedback', '$feedbackCount', AppColors.accent),
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
                  label: const Text('Feedback'),
                  selected: _filterType == 'feedback',
                  onSelected: (selected) {
                    setState(() {
                      _filterType = selected ? 'feedback' : _filterType;
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
              ],
            ),

            const SizedBox(height: 16),

            // Alerts list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('notifications')
                    .where('userId', isEqualTo: currentUserId)
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
                    if (_filterType == 'feedback') return data['type'] == 'feedback';
                    if (_filterType == 'unread') return !data['read'];

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
    VoidCallback? onTap;

    switch (alert['type']) {
      case 'approval':
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case 'revision':
        icon = Icons.edit;
        color = AppColors.warning;
        break;
      case 'feedback':
        icon = Icons.feedback;
        color = AppColors.accent;
        onTap = () {
          // Navigate to feedback screen with the specific topicId
          final topicId = alert['topicId'];
          if (topicId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreatorFeedback(topicId: topicId),
              ),
            );
          } else {
            // If no topicId, navigate to general feedback page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatorFeedback()),
            );
          }
        };
        break;
      case 'collaboration':
        icon = Icons.group_add;
        color = AppColors.primary;
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
            if (onTap != null) onTap!();
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

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';

    DateTime time;
    if (timestamp is Timestamp) {
      time = timestamp.toDate();
    } else {
      return 'Invalid time';
    }

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${time.day}/${time.month}/${time.year}';
  }
}