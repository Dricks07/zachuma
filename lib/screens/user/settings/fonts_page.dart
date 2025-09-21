import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/font_provider.dart';
import '../../../constants.dart';

class FontsPage extends StatefulWidget {
  const FontsPage({super.key});

  @override
  State<FontsPage> createState() => _FontsPageState();
}

class _FontsPageState extends State<FontsPage> {
  final List<String> fontSizes = ['Small', 'Medium', 'Large', 'Extra Large'];
  final List<String> fontFamilies = ['Poppins', 'Roboto', 'Open Sans', 'Manrope', 'Inter'];

  @override
  Widget build(BuildContext context) {
    final fontProvider = Provider.of<FontProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Font Settings'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Font Size',
              style: AppTextStyles.subHeading,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: fontProvider.fontSize,
              onChanged: (value) {
                if (value != null) {
                  fontProvider.setFontSize(value);
                }
              },
              items: fontSizes.map((size) {
                return DropdownMenuItem(
                  value: size,
                  child: Text(size),
                );
              }).toList(),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Font Family',
              style: AppTextStyles.subHeading,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: fontFamilies.map((font) {
                return ChoiceChip(
                  label: Text(font, style: TextStyle(fontFamily: font)),
                  selected: fontProvider.fontFamily == font,
                  onSelected: (selected) {
                    if (selected) {
                      fontProvider.setFontFamily(font);
                    }
                  },
                  selectedColor: AppColors.secondary,
                  labelStyle: TextStyle(
                    color: fontProvider.fontFamily == font ? Colors.white : AppColors.textPrimary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Preview',
              style: AppTextStyles.subHeading,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Heading Text',
                    style: AppTextStyles.heading,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subheading Text',
                    style: AppTextStyles.subHeading,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Regular Text',
                    style: AppTextStyles.regular,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is a preview of how text will appear in the app with your selected settings.',
                    style: AppTextStyles.regular,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}