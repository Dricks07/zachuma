// lib/screens/creator/creator_profile.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import 'creator_shell.dart';

class CreatorProfile extends StatefulWidget {
  const CreatorProfile({super.key});

  @override
  State<CreatorProfile> createState() => _CreatorProfileState();
}

class _CreatorProfileState extends State<CreatorProfile> {
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() => _userData = doc.data());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CreatorShell(
      title: "My Profile",
      currentIndex: -1,
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Creator Profile", style: AppTextStyles.heading.copyWith(fontSize: 24)),
            const SizedBox(height: 20),
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(_userData?['name'] ?? "Content Creator", style: AppTextStyles.subHeading),
                    const SizedBox(height: 4),
                    Text(_userData?['email'] ?? "creator@zachuma.com",
                        style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
                      ),
                      child: const Text("Edit Profile"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Creator Stats
            Text("My Content Stats", style: AppTextStyles.subHeading),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard("Topics Created", "24", Icons.article, AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard("Published", "18", Icons.check_circle, AppColors.success),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard("Pending Review", "3", Icons.hourglass_empty, AppColors.warning),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard("Avg. Rating", "4.7", Icons.star, AppColors.accent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.heading),
            Text(title, style: AppTextStyles.regular),
          ],
        ),
      ),
    );
  }
}