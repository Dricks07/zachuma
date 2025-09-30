import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import 'creator_shell.dart';
import 'creator_feedback.dart';

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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildStatsLoading();
                }

                if (snapshot.hasError) {
                  return _buildStatsError(snapshot.error.toString());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildStatsEmpty();
                }

                final notifications = snapshot.data!.docs;
                final unreadCount = notifications.where((n) {
                  final data = n.data() as Map<String, dynamic>;
                  return !(data['read'] ?? false);
                }).length;

                final feedbackCount = notifications.where((n) {
                  final data = n.data() as Map<String, dynamic>;
                  return data['type'] == 'feedback' && !(data['read'] ?? false);
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

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('notifications')
                    .where('userId', isEqualTo: currentUserId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    print('Error loading notifications: ${snapshot.error}'); // Debug print
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading notifications',
                            style: AppTextStyles.midFont,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    print('No notifications data found'); // Debug print
                    return _buildEmptyState();
                  }

                  final notifications = snapshot.data!.docs;
                  print('Found ${notifications.length} notifications'); // Debug print

                  // Apply filters
                  final filteredNotifications = notifications.where((notification) {
                    final data = notification.data() as Map<String, dynamic>;

                    if (_filterType == 'all') return true;
                    if (_filterType == 'feedback') return data['type'] == 'feedback';
                    if (_filterType == 'unread') return !(data['read'] ?? false); // CHANGED: 'read' instead of 'isRead'

                    return true;
                  }).toList();

                  print('Filtered to ${filteredNotifications.length} notifications'); // Debug print

                  if (filteredNotifications.isEmpty) {
                    return _buildEmptyState(filtered: true);
                  }

                  return ListView.builder(
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = filteredNotifications[index];
                      final data = notification.data() as Map<String, dynamic>;
                      print('Notification $index: $data'); // Debug print

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
        ],
      ),
    );
  }

  Widget _buildStatsEmpty() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'No notifications yet',
          style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildStatsError(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 24, color: AppColors.error),
          const SizedBox(height: 8),
          Text(
            'Failed to load stats',
            style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
          ),
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

  Widget _buildEmptyState({bool filtered = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            "No notifications",
            style: AppTextStyles.subHeading,
          ),
          const SizedBox(height: 8),
          Text(
            filtered
                ? "No ${_filterType == 'unread' ? 'unread' : _filterType} notifications"
                : "You'll see notifications here when you receive them",
            style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(String id, Map<String, dynamic> alert) {
    final isRead = alert['read'] ?? false; // CHANGED: 'read' instead of 'isRead'
    final type = alert['type'] ?? 'general';
    final title = alert['title'] ?? 'Notification';
    final message = alert['message'] ?? 'No message content';
    final timestamp = alert['createdAt']; // CHANGED: 'createdAt' instead of 'timestamp'

    IconData icon;
    Color color;
    VoidCallback? onTap;

    switch (type) {
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
          final topicId = alert['topicId'];
          if (topicId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreatorFeedback(topicId: topicId),
              ),
            );
          } else {
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
          border: !isRead ? Border.all(color: color, width: 1) : null,
        ),
        child: InkWell(
          onTap: () {
            if (!isRead) {
              _firestore.collection('notifications').doc(id).update({'read': true}); // CHANGED: 'read' instead of 'isRead'
            }
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
                      title,
                      style: AppTextStyles.regular.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isRead ? AppColors.textPrimary : color,
                      ),
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
                      _formatTime(timestamp),
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
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';

    try {
      DateTime time;
      if (timestamp is Timestamp) {
        time = timestamp.toDate();
      } else {
        return 'Invalid time';
      }

      final now = DateTime.now();
      final difference = now.difference(time);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';

      return DateFormat('MMM dd, yyyy').format(time);
    } catch (e) {
      return 'Unknown time';
    }
  }
}