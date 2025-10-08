import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:convert';
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
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _contentSections = [];
  List<Map<String, dynamic>> _quizQuestions = [];
  bool _isLoading = true;
  bool _hasContent = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SyncService _syncService = SyncService();
  String? _actualTopicId;
  String? _actualTopicTitle;
  Map<String, dynamic>? _savedProgress;

  @override
  void initState() {
    super.initState();
    _extractRouteArguments();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _extractRouteArguments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _actualTopicId = args['topicId'] as String?;
        _actualTopicTitle = args['topicTitle'] as String?;

        if (_actualTopicId != null && _actualTopicId!.isNotEmpty) {
          _loadContent();
        } else {
          _loadContent(); // Load with widget topicId if route args are invalid
        }
      } else {
        _actualTopicId = widget.topicId;
        _actualTopicTitle = widget.topicTitle;
        _loadContent();
      }
    });
  }

  Future<void> _loadContent() async {
    try {
      setState(() {
        _isLoading = true;
        _hasContent = false;
      });

      final topicIdToUse = _actualTopicId ?? widget.topicId;

      if (topicIdToUse.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasContent = false;
        });
        return;
      }

      await _loadSavedProgress(topicIdToUse);
      await _syncService.syncData();

      Map<String, dynamic>? topic;
      topic = await _dbHelper.getTopic(topicIdToUse);

      if (topic == null) {
        final allTopics = await _syncService.getTopics();
        topic = allTopics.firstWhere(
              (t) => t['id'] == topicIdToUse,
          orElse: () => {},
        );
        if (topic.isEmpty) {
          topic = null;
        }
      }

      if (topic != null && topic['content'] != null) {
        final String content = topic['content'] as String;

        if (content.isNotEmpty) {
          final List<String> sections = _parseContentIntoSections(content);
          List<Map<String, dynamic>> quizQuestions = [];
          if (topic['quizQuestions'] != null) {
            try {
              final quizData = jsonDecode(topic['quizQuestions']);
              if (quizData is List) {
                quizQuestions = List<Map<String, dynamic>>.from(quizData);
              }
            } catch (e) {
              // Quiz parsing failed
            }
          }

          setState(() {
            _contentSections = sections.map((section) {
              String title = 'Untitled Section';
              String contentText = section;

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
                'image': topic!['imageUrl'] ?? '',
              };
            }).toList();

            _quizQuestions = quizQuestions;
            _hasContent = true;
          });

          _restoreScrollPosition();
        } else {
          setState(() {
            _hasContent = false;
          });
        }
      } else {
        setState(() {
          _hasContent = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasContent = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSavedProgress(String topicId) async {
    try {
      _savedProgress = await _dbHelper.getUserProgress(topicId);
    } catch (e) {
      _savedProgress = null;
    }
  }

  void _restoreScrollPosition() {
    if (_savedProgress != null && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final savedScrollProgress = _savedProgress!['scrollProgress'] as double? ?? 0.0;
        if (savedScrollProgress > 0) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final targetScroll = maxScroll * savedScrollProgress;
          _scrollController.animateTo(
            targetScroll,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  List<String> _parseContentIntoSections(String content) {
    final lines = content.split('\n');
    final List<String> sections = [];
    String currentSection = '';

    for (final line in lines) {
      if (line.trim().startsWith('##') && currentSection.isNotEmpty) {
        sections.add(currentSection.trim());
        currentSection = line + '\n';
      } else {
        currentSection += line + '\n';
      }
    }

    if (currentSection.trim().isNotEmpty) {
      sections.add(currentSection.trim());
    }

    if (sections.isEmpty && content.trim().isNotEmpty) {
      sections.add(content);
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading content...',
                style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasContent) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _actualTopicTitle ?? widget.topicTitle,
            style: AppTextStyles.midFont.copyWith(fontSize: 20),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'No content available for this topic',
                style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _actualTopicTitle ?? widget.topicTitle,
          style: AppTextStyles.subHeading,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_contentSections.isNotEmpty &&
                      _contentSections[0]['image'] != null &&
                      _contentSections[0]['image'].isNotEmpty)
                    Container(
                      height: 200,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(_contentSections[0]['image']!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  ..._contentSections.asMap().entries.map((entry) {
                    final index = entry.key;
                    final section = entry.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (index > 0) ...[
                          const SizedBox(height: 32),
                          Divider(
                            color: Colors.grey[300],
                            thickness: 1,
                          ),
                          const SizedBox(height: 32),
                        ],

                        if (section['title'] != null && section['title'] != 'Untitled Section')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              section['title']!,
                              style: AppTextStyles.subHeading,
                            ),
                          ),

                        _buildMarkdownContent(section['content']),
                      ],
                    );
                  }).toList(),

                  Container(
                    margin: const EdgeInsets.only(top: 48),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Topic Complete!',
                          style: AppTextStyles.subHeading,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You have finished reading this topic!',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.regular,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_quizQuestions.isNotEmpty) {
                                _showQuizDialog();
                              } else {
                                _markTopicCompleted();
                                _showCompletionDialog();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              _quizQuestions.isNotEmpty ? 'Take Quiz' : 'Mark as Complete',
                              style: AppTextStyles.regular.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.surface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(String? content) {
    if (content == null || content.isEmpty) {
      return Container();
    }

    return MarkdownBody(
      data: content,
      styleSheet: MarkdownStyleSheet(
        p: AppTextStyles.regular.copyWith(height: 1.6),
        h1: AppTextStyles.heading,
        h2: AppTextStyles.subHeading,
        h3: AppTextStyles.midFont.copyWith(fontSize: 20),
        h4: AppTextStyles.midFont,
        strong: const TextStyle(fontWeight: FontWeight.bold),
        em: const TextStyle(fontStyle: FontStyle.italic),
        blockquote: TextStyle(
          fontStyle: FontStyle.italic,
          color: AppColors.textSecondary,
        ),
        blockquoteDecoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(
            left: BorderSide(
              color: AppColors.primary,
              width: 4,
            ),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        code: TextStyle(
          backgroundColor: Colors.grey[100],
          color: AppColors.textPrimary,
        ),
        codeblockPadding: const EdgeInsets.all(16),
        codeblockDecoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        listIndent: 24.0,
        listBullet: TextStyle(color: AppColors.primary),
        tableHead: const TextStyle(fontWeight: FontWeight.bold),
        tableBody: AppTextStyles.regular,
        tableBorder: TableBorder.all(color: Colors.grey[300]!, width: 1),
        tableHeadAlign: TextAlign.center,
        tableColumnWidth: const FlexColumnWidth(),
      ),
      selectable: true,
    );
  }

  Future<void> _markTopicCompleted({double? quizScore}) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await _dbHelper.markTopicAsCompleted(
        userId: userId,
        topicId: _actualTopicId ?? widget.topicId,
        finalScore: 100.0,
        quizScore: quizScore,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Topic completed successfully!'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark topic as completed'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showQuizDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          topicId: _actualTopicId ?? widget.topicId,
          topicTitle: _actualTopicTitle ?? widget.topicTitle,
          questions: _quizQuestions,
          onQuizCompleted: (score) {
            _saveQuizScore(score);
            _showCompletionDialog();
          },
        ),
      ),
    );
  }

  Future<void> _saveQuizScore(double score) async {
    try {
      final currentProgress = await _dbHelper.getUserProgress(_actualTopicId ?? widget.topicId);
      if (currentProgress != null) {
        currentProgress['quizScore'] = score;
        await _dbHelper.updateUserProgress(currentProgress);
      }
      await _markTopicCompleted(quizScore: score);
    } catch (e) {
      // Handle error
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Congratulations!',
                  style: AppTextStyles.subHeading,
                ),
                const SizedBox(height: 8),
                Text(
                  'You have successfully completed this learning topic.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.regular,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Continue Learning',
                      style: AppTextStyles.regular.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class QuizScreen extends StatefulWidget {
  final String topicId;
  final String topicTitle;
  final List<Map<String, dynamic>> questions;
  final Function(double) onQuizCompleted;

  const QuizScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
    required this.questions,
    required this.onQuizCompleted,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  List<int?> _selectedAnswers = [];
  bool _showResults = false;
  int _correctAnswers = 0;

  @override
  void initState() {
    super.initState();
    _selectedAnswers = List.filled(widget.questions.length, null);
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answerIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _calculateResults();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _calculateResults() {
    _correctAnswers = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      final correctIndex = widget.questions[i]['correctIndex'] as int;
      if (_selectedAnswers[i] == correctIndex) {
        _correctAnswers++;
      }
    }

    setState(() {
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showResults) {
      final score = (_correctAnswers / widget.questions.length) * 100;
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text(
            'Quiz Results',
            style: AppTextStyles.midFont.copyWith(fontSize: 20),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                score >= 70 ? Icons.celebration : Icons.thumb_up,
                size: 80,
                color: score >= 70 ? AppColors.success : AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                score >= 70 ? 'Excellent Work!' : 'Good Effort!',
                style: AppTextStyles.subHeading,
              ),
              const SizedBox(height: 16),
              Text(
                'You scored $_correctAnswers out of ${widget.questions.length}',
                style: AppTextStyles.regular,
              ),
              const SizedBox(height: 8),
              Text(
                '${score.round()}%',
                style: AppTextStyles.heading.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onQuizCompleted(score);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Continue',
                    style: AppTextStyles.regular.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = widget.questions[_currentQuestionIndex];
    final options = currentQuestion['options'] as List<dynamic>;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Quiz - ${widget.topicTitle}',
          style: AppTextStyles.midFont.copyWith(fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${widget.questions.length}',
                  style: AppTextStyles.regular.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentQuestion['question'] ?? '',
                    style: AppTextStyles.midFont.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 24),
                  ...options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value.toString();
                    final isSelected = _selectedAnswers[_currentQuestionIndex] == index;

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: OutlinedButton(
                        onPressed: () => _selectAnswer(index),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
                          foregroundColor: isSelected ? AppColors.primary : AppColors.textPrimary,
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.grey[300]!,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.all(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.grey[400]!,
                                  width: 2,
                                ),
                                color: isSelected ? AppColors.primary : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: AppColors.surface, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option,
                                style: AppTextStyles.regular,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: _selectedAnswers[_currentQuestionIndex] != null
                      ? _nextQuestion
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    _currentQuestionIndex < widget.questions.length - 1
                        ? 'Next'
                        : 'Finish Quiz',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}