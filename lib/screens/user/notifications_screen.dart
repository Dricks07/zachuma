import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import 'user_shell.dart'; // Import the UserShell

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return UserShell(
      title: 'Notifications',
      currentIndex: 3, // Alerts is at index 3
      child: currentUser == null
          ? const Center(
        child: Text(
          "Please sign in to view notifications",
          style: TextStyle(fontSize: 16),
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('notifications')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "No notifications yet",
                    style: AppTextStyles.subHeading,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Notifications will appear here",
                    style: AppTextStyles.regular.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          // Group notifications by date
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final yesterday = today.subtract(const Duration(days: 1));

          final todayNotifications = notifications.where((n) {
            final data = n.data() as Map<String, dynamic>;
            final timestamp = data['createdAt'] as Timestamp?;
            if (timestamp == null) return false;
            final date = timestamp.toDate();
            return date.isAfter(today);
          }).toList();

          final yesterdayNotifications = notifications.where((n) {
            final data = n.data() as Map<String, dynamic>;
            final timestamp = data['createdAt'] as Timestamp?;
            if (timestamp == null) return false;
            final date = timestamp.toDate();
            return date.isAfter(yesterday) && date.isBefore(today);
          }).toList();

          final olderNotifications = notifications.where((n) {
            final data = n.data() as Map<String, dynamic>;
            final timestamp = data['createdAt'] as Timestamp?;
            if (timestamp == null) return false;
            final date = timestamp.toDate();
            return date.isBefore(yesterday);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (todayNotifications.isNotEmpty) ...[
                _buildSectionHeader('Today'),
                ...todayNotifications.map((doc) => _buildNotificationItem(doc)).toList(),
              ],
              if (yesterdayNotifications.isNotEmpty) ...[
                _buildSectionHeader('Yesterday'),
                ...yesterdayNotifications.map((doc) => _buildNotificationItem(doc)).toList(),
              ],
              if (olderNotifications.isNotEmpty) ...[
                _buildSectionHeader('Older'),
                ...olderNotifications.map((doc) => _buildNotificationItem(doc)).toList(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF0F1620),
          fontSize: 18,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isRead = data['read'] ?? false;
    final message = data['message'] ?? '';
    final title = data['title'] ?? 'Notification';
    final timestamp = data['createdAt'] as Timestamp?;
    final time = _formatTime(timestamp);

    return _NotificationTile(
      id: doc.id,
      title: title,
      message: message,
      time: time,
      isRead: isRead,
      onTap: () {
        // Mark as read when tapped
        if (!isRead) {
          _firestore.collection('notifications').doc(doc.id).update({'read': true});
        }
      },
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final time = timestamp.toDate();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}

class _NotificationTile extends StatefulWidget {
  final String id;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.onTap,
  });

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: widget.isRead ? Colors.white : const Color(0xFFF5F9FF),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
          widget.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification icon with status indicator
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF414141),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isRead ? const Color(0xFF6C7683) : const Color(0xFF48C78E),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.notifications, color: Colors.white),
                  ),
                  const SizedBox(width: 16),

                  // Notification content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: const Color(0xFF0F1620),
                            fontSize: 16,
                            fontFamily: 'Manrope',
                            fontWeight: widget.isRead ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.time,
                          style: const TextStyle(
                            color: Color(0xFF6C7683),
                            fontSize: 12,
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.message,
                          style: TextStyle(
                            color: const Color(0xFF0F1620),
                            fontSize: 14,
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: _isExpanded ? null : 2,
                          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Expand/collapse indicator
              if (widget.message.length > 100)
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF6C7683),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}