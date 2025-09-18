// lib/screens/reviewer/reviewer_profile.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import 'reviewer_shell.dart';

class ReviewerProfile extends StatefulWidget {
  const ReviewerProfile({super.key});

  @override
  State<ReviewerProfile> createState() => _ReviewerProfileState();
}

class _ReviewerProfileState extends State<ReviewerProfile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<QuerySnapshot>? _reviewStatsSubscription;

  int _topicsReviewed = 0;
  int _pendingReviews = 0;
  double _qualityScore = 0.0;
  String _avgTime = "0min";

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadReviewStats();
  }

  void _loadUserData() {
    final user = _auth.currentUser;
    if (user != null) {
      _userSubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (mounted && snapshot.exists) {
          setState(() {});
        }
      });
    }
  }

  void _loadReviewStats() {
    final user = _auth.currentUser;
    if (user != null) {
      // Get topics reviewed count
      _reviewStatsSubscription = _firestore
          .collection('topics')
          .where('reviewedBy', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _topicsReviewed = snapshot.docs.length;

            // Calculate quality score (simplified - you might want a more sophisticated calculation)
            final approvedTopics =
                snapshot.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == 'published';
                }).length;

            _qualityScore =
            _topicsReviewed > 0
                ? (approvedTopics / _topicsReviewed) * 100
                : 0.0;
          });
        }
      });

      // Get pending reviews count
      _firestore
          .collection('topics')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _pendingReviews = snapshot.docs.length;
          });
        }
      });

      // Calculate average review time (this would require tracking review times in your data model)
      // For now, we'll use a placeholder
      _avgTime = "9min";
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _reviewStatsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return ReviewerShell(
      title: "My Profile",
      currentIndex: -1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return StreamBuilder<DocumentSnapshot>(
            stream: user != null
                ? _firestore.collection('users').doc(user.uid).snapshots()
                : null,
            builder: (context, snapshot) {
              final userData = snapshot.data?.data() as Map<String, dynamic>?;

              return SingleChildScrollView(

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "My Profile",
                      style: AppTextStyles.heading.copyWith(
                        fontSize: isMobile ? 22 : 24,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Profile Card - 80% width
                    Container(
                      width: constraints.maxWidth * 0.98,
                      child: Card(
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(25),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: isMobile ? 40 : 50,
                                backgroundColor: AppColors.primary,
                                child: userData?['photoUrl'] != null
                                    ? ClipOval(
                                  child: Image.network(
                                    userData!['photoUrl'],
                                    width: isMobile ? 80 : 100,
                                    height: isMobile ? 80 : 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(
                                          Icons.person,
                                          size: isMobile ? 40 : 50,
                                          color: Colors.white,
                                        ),
                                  ),
                                )
                                    : Icon(
                                  Icons.person,
                                  size: isMobile ? 40 : 50,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                userData?['name'] ?? "Content Reviewer",
                                style: AppTextStyles.subHeading,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? "reviewer@zachuma.com",
                                style: AppTextStyles.regular.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (userData?['role'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  userData!['role'].toString().toUpperCase(),
                                  style: AppTextStyles.regular.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (userData?['joinedAt'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "Joined ${_formatDate(userData!['joinedAt'])}",
                                  style: AppTextStyles.regular.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () {
                                  // Navigate to edit profile screen
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
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Additional Information - also 80% width
                    Container(
                      width: constraints.maxWidth * 0.98,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Account Information", style: AppTextStyles.subHeading),
                          const SizedBox(height: 16),
                          Card(
                            color: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  _buildInfoRow("User ID", user?.uid ?? "N/A"),
                                  const Divider(),
                                  _buildInfoRow(
                                    "Created",
                                    user?.metadata.creationTime != null
                                        ? _formatDate(user!.metadata.creationTime!)
                                        : "N/A",
                                  ),
                                  const Divider(),
                                  _buildInfoRow(
                                    "Last Sign In",
                                    user?.metadata.lastSignInTime != null
                                        ? _formatDate(user!.metadata.lastSignInTime!)
                                        : "N/A",
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.regular.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.regular,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return "Unknown date";

    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return "Invalid date";
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${dateTime.year}';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inMinutes} minutes ago';
    }
  }
}