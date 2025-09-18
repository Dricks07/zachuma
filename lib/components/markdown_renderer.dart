// lib/components/markdown_renderer.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';

class MarkdownRenderer extends StatelessWidget {
  final String data;
  final double padding;

  const MarkdownRenderer({
    super.key,
    required this.data,
    this.padding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Markdown(
      data: data,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          fontSize: 16,
          fontFamily: 'Manrope',
          height: 1.5,
          color: AppColors.textPrimary,
        ),
        h1: TextStyle(
          fontSize: 24,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        h2: TextStyle(
          fontSize: 20,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        h3: TextStyle(
          fontSize: 18,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        blockquote: TextStyle(
          fontSize: 16,
          fontStyle: FontStyle.italic,
          color: Colors.grey[700],
          backgroundColor: Colors.grey[100],
        ),
        listBullet: TextStyle(
          fontSize: 16,
          fontFamily: 'Manrope',
          color: AppColors.textPrimary,
        ),
      ),
      imageBuilder: (uri, title, alt) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              uri.toString(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Icon(Icons.error_outline, color: Colors.grey),
                );
              },
            ),
          ),
        );
      },
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrl(Uri.parse(href));
        }
      },
    );
  }
}