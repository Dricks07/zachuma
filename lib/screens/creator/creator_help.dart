// lib/screens/creator/creator_help.dart
import 'package:flutter/material.dart';
import '../../constants.dart';
import 'creator_shell.dart';

class CreatorHelp extends StatelessWidget {
  const CreatorHelp({super.key});

  @override
  Widget build(BuildContext context) {
    return CreatorShell(
      title: "Creator Help",
      currentIndex: 5,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Content Creator Guide",
              style: AppTextStyles.heading.copyWith(
                  fontSize: 24,
                  color: AppColors.accent
              ),
            ),
            const SizedBox(height: 20),

            // FAQ Section
            _buildFAQSection(),

            const SizedBox(height: 24),

            // Support Contact
            _buildSupportSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final List<Map<String, String>> faqs = [
      {
        'question': 'How to create effective topics?',
        'answer': 'Focus on clear, concise content. Use headings to organize information, include relevant examples, and ensure your quizzes test the key concepts.',
      },
      {
        'question': 'What makes a good quiz?',
        'answer': 'Good quizzes test understanding of key concepts, have clear and unambiguous questions, and provide informative answer explanations.',
      },
      {
        'question': 'How long should topics be?',
        'answer': 'Topics should be concise enough to read in 5-10 minutes. Focus on one main concept per topic for better learning outcomes.',
      },
      {
        'question': 'How to add images to topics?',
        'answer': 'Use the image URL field when creating or editing a topic. Make sure the image is relevant to the content and properly sized for mobile viewing.',
      },
      {
        'question': 'What are the review guidelines?',
        'answer': 'Topics are reviewed for accuracy, clarity, and educational value. Ensure your content is factually correct and well-organized before submitting for review.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Frequently Asked Questions",
          style: AppTextStyles.subHeading,
        ),
        const SizedBox(height: 12),
        ...faqs.map((faq) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              title: Text(faq['question']!, style: AppTextStyles.midFont),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    faq['answer']!,
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
            Text("Need more help?", style: AppTextStyles.subHeading),
            const SizedBox(height: 12),
            Text("Contact our content support team:", style: AppTextStyles.regular),
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
                        "content-support@zachuma.com",
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