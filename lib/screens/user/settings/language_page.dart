import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/language_provider.dart';
import '../../../constants.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  final List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'de', 'name': 'German'},
    {'code': 'pt', 'name': 'Portuguese'},
    {'code': 'zh', 'name': 'Chinese'},
    {'code': 'hi', 'name': 'Hindi'},
    {'code': 'ar', 'name': 'Arabic'},
  ];

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Language Settings'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final language = languages[index];
          return RadioListTile<String>(
            title: Text(language['name']!),
            value: language['code']!,
            groupValue: languageProvider.currentLanguage,
            onChanged: (value) {
              if (value != null) {
                languageProvider.setLanguage(value);
                // Update app language
                _updateAppLanguage(value);
              }
            },
          );
        },
      ),
    );
  }

  void _updateAppLanguage(String languageCode) async {
    try {
      // Load the language JSON file
      String data = await rootBundle.loadString('assets/locales/$languageCode.json');
      // Update the app's localization (you'll need to implement this based on your i18n setup)
      print('Language changed to: $languageCode');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Language changed to ${_getLanguageName(languageCode)}')),
      );
    } catch (e) {
      print('Error changing language: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error changing language')),
      );
    }
  }

  String _getLanguageName(String code) {
    return languages.firstWhere(
          (lang) => lang['code'] == code,
      orElse: () => {'name': 'Unknown'},
    )['name']!;
  }
}