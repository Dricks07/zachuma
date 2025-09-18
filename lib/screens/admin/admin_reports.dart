import 'package:flutter/material.dart';
import '../../constants.dart';
import 'admin_shell.dart';

class AdminReports extends StatelessWidget {
  const AdminReports({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: "Reports",
      currentIndex: 6,
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("System Reports", style: AppTextStyles.heading.copyWith(fontSize: 24)),
            const SizedBox(height: 20),
            // Report Types
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildReportCard("User Activity", Icons.analytics, AppColors.primary),
                _buildReportCard("Course Progress", Icons.trending_up, AppColors.secondary),
                _buildReportCard("Revenue", Icons.attach_money, AppColors.success),
                _buildReportCard("System Health", Icons.health_and_safety, AppColors.warning),
              ],
            ),
            const SizedBox(height: 24),
            // Date Range Selector
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.primary),
                    SizedBox(width: 12),
                    Text("Select Date Range", style: TextStyle(fontWeight: FontWeight.w500)),
                    Spacer(),
                    Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Generate Report Button
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Text("Generate Report"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, IconData icon, Color color) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 12),
              Text(title, style: AppTextStyles.midFont),
            ],
          ),
        ),
      ),
    );
  }
}