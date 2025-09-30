import 'package:flutter/material.dart';
import '../../constants.dart';
import 'user_shell.dart';

class UserHelp extends StatelessWidget {
  const UserHelp({super.key});

  @override
  Widget build(BuildContext context) {
    // Navigate to the settings screen. This is a placeholder for where a real navigation would happen.
    void navigateToSettings() {
      Navigator.pushNamed(context, '/user/settings');
    }

    return UserShell(
      title: "Help Center",
      currentIndex: -1, // No highlight on bottom nav
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeHeader(),
            const SizedBox(height: 24),

            // Quick Start Guide
            Text("Getting Started", style: AppTextStyles.subHeading),
            const SizedBox(height: 16),
            _buildStepCard(
              "1. Explore Topics",
              Icons.explore_outlined,
              "Use the 'Topics' and 'Discover' screens to find financial content. You can browse all topics or filter them by categories that interest you.",
            ),
            const SizedBox(height: 12),
            _buildStepCard(
              "2. Read and Learn Offline",
              Icons.chrome_reader_mode_outlined,
              "Tap on any topic to read its content. The app automatically saves topics for offline access, so you can continue learning without an internet connection.",
            ),
            const SizedBox(height: 12),
            _buildStepCard(
              "3. Ask the AI Assistant",
              Icons.question_answer_outlined,
              "Have a question? Use the 'Ask ZaChuma' floating button to chat with our AI assistant for instant explanations on financial concepts.",
            ),
            const SizedBox(height: 24),

            // Common Questions
            Text("Frequently Asked Questions", style: AppTextStyles.subHeading),
            const SizedBox(height: 16),
            _buildFAQItem(
              "How do I find topics that are right for me?",
              "Navigate to the 'Topics' screen to see all available content. You can use the search bar to look for specific keywords or filter by difficulty level (Beginner, Intermediate, Advanced) to find content that matches your knowledge.",
            ),
            _buildFAQItem(
              "Can I really use the app offline?",
              "Yes! When you open the app with an internet connection, it automatically syncs and saves all available topics to your device. You can then read them anytime, anywhere, even without data.",
            ),
            _buildFAQItem(
              "How do quizzes work?",
              "Some topics include a short quiz at the end to help you test your understanding of the key concepts. Your score is for your own reference to gauge your learning.",
            ),
            _buildFAQItem(
              "What if I'm struggling with a concept?",
              "Use our AI assistant, 'Ask ZaChuma'! It's designed to provide instant, clear explanations for financial questions. Access it via the floating button on the main screens.",
            ),
            _buildFAQItem(
              "Is my personal financial data secure?",
              "Absolutely. The ZaChuma app does not ask for or store any of your personal financial information like bank accounts or transaction data. Our focus is solely on your educational journey.",
            ),
            const SizedBox(height: 24),

            // Support Section
            _buildSupportSection(onContactSupport: navigateToSettings),
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
            Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome to ZaChuma Help", style: AppTextStyles.heading.copyWith(fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(
                    "Find answers to your questions and learn how to get the most out of your financial learning journey.",
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

  Widget _buildStepCard(String title, IconData icon, String description) {
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
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
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

  Widget _buildSupportSection({required VoidCallback onContactSupport}) {
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
              "If you can't find the answer you're looking for, please don't hesitate to reach out to our support team.",
              style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Center(
              child: FilledButton.icon(
                onPressed: onContactSupport,
                icon: const Icon(Icons.email_outlined),
                label: const Text("Contact Support"),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
