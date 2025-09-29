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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return CreatorShell(
        title: "My Profile",
        currentIndex: -1,
        child: const Center(child: Text("Please sign in to view your profile")),
      );
    }

    return CreatorShell(
      title: "My Profile",
      currentIndex: -1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Creator Profile", style: AppTextStyles.heading.copyWith(fontSize: 24)),
            const SizedBox(height: 20),

            // User Profile Card with Stream
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(currentUser.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildProfileCard(null);
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildProfileCard(null);
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                return _buildProfileCard(userData);
              },
            ),

            const SizedBox(height: 24),

            // Content Stats with Stream
            Text("My Content Stats", style: AppTextStyles.subHeading),
            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('topics')
                  .where('authorId', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildStatsGrid(0, 0, 0, 0.0);
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildStatsGrid(0, 0, 0, 0.0);
                }

                final topics = snapshot.data!.docs;
                int totalTopics = topics.length;
                int publishedTopics = 0;
                int pendingTopics = 0;
                double totalRating = 0.0;
                int ratedTopics = 0;

                for (var topic in topics) {
                  final data = topic.data() as Map<String, dynamic>;
                  final status = data['status']?.toString() ?? '';

                  if (status == 'published') {
                    publishedTopics++;
                  } else if (status == 'pending') {
                    pendingTopics++;
                  }

                  // Calculate average rating if available
                  if (data['rating'] != null) {
                    totalRating += (data['rating'] is int
                        ? (data['rating'] as int).toDouble()
                        : data['rating'] as double);
                    ratedTopics++;
                  }
                }

                double avgRating = ratedTopics > 0 ? totalRating / ratedTopics : 0.0;

                return _buildStatsGrid(totalTopics, publishedTopics, pendingTopics, avgRating);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic>? userData) {
    return Card(
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
            Text(userData?['name'] ?? "Content Creator",
                style: AppTextStyles.subHeading),
            const SizedBox(height: 4),
            Text(userData?['email'] ?? FirebaseAuth.instance.currentUser?.email ?? "creator@zachuma.com",
                style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            if (userData?['bio'] != null) ...[
              Text(userData!['bio'],
                  style: AppTextStyles.regular,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
            ],
            FilledButton(
              onPressed: () {
                // TODO: Implement edit profile functionality
                _showEditProfileDialog(userData);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
              ),
              child: const Text("Edit Profile"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(int totalTopics, int publishedTopics, int pendingTopics, double avgRating) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard("Topics Created", totalTopics.toString(),
                  Icons.article, AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard("Published", publishedTopics.toString(),
                  Icons.check_circle, AppColors.success),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard("Pending Review", pendingTopics.toString(),
                  Icons.hourglass_empty, AppColors.warning),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard("Avg. Rating", avgRating.toStringAsFixed(1),
                  Icons.star, AppColors.accent),
            ),
          ],
        ),
      ],
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
            Text(title,
                style: AppTextStyles.regular.copyWith(fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(Map<String, dynamic>? userData) {
    final nameController = TextEditingController(text: userData?['name'] ?? '');
    final bioController = TextEditingController(text: userData?['bio'] ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Profile"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bioController,
                decoration: const InputDecoration(
                  labelText: "Bio",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () async {
                final currentUser = _auth.currentUser;
                if (currentUser != null) {
                  await _firestore.collection('users').doc(currentUser.uid).set({
                    'name': nameController.text,
                    'bio': bioController.text,
                    'email': currentUser.email,
                    'lastUpdated': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

                  Navigator.of(context).pop();

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile updated successfully")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}