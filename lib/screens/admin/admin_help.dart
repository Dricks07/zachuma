import 'package:flutter/material.dart';
import '../../constants.dart';
import 'admin_shell.dart';

class AdminHelp extends StatelessWidget {
  const AdminHelp({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: "Help Center",
      currentIndex: 8, // Corresponds to the drawer index
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeHeader(),
            const SizedBox(height: 24),

            // Key Responsibilities
            Text("Key Admin Responsibilities", style: AppTextStyles.subHeading),
            const SizedBox(height: 16),
            _buildResponsibilityCard(
              "User Management",
              Icons.people_outline,
              "Oversee all registered users. You can change user roles (e.g., promote a user to a 'Creator' or 'Reviewer') and block or unblock user accounts as needed.",
              AppColors.primary,
            ),
            const SizedBox(height: 12),
            _buildResponsibilityCard(
              "Content Oversight",
              Icons.article_outlined,
              "Monitor all topics within the system. While content creation is handled by Creators, you have the ability to view topic details and delete content if necessary.",
              AppColors.secondary,
            ),
            const SizedBox(height: 12),
            _buildResponsibilityCard(
              "System Analytics & Reporting",
              Icons.analytics_outlined,
              "Monitor the health and activity of the platform through real-time analytics and generate detailed CSV reports on user activity, content status, and system logs.",
              AppColors.success,
            ),
            const SizedBox(height: 24),

            // FAQ Section
            Text("Frequently Asked Questions", style: AppTextStyles.subHeading),
            const SizedBox(height: 16),

            _buildFAQItem(
              "How do I manage user roles?",
              "Navigate to the 'Users' page from the main dashboard. Here you will see a list of all users. Each user card has a dropdown menu allowing you to change their role (e.g., 'user', 'creator', 'reviewer', 'admin'). You can also use the 'Block User' button to suspend their access.",
            ),
            _buildFAQItem(
              "How do I generate a report?",
              "Go to the 'Reports' page. First, select the type of report you need (User Activity, Content Status, or System Logs). Next, select a date range using the calendar. Finally, click 'Generate Report'. You can then view the data and download it as a CSV file.",
            ),
            _buildFAQItem(
              "How do I view platform analytics?",
              "The 'Analytics' page provides a real-time snapshot of your platform. It includes key metrics like the total number of users and topics, as well as a live feed of the most recent activities, such as new user registrations and content submissions.",
            ),
            _buildFAQItem(
              "How do I manage app settings?",
              "On the 'Settings' page, you can manage the list of available topic categories that Creators can assign to their content. You can also enable or disable core features, such as the AI Chatbot and offline content syncing for learners.",
            ),
            const SizedBox(height: 24),

            // Support Contact
            _buildSupportSection(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Card(
      color: AppColors.primary.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Admin Help Center", style: AppTextStyles.heading.copyWith(fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(
                    "Find answers and guides for managing the ZaChuma platform effectively.",
                    style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsibilityCard(String title, IconData icon, String description, Color color) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.midFont.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(question, style: AppTextStyles.midFont),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text(
              answer,
              style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.support_agent, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text("Need More Help?", style: AppTextStyles.subHeading),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "If you encounter a critical issue or have a question not covered here, please contact technical support.",
              style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            _buildSupportOption(
              Icons.email_outlined,
              "Email Support",
              "support@zachuma.com",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption(IconData icon, String title, String detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.midFont.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(detail, style: AppTextStyles.regular),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
