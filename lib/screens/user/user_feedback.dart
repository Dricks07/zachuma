import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../constants.dart';
import 'user_shell.dart';

class UserFeedback extends StatefulWidget {
  const UserFeedback({super.key});

  @override
  State<UserFeedback> createState() => _UserFeedbackState();
}

class _UserFeedbackState extends State<UserFeedback> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  String _selectedType = 'Suggestion';
  bool _isSubmitting = false;
  String? _appVersion;
  String? _deviceInfo;

  final List<String> _feedbackTypes = [
    'Suggestion',
    'Bug Report',
    'Feature Request',
    'Content Issue',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();

      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });

      // Get device information
      if (Theme.of(context).platform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        setState(() {
          _deviceInfo = '${androidInfo.model} • Android ${androidInfo.version.release}';
        });
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        setState(() {
          _deviceInfo = '${iosInfo.model} • iOS ${iosInfo.systemVersion}';
        });
      } else {
        setState(() {
          _deviceInfo = 'Unknown device';
        });
      }
    } catch (e) {
      setState(() {
        _appVersion = 'Unknown';
        _deviceInfo = 'Unknown device';
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendAdminNotification(Map<String, dynamic> feedbackData) async {
    try {
      // Get all admin users
      final adminUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      // Create notification for each admin
      for (final adminDoc in adminUsers.docs) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .add({
          'userId': adminDoc.id,
          'title': 'New Feedback Received',
          'message': '${feedbackData['userName']} submitted a ${feedbackData['type']}',
          'type': 'feedback',
          'feedbackId': feedbackData['id'],
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error sending admin notification: $e');
      // Don't show error to user - notification failure shouldn't block feedback submission
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please sign in to submit feedback",
                style: AppTextStyles.regular.copyWith(color: AppColors.surface)),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Get user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();

      // Submit feedback
      final feedbackDoc = await FirebaseFirestore.instance.collection('feedback').add({
        'userId': user.uid,
        'userName': userData?['name'] ?? user.displayName ?? 'Anonymous User',
        'userEmail': user.email,
        'type': _selectedType,
        'message': _messageController.text.trim(),
        'appVersion': _appVersion,
        'deviceInfo': _deviceInfo,
        'status': 'new',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Prepare notification data
      final feedbackData = {
        'id': feedbackDoc.id,
        'userName': userData?['name'] ?? user.displayName ?? 'Anonymous User',
        'type': _selectedType,
        'message': _messageController.text.trim(),
      };

      // Send notification to admins
      await _sendAdminNotification(feedbackData);

      // Clear form
      _messageController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Feedback submitted successfully!",
              style: AppTextStyles.regular.copyWith(color: AppColors.surface)),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error submitting feedback: ${e.toString()}",
              style: AppTextStyles.regular.copyWith(color: AppColors.surface)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return UserShell(
      title: "Submit Feedback",
      currentIndex: -1, // Not in bottom nav
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Help Us Improve",
                          style: AppTextStyles.heading.copyWith(fontSize: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Your feedback helps us make ZaChuma better for everyone.",
                          style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Feedback Type
                Card(
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Feedback Type", style: AppTextStyles.midFont),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.accent),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          items: _feedbackTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type, style: AppTextStyles.regular),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedType = value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Message
                Card(
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Your Message", style: AppTextStyles.midFont),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _messageController,
                          maxLines: 6,
                          decoration: InputDecoration(
                            hintText: _selectedType == 'Bug Report'
                                ? "Please describe the bug you encountered, steps to reproduce it, and what you expected to happen..."
                                : "Tell us your thoughts, ideas, or concerns...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.accent),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          style: AppTextStyles.regular,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your feedback message';
                            }
                            if (value.trim().length < 10) {
                              return 'Please provide more details (at least 10 characters)';
                            }
                            return null;
                          },
                          onTap: _scrollToBottom,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Device Info
                if (_appVersion != null && _deviceInfo != null)
                  Card(
                    color: AppColors.background,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'App: $_appVersion • Device: $_deviceInfo',
                              style: AppTextStyles.notificationText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // Additional Info Card
                Card(
                  color: AppColors.surface.withOpacity(0.8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_active, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Admins will be notified about your feedback',
                            style: AppTextStyles.notificationText.copyWith(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Text(
                      "Submit Feedback",
                      style: AppTextStyles.midFont.copyWith(color: AppColors.surface),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Extra padding for keyboard space
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 100 : 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}