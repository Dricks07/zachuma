import 'package:flutter/material.dart';
import '../../constants.dart';
import 'admin_shell.dart';

class AdminAlerts extends StatelessWidget {
  const AdminAlerts({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> alerts = [
      {
        'title': 'New User Registration',
        'message': 'Sarah Johnson just registered on the platform',
        'time': '2 hours ago',
        'type': 'user',
        'read': false,
      },
      {
        'title': 'Course Completion',
        'message': 'Michael Smith completed "Introduction to Finance"',
        'time': '5 hours ago',
        'type': 'course',
        'read': true,
      },
      {
        'title': 'System Update',
        'message': 'New app version 2.1.0 is available for deployment',
        'time': '1 day ago',
        'type': 'system',
        'read': true,
      },
      {
        'title': 'Feedback Received',
        'message': 'New feedback received from Emily Gondwe',
        'time': '2 days ago',
        'type': 'feedback',
        'read': true,
      },
    ];

    return AdminShell(
      title: "Alerts",
      currentIndex: 3,
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Added clear heading
            Text("Notifications", style: AppTextStyles.heading.copyWith(fontSize: 24)),
            const SizedBox(height: 16),
            Text(
              "Manage and review system alerts and notifications",
              style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Alert stats
            Container(
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
                  _buildStatItem('Total', '24', AppColors.primary),
                  _buildStatItem('Unread', '3', AppColors.secondary),
                  _buildStatItem('Urgent', '1', AppColors.error),
                ],
              ),
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
                  icon: Icon(Icons.filter_list, color: AppColors.primary),
                  onPressed: () {
                    // Filter alerts
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Alerts list
            Expanded(
              child: ListView.builder(
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return _buildAlertCard(alert);
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

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    IconData icon;
    Color color;

    switch (alert['type']) {
      case 'user':
        icon = Icons.person_add;
        color = AppColors.success;
        break;
      case 'course':
        icon = Icons.library_books;
        color = AppColors.primary;
        break;
      case 'system':
        icon = Icons.system_update;
        color = AppColors.warning;
        break;
      case 'feedback':
        icon = Icons.feedback;
        color = AppColors.accent;
        break;
      default:
        icon = Icons.notifications;
        color = AppColors.textSecondary;
    }

    return Container(
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
        border: alert['read'] ? null : Border.all(color: color, width: 1),
      ),
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
                  alert['title'],
                  style: AppTextStyles.regular.copyWith(
                    fontWeight: FontWeight.w600,
                    color: alert['read'] ? AppColors.textPrimary : color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert['message'],
                  style: AppTextStyles.regular.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert['time'],
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
    );
  }
}