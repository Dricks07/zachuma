import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../constants.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  String appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ZaChuma Learning Platform',
              style: AppTextStyles.heading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Version $appVersion',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Text(
              'About ZaChuma',
              style: AppTextStyles.subHeading,
            ),
            const SizedBox(height: 16),
            Text(
              'ZaChuma is an educational platform designed to make learning accessible to everyone. '
                  'We provide high-quality educational content across various subjects and skill levels.',
              style: AppTextStyles.regular,
            ),
            const SizedBox(height: 24),
            Text(
              'Our Mission',
              style: AppTextStyles.subHeading,
            ),
            const SizedBox(height: 16),
            Text(
              'To democratize education by providing affordable, accessible, and high-quality learning '
                  'resources to students and professionals worldwide.',
              style: AppTextStyles.regular,
            ),
            const SizedBox(height: 24),
            Text(
              'Contact Us',
              style: AppTextStyles.subHeading,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: const Text('support@zachuma.com'),
              onTap: () => _launchUrl('mailto:support@zachuma.com'),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Website'),
              subtitle: const Text('www.zachuma.com'),
              onTap: () => _launchUrl('https://www.zachuma.com'),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Phone'),
              subtitle: const Text('+1 (234) 567-8900'),
              onTap: () => _launchUrl('tel:+12345678900'),
            ),
          ],
        ),
      ),
    );
  }
}