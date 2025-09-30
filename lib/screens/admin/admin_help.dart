import 'package:flutter/material.dart';
import '../../constants.dart';
import 'admin_shell.dart';

class AdminHelp extends StatelessWidget {
  const AdminHelp({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: "Help Center",
      currentIndex: 8,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Help & Support", style: AppTextStyles.heading.copyWith(fontSize: 24)),
            const SizedBox(height: 20),

            // Welcome Card
            Card(
              color: AppColors.primary.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: AppColors.primary, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Welcome to Help Center", style: AppTextStyles.midFont.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text("Find answers to common questions and get support", style: AppTextStyles.regular),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // FAQ Section
            Text("Frequently Asked Questions", style: AppTextStyles.subHeading),
            const SizedBox(height: 16),

            _buildFAQItem(
              "How to add a new course?",
              "To add a new course, navigate to the Courses page and click the 'New Course' button. Fill in the required details including title, description, difficulty level, and content. You can upload text, video, or audio materials. Once submitted, the course will go through review before being published.",
            ),
            const SizedBox(height: 8),

            _buildFAQItem(
              "How to manage user permissions?",
              "User permissions can be managed from the Users page. Click on any user to view their profile and select 'Make Admin' or 'Demote' to change their role. Admin users have full system access, while regular users can only access learning content. You can also reset user passwords and manage their account status.",
            ),
            const SizedBox(height: 8),

            _buildFAQItem(
              "How to generate reports?",
              "Reports can be generated from the Reports page. Select the report type (user activity, course completion, financial metrics) and specify the date range. Click 'Generate Report' to create a detailed PDF report. You can also schedule automated reports to be sent to your email.",
            ),
            const SizedBox(height: 8),

            _buildFAQItem(
              "How to handle user feedback?",
              "User feedback is managed in the Feedback section. You can view all submitted feedback, mark items as resolved, and respond to users. Use the filter options to sort by feedback type (bug reports, suggestions, etc.) and status (new, in-progress, resolved).",
            ),
            const SizedBox(height: 8),

            _buildFAQItem(
              "System maintenance procedures",
              "For system maintenance, use the Settings page to perform backups, clear cache, and update system configurations. Major updates should be scheduled during off-peak hours. Always notify users in advance of planned maintenance through the notification system.",
            ),
            const SizedBox(height: 8),

            _buildFAQItem(
              "Troubleshooting common issues",
              "Common issues include user login problems, content loading errors, and notification failures. Check the System Alerts page for any active issues. For user-specific problems, verify their account status and try resetting their password. For content issues, check if the files are properly uploaded and accessible.",
            ),
            const SizedBox(height: 24),

            // Quick Guides Section
            Text("Quick Guides", style: AppTextStyles.subHeading),
            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildGuideCard("User Management", Icons.people, "Manage users and permissions"),
                _buildGuideCard("Content Creation", Icons.article, "Create and edit courses"),
                _buildGuideCard("Analytics", Icons.analytics, "View system statistics"),
                _buildGuideCard("Notifications", Icons.notifications, "Manage alerts and messages"),
              ],
            ),
            const SizedBox(height: 24),

            // Support Contact
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.support_agent, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Text("Need more help?", style: AppTextStyles.subHeading),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Our support team is here to help you with any questions or issues you may encounter while using the ZaChuma admin panel.",
                      style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),

                    // Contact Methods
                    _buildContactMethod(
                      Icons.email,
                      "Email Support",
                      "support@zachuma.com",
                      "We typically respond within 2 hours",
                    ),
                    const SizedBox(height: 16),

                    _buildContactMethod(
                      Icons.phone,
                      "Phone Support",
                      "+265 993 283 331",
                      "Available Monday-Friday, 8AM-6PM",
                    ),
                    const SizedBox(height: 16),

                    _buildContactMethod(
                      Icons.chat,
                      "Live Chat",
                      "Available in app",
                      "Get instant help from our team",
                    ),
                    const SizedBox(height: 16),

                    _buildContactMethod(
                      Icons.description,
                      "Documentation",
                      "Online guides",
                      "Comprehensive admin documentation",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Emergency Section
            Card(
              color: AppColors.error.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.error, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Emergency Support", style: AppTextStyles.midFont.copyWith(color: AppColors.error)),
                          const SizedBox(height: 4),
                          Text(
                            "For critical system issues requiring immediate attention",
                            style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(question, style: AppTextStyles.midFont),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              answer,
              style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(String title, IconData icon, String description) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.midFont.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTextStyles.regular.copyWith(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactMethod(IconData icon, String title, String detail, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}