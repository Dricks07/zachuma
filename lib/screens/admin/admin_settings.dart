import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/admin_repository.dart';
import 'admin_shell.dart';

class AdminSettings extends StatelessWidget {
  const AdminSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AdminRepository();
    final catCtrl = TextEditingController();

    return AdminShell(
      title: "Settings",
      currentIndex: 7, // Updated to match drawer index
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: StreamBuilder<DocumentSnapshot>(
          stream: repo.streamSettings(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return Center(
                child: Text(
                  "Error loading settings",
                  style: AppTextStyles.regular.copyWith(color: AppColors.error),
                ),
              );
            }

            final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};
            final categories = (data['categories'] as List?)?.cast<String>() ?? <String>[];
            final chatbot = (data['chatbotEnabled'] ?? true) == true;
            final offline = (data['offlineSupport'] ?? true) == true;

            return ListView(
              children: [
                Text("Application Settings", style: AppTextStyles.heading.copyWith(fontSize: 24)),
                const SizedBox(height: 20),
                Card(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Features", style: AppTextStyles.subHeading),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          value: chatbot,
                          title: Text("Chatbot Enabled", style: AppTextStyles.midFont),
                          subtitle: Text("Toggle the in-app AI assistant", style: AppTextStyles.notificationText),
                          onChanged: (v) => repo.updateSettings({'chatbotEnabled': v}),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          value: offline,
                          title: Text("Offline Support", style: AppTextStyles.midFont),
                          subtitle: Text("Allow caching of course content", style: AppTextStyles.notificationText),
                          onChanged: (v) => repo.updateSettings({'offlineSupport': v}),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Course Categories", style: AppTextStyles.subHeading),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final c in categories)
                              Chip(
                                label: Text(c),
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                deleteIconColor: AppColors.error,
                                onDeleted: () => _removeCategory(repo, c, categories),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: catCtrl,
                                decoration: InputDecoration(
                                  hintText: "Add category",
                                  filled: true,
                                  fillColor: AppColors.background,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: () {
                                final v = catCtrl.text.trim();
                                if (v.isEmpty) return;
                                final updated = {...data, 'categories': [...categories, v]};
                                repo.updateSettings(updated);
                                catCtrl.clear();
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.surface,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                              child: const Text("Add"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _removeCategory(AdminRepository repo, String c, List<String> categories) {
    final updated = [...categories]..remove(c);
    repo.updateSettings({'categories': updated});
  }
}