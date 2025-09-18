import 'package:flutter/material.dart';
import '../../constants.dart';
import 'admin_shell.dart';

class AdminFeedback extends StatelessWidget {
  const AdminFeedback({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: "Feedback",
      currentIndex: 5,
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("User Feedback", style: AppTextStyles.heading.copyWith(fontSize: 24)),
            const SizedBox(height: 20),
            // Feedback List
            Expanded(
              child: ListView.builder(
                itemCount: 5, // Replace with actual feedback count
                itemBuilder: (context, index) {
                  return Card(
                    color: AppColors.surface,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                child: Icon(Icons.person),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("User ${index + 1}", style: AppTextStyles.midFont),
                                    Text("2 days ago", style: AppTextStyles.notificationText),
                                  ],
                                ),
                              ),
                              Chip(
                                label: Text(
                                  index % 3 == 0 ? "Bug Report" : "Suggestion",
                                  style: AppTextStyles.notificationText.copyWith(color: AppColors.surface),
                                ),
                                backgroundColor: index % 3 == 0 ? AppColors.error : AppColors.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "This is a sample feedback message. The user is providing their thoughts on the platform.",
                            style: AppTextStyles.regular,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              FilledButton(
                                onPressed: () {},
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.surface,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                child: const Text("Mark as Resolved"),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {},
                                child: const Text("View Details"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}