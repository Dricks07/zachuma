import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:za_chuma/constants.dart';
import 'package:za_chuma/services/database_helper.dart';
import 'package:za_chuma/services/sync_service.dart';

class LearningScreen extends StatefulWidget {
  final String topicId;
  final String topicTitle;

  const LearningScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
  });

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  int _currentPageIndex = 0;
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> _contentSections = [];
  bool _isLoading = true;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SyncService _syncService = SyncService();

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      // First try to sync to ensure we have the latest content (only if online)
      await _syncService.syncData();

      // Get topic from database
      final topic = await _dbHelper.getTopic(widget.topicId);

      if (topic != null && topic['content'] != null) {
        final String content = topic['content'] as String;
        print('Raw content from DB: $content'); // Debug log

        if (content.isNotEmpty) {
          // Parse the Markdown content into sections
          final List<String> sections = _parseContentIntoSections(content);

          setState(() {
            _contentSections = sections.map((section) {
              // Split section into title and content
              final lines = section.split('\n');
              String title = 'Untitled Section';
              String contentText = section;

              // If the section starts with a heading, extract it as title
              if (section.trim().startsWith('#')) {
                final firstLineEnd = section.indexOf('\n');
                if (firstLineEnd != -1) {
                  title = section.substring(0, firstLineEnd).replaceAll('#', '').trim();
                  contentText = section.substring(firstLineEnd + 1).trim();
                } else {
                  title = section.replaceAll('#', '').trim();
                  contentText = '';
                }
              }

              return {
                'title': title,
                'content': contentText,
                'image': topic['imageUrl'] ?? 'https://placehold.co/600x300',
              };
            }).toList();

            _isLoading = false;
          });

          print('Parsed ${_contentSections.length} sections'); // Debug log
          return;
        }
      }

      // If we get here, there's no content
      setState(() => _isLoading = false);

    } catch (e) {
      print('Error loading content: $e');
      setState(() => _isLoading = false);
    }
  }

  List<String> _parseContentIntoSections(String content) {
    // Split by markdown headings (##, ###, etc.)
    final lines = content.split('\n');
    final List<String> sections = [];
    String currentSection = '';

    for (final line in lines) {
      if (line.trim().startsWith('##') && currentSection.isNotEmpty) {
        // New section found, save the current one
        sections.add(currentSection.trim());
        currentSection = line + '\n';
      } else {
        currentSection += line + '\n';
      }
    }

    // Add the last section
    if (currentSection.trim().isNotEmpty) {
      sections.add(currentSection.trim());
    }

    // If no sections were found (no headings), treat entire content as one section
    if (sections.isEmpty && content.trim().isNotEmpty) {
      sections.add(content);
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5CAFD6)),
          ),
        ),
      );
    }

    if (_contentSections.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.topicTitle,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No content available for this topic',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Manrope',
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadContent,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.topicTitle,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadContent,
            tooltip: 'Reload content',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LinearProgressIndicator(
              value: (_currentPageIndex + 1) / _contentSections.length,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5CAFD6)),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Page counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Section ${_currentPageIndex + 1} of ${_contentSections.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${((_currentPageIndex + 1) / _contentSections.length * 100).round()}% Complete',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Content area
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _contentSections.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildContentSection(_contentSections[index]);
              },
            ),
          ),
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentPageIndex > 0
                      ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE9E9E9),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: _currentPageIndex < _contentSections.length - 1
                      ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                      : () {
                    _showCompletionDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5CAFD6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: Text(_currentPageIndex < _contentSections.length - 1
                      ? 'Next'
                      : 'Finish'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(Map<String, dynamic> section) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          if (section['title'] != null && section['title'] != 'Untitled Section')
            Text(
              section['title']!,
              style: const TextStyle(
                fontSize: 24,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),

          const SizedBox(height: 16),

          // Section image (if available)
          if (section['image'] != null && section['image'].isNotEmpty)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(section['image']!),
                  fit: BoxFit.cover,
                  onError: (error, stackTrace) {
                    print('Error loading image: $error');
                  },
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              ),
            ),

          // Section content as Markdown
          _buildMarkdownContent(section['content']),

          const SizedBox(height: 24),

          // Interactive element
          _buildInteractiveElement(),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(String? content) {
    if (content == null || content.isEmpty) {
      return const Text(
        'No content available for this section.',
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Manrope',
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return MarkdownBody(
      data: content,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          fontSize: 16,
          fontFamily: 'Manrope',
          height: 1.6,
          color: Colors.black87,
        ),
        h1: const TextStyle(
          fontSize: 28,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        h2: const TextStyle(
          fontSize: 24,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        h3: const TextStyle(
          fontSize: 20,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        h4: const TextStyle(
          fontSize: 18,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        strong: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        em: const TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.black87,
        ),
        blockquote: TextStyle(
          fontSize: 16,
          fontStyle: FontStyle.italic,
          color: Colors.grey[700],
        ),
        blockquoteDecoration: BoxDecoration(
          color: Colors.grey[100],
          //borderLeft: BorderSide(
           // color: const Color(0xFF5CAFD6),
           // width: 4,
          //),
          borderRadius: BorderRadius.circular(4),
        ),
        code: TextStyle(
          fontSize: 14,
          fontFamily: 'Courier',
          backgroundColor: Colors.grey[100],
          color: Colors.purple[700],
        ),
        codeblockPadding: const EdgeInsets.all(16),
        codeblockDecoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        listIndent: 24.0,
        listBullet: const TextStyle(
          fontSize: 16,
          color: Color(0xFF5CAFD6),
        ),
        tableHead: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        tableBody: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        tableBorder: TableBorder.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        tableHeadAlign: TextAlign.center,
        tableColumnWidth: const FlexColumnWidth(),
      ),
      selectable: true, // Allow text selection for better UX
    );
  }

  Widget _buildInteractiveElement() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Check:',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'What is the main concept from this section?',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _OptionButton(text: 'I understand this concept well'),
              _OptionButton(text: 'I need to review this again'),
              _OptionButton(text: 'I\'m not sure about this'),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _saveProgress();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5CAFD6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Mark as Completed'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProgress() async {
    try {
      final progress = {
        'topicId': widget.topicId,
        'completed': _currentPageIndex + 1 == _contentSections.length ? 1 : 0,
        'progress': (_currentPageIndex + 1) / _contentSections.length,
        'lastAccessed': DateTime.now().millisecondsSinceEpoch,
        'currentSection': _currentPageIndex,
      };

      await _dbHelper.updateUserProgress(progress);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Progress saved'),
          backgroundColor: Color(0xFF5CAFD6),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error saving progress: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save progress'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showCompletionDialog() {
    _saveProgress();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF5CAFD6),
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Congratulations!',
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You have completed this learning module.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Review Again'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to quiz screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5CAFD6),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Take Quiz'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String text;

  const _OptionButton({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          side: const BorderSide(color: Color(0xFF5CAFD6)),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(text),
      ),
    );
  }
}