import 'package:flutter/material.dart';
import '../../constants.dart';
import 'admin_shell.dart';

class AdminAnalytics extends StatelessWidget {
  const AdminAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: "Analytics",
      currentIndex: 4,
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Platform Analytics", style: AppTextStyles.heading.copyWith(fontSize: 24)),
            const SizedBox(height: 20),
            // Stats Overview
            Row(
              children: [
                _buildStatCard("Total Users", "1,243", Icons.people, AppColors.primary),
                const SizedBox(width: 16),
                _buildStatCard("Active Courses", "27", Icons.menu_book, AppColors.secondary),
                const SizedBox(width: 16),
                _buildStatCard("Completion Rate", "78%", Icons.trending_up, AppColors.success),
                const SizedBox(width: 16),
                _buildStatCard("Avg. Time Spent", "2.4h", Icons.timer, AppColors.warning),
              ],
            ),
            const SizedBox(height: 24),
            // Charts Placeholder
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: SizedBox(
                  height: 300,
                  child: Center(
                    child: Text(
                      "Engagement Charts Will Appear Here",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(value, style: AppTextStyles.heading.copyWith(fontSize: 28)),
              const SizedBox(height: 4),
              Text(title, style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}