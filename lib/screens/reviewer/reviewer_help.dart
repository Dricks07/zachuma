// lib/screens/reviewer/reviewer_help.dart
import 'package:flutter/material.dart';
import '../../constants.dart';
import 'reviewer_shell.dart';

class ReviewerHelp extends StatelessWidget {
  const ReviewerHelp({super.key});

  @override
  Widget build(BuildContext context) {
    return ReviewerShell(
      title: "Reviewer Guide",
      currentIndex: 3,
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Content Review Guidelines",
                  style: AppTextStyles.heading.copyWith(fontSize: 24)
              ),
              const SizedBox(height: 20),

              // FAQ Section
              _buildFAQSection(),

              const SizedBox(height: 24),

              // Support Contact
              _buildSupportSection(),

              // Add extra padding at the bottom to ensure content isn't hidden by navigation
              const SizedBox(height: 80),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final List<Map<String, dynamic>> faqs = [
      {
        'question': 'Review Checklist',
        'answer': [
          'Check for accuracy of financial information',
          'Ensure content is clear and understandable',
          'Verify that examples are relevant and correct',
          'Confirm quizzes test the right concepts',
          'Ensure appropriate difficulty level',
        ],
        'isList': true,
      },
      {
        'question': 'Quality Standards',
        'answer': 'Topics should be accurate, well-structured, and educational. Avoid approving content with factual errors, unclear explanations, or inappropriate difficulty levels.',
        'isList': false,
      },
      {
        'question': 'Review Timeline',
        'answer': 'Aim to review topics within 48 hours of submission. For urgent content, prioritize based on topic importance and creator request.',
        'isList': false,
      },
      {
        'question': 'Handling Rejections',
        'answer': 'When rejecting content, provide clear, constructive feedback explaining what needs improvement. Focus on specific issues rather than general criticism.',
        'isList': false,
      },
      {
        'question': 'Grading Quizzes',
        'answer': 'Ensure quiz questions are unambiguous and have only one correct answer. Distractors should be plausible but clearly incorrect.',
        'isList': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...faqs.map((faq) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              title: Text(faq['question'], style: AppTextStyles.midFont),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: faq['isList']
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (faq['answer'] as List<String>).map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text("• $item", style: AppTextStyles.regular),
                      );
                    }).toList(),
                  )
                      : Text(
                    faq['answer'] as String,
                    style: AppTextStyles.regular,
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Need assistance?", style: AppTextStyles.subHeading),
            const SizedBox(height: 12),
            Text("Contact our review support team:", style: AppTextStyles.regular),
            const SizedBox(height: 16),

            // Email contact
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.email, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Email Support",
                        style: AppTextStyles.midFont.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "review-support@zachuma.com",
                        style: AppTextStyles.regular,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Phone contact
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.phone, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Phone Support",
                        style: AppTextStyles.midFont.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "+265 993 283 331",
                        style: AppTextStyles.regular,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Hours
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.access_time, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Support Hours",
                        style: AppTextStyles.midFont.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Monday - Friday: 8AM - 5PM",
                        style: AppTextStyles.regular,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Saturday: 9AM - 1PM",
                        style: AppTextStyles.regular,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}