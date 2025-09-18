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
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Help & Support", style: AppTextStyles.heading.copyWith(fontSize: 24)),
            const SizedBox(height: 20),
            // FAQ Section
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                title: Text("How to add a new course?", style: AppTextStyles.midFont),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "To add a new course, navigate to the Courses page and click the 'New Course' button. Fill in the required details and save.",
                      style: AppTextStyles.regular,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                title: Text("How to manage user permissions?", style: AppTextStyles.midFont),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "User permissions can be managed from the Users page. Click on a user and select 'Make Admin' or 'Demote' to change their role.",
                      style: AppTextStyles.regular,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                title: Text("How to generate reports?", style: AppTextStyles.midFont),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Reports can be generated from the Reports page. Select the report type and date range, then click 'Generate Report'.",
                      style: AppTextStyles.regular,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Support Contact
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Need more help?", style: AppTextStyles.subHeading),
                    const SizedBox(height: 12),
                    Text("Contact our support team:", style: AppTextStyles.regular),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.email, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text("support@zachuma.com", style: AppTextStyles.regular),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.phone, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text("+1 (555) 123-4567", style: AppTextStyles.regular),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}