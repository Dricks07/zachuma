import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? profileData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (doc.exists) {
          setState(() {
            profileData = doc.data();
            isLoading = false;
          });
        } else {
          await _createDefaultProfile();
        }
      } catch (e) {
        print('Error loading profile: $e');
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _createDefaultProfile() async {
    if (user != null) {
      final defaultData = {
        'name': user!.displayName ?? 'User',
        'email': user!.email ?? '',
        'phone': user!.phoneNumber ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'photoUrl': user!.photoURL ?? 'https://placehold.co/150x150',
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set(defaultData);

      setState(() {
        profileData = defaultData;
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService().signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Profile',
          style: AppTextStyles.heading.copyWith(
            fontSize: 24,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: AppColors.error,
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),

            const SizedBox(height: 32),

            // Profile Options List
            _buildProfileOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Profile Avatar
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              width: 2,
              color: AppColors.textSecondary,
            ),
          ),
          child: CircleAvatar(
            radius: 70,
            backgroundImage: NetworkImage(
              profileData?['photoUrl'] ?? 'https://placehold.co/150x150',
            ),
            onBackgroundImageError: (_, __) {
              // Handle image loading error
            },
          ),
        ),

        const SizedBox(height: 24),

        // User Name
        Text(
          profileData?['name'] ?? 'User',
          style: AppTextStyles.subHeading.copyWith(
            fontSize: 24,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // User Email
        Text(
          profileData?['email'] ?? '',
          style: AppTextStyles.regular.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProfileOptions() {
    final options = [
      {
        'icon': Icons.person_outline,
        'title': 'Personal Info',
        'subtitle': 'Update your personal information',
        'onTap': () => _navigateToPersonalInfo(),
      },
      {
        'icon': Icons.emoji_events_outlined,
        'title': 'Achievements',
        'subtitle': 'View your learning achievements',
        'onTap': () => _navigateToAchievements(),
      },
      {
        'icon': Icons.settings_outlined,
        'title': 'Settings',
        'subtitle': 'App preferences and settings',
        'onTap': () => _navigateToSettings(),
      },
      {
        'icon': Icons.security_outlined,
        'title': 'Data Privacy',
        'subtitle': 'Manage your data privacy settings',
        'onTap': () => _navigateToDataPrivacy(),
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      separatorBuilder: (context, index) => Divider(
        color: AppColors.textSecondary.withOpacity(0.3),
        height: 1,
      ),
      itemBuilder: (context, index) {
        final option = options[index];
        return ListTile(
          leading: Icon(
            option['icon'] as IconData,
            color: AppColors.primary,
            size: 28,
          ),
          title: Text(
            option['title'] as String,
            style: AppTextStyles.midFont.copyWith(
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            option['subtitle'] as String,
            style: AppTextStyles.notificationText.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onTap: option['onTap'] as VoidCallback?,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        );
      },
    );
  }

  void _navigateToPersonalInfo() {
    Navigator.pushNamed(context, '/user/profile/personal-info');
  }

  void _navigateToAchievements() {
    Navigator.pushNamed(context, '/user/profile/achievements');
  }

  void _navigateToSettings() {
    Navigator.pushNamed(context, '/user/settings');
  }

  void _navigateToDataPrivacy() {
    Navigator.pushNamed(context, '/user/profile/data-privacy');
  }
}