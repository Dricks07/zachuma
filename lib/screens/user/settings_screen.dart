import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import 'user_shell.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return UserShell(
      title: 'Settings',
      currentIndex: 4,
      child: Container(
        color: AppColors.surface,
        child: ListView(
          children: [
            const SizedBox(height: 20),
            _buildSettingsItem(
              context,
              icon: Icons.color_lens,
              iconColor: AppColors.secondary,
              title: 'Themes',
              onTap: () => _showThemesDialog(context),
            ),
            _buildSettingsItem(
              context,
              icon: Icons.person,
              iconColor: AppColors.primary,
              title: 'Personal Info',
              onTap: () => _showPersonalInfoDialog(context),
            ),
            _buildSettingsItem(
              context,
              icon: Icons.font_download,
              iconColor: AppColors.secondary,
              title: 'Fonts',
              onTap: () => _showFontsDialog(context),
            ),
            _buildSettingsItem(
              context,
              icon: Icons.language,
              iconColor: AppColors.primary,
              title: 'Language',
              onTap: () => _showLanguageDialog(context),
            ),
            _buildSettingsItem(
              context,
              icon: Icons.star,
              iconColor: AppColors.secondary,
              title: 'Rate us',
              onTap: () => _showRateUsDialog(context),
            ),
            _buildSettingsItem(
              context,
              icon: Icons.info,
              iconColor: AppColors.primary,
              title: 'About us',
              onTap: () => _showAboutUsDialog(context),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 16),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),

            // Title
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F1620),
                  fontSize: 19,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Chevron
            const Text(
              '>',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0F1620),
                fontSize: 33,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Themes'),
        content: const Text('Select your preferred app theme.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement theme change
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showPersonalInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personal Info'),
        content: const Text('Update your personal information.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFontsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fonts'),
        content: const Text('Choose your preferred font style and size.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement font change
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Language'),
        content: const Text('Select your preferred language.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement language change
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showRateUsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Us'),
        content: const Text('We would appreciate your feedback!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
            },
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  void _showAboutUsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Us'),
        content: const Text('ZaChuma is an educational platform designed to help you learn and grow.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}