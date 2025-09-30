// lib/screens/creator/creator_addContent.dart
import 'package:flutter/material.dart';
import 'package:za_chuma/screens/creator/creator_shell.dart';
import '../../constants.dart';
import '../../services/admin_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AddContent extends StatefulWidget {
  final String? topicId;
  final Map<String, dynamic>? existing;
  final bool isReviewMode;
  final bool isCollaborator;

  const AddContent({
    super.key,
    this.topicId,
    this.existing,
    this.isReviewMode = false,
    this.isCollaborator = false
  });

  @override
  State<AddContent> createState() => _AddContentState();
}

class _AddContentState extends State<AddContent> {
  final repo = AdminRepository();
  final _form = GlobalKey<FormState>();
  final _quizForm = GlobalKey<FormState>();

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final contentCtrl = TextEditingController();
  final levelCtrl = TextEditingController(text: 'beginner');
  final statusCtrl = TextEditingController(text: 'draft');

  // Predefined categories
  final List<String> _categories = [
    // 1. Money Basics
    'Savings',
    'Budgeting',
    'Banking',
    'Credit & Credit Scores',
    'Debt Management',

    // 2. Wealth Building
    'Investing',
    'Stocks',
    'Bonds',
    'Mutual Funds',
    'Real Estate',
    'Cryptocurrency',
    'Entrepreneurship',
    'Side Hustles',
    'Passive Income',

    // 3. Financial Planning
    'Retirement & Early Retirement',
    'Insurance',
    'Taxes & Tax Planning',
    'Education & College Planning',
    'Estate Planning',

    // 4. Advanced Finance
    'Market Analysis',
    'Portfolio Management',
    'Asset Allocation',
    'Investment Strategies',
    'Wealth Preservation',

    // 5. Financial Wellness
    'Money Mindset',
    'Frugal Living',
    'Financial Goals & Independence',
    'Cash Flow Management',
    'Net Worth Tracking',
    'Behavioral Finance',
    'Financial Security',
  ];


  String? _selectedCategory;

  // Quiz questions
  List<Map<String, dynamic>> quizQuestions = [];
  final questionCtrl = TextEditingController();
  final List<TextEditingController> optionCtrls = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int correctAnswerIndex = 0;
  bool addingQuiz = false;
  bool showPreview = false;

  bool saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      titleCtrl.text = widget.existing!['title'] ?? '';
      descCtrl.text = widget.existing!['description'] ?? '';
      _selectedCategory = widget.existing!['category'] ?? '';
      contentCtrl.text = widget.existing!['content'] ?? '';
      levelCtrl.text = widget.existing!['level'] ?? 'beginner';
      if (widget.isReviewMode) {
        statusCtrl.text = widget.existing!['status'] ?? 'draft';
      }

      // Load existing quiz questions
      if (widget.existing!.containsKey('quizQuestions')) {
        quizQuestions =
        List<Map<String, dynamic>>.from(widget.existing!['quizQuestions']);
      }
    } else {
      // Set default category for new topics
      _selectedCategory = _categories.isNotEmpty ? _categories[0] : null;
    }
  }

  void _addQuizQuestion() {
    if (_quizForm.currentState!.validate()) {
      setState(() {
        quizQuestions.add({
          'question': questionCtrl.text,
          'options': optionCtrls.map((ctrl) => ctrl.text).toList(),
          'correctIndex': correctAnswerIndex,
          'createdAt': DateTime.now(),
        });

        // Reset form
        questionCtrl.clear();
        for (var ctrl in optionCtrls) {
          ctrl.clear();
        }
        correctAnswerIndex = 0;
        addingQuiz = false;
      });
    }
  }

  void _removeQuizQuestion(int index) {
    setState(() {
      quizQuestions.removeAt(index);
    });
  }

  void _showMarkdownHelp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Markdown Help"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _MarkdownHelpItem(
                  syntax: "# Heading 1",
                  description: "Main section heading",
                ),
                _MarkdownHelpItem(
                  syntax: "## Heading 2",
                  description: "Subsection heading",
                ),
                _MarkdownHelpItem(
                  syntax: "**bold**",
                  description: "Bold text",
                ),
                _MarkdownHelpItem(
                  syntax: "*italic*",
                  description: "Italic text",
                ),
                _MarkdownHelpItem(
                  syntax: "- List item",
                  description: "Bulleted list",
                ),
                _MarkdownHelpItem(
                  syntax: "1. Numbered item",
                  description: "Numbered list",
                ),
                _MarkdownHelpItem(
                  syntax: "[Link text](https://example.com)",
                  description: "Hyperlink",
                ),
                _MarkdownHelpItem(
                  syntax: "![Image alt](image.jpg)",
                  description: "Image",
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = !widget.isReviewMode && !widget.isCollaborator;

    return CreatorShell(
      title: widget.topicId == null ? "Create New Topic" : "Update Topic",
      currentIndex: 2,
      child: Form(
        key: _form,
        child: ListView(
          children: [
            Text(widget.topicId == null ? "Create New Topic" : "Update Topic",
                style: AppTextStyles.heading.copyWith(fontSize: 24)),
            const SizedBox(height: 24),

            // Form fields
            Wrap(
              runSpacing: 16,
              spacing: 16,
              children: [
                _textField(
                    "Title", titleCtrl, (v) => v!.isEmpty ? "Required" : null,
                    width: 500, enabled: canEdit),
                _buildCategoryDropdown(width: 500, enabled: canEdit),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              runSpacing: 16,
              spacing: 16,
              children: [
                _buildDropdown("Level", levelCtrl,
                    ['beginner', 'intermediate', 'advanced'],
                    enabled: canEdit),
                if (widget.isReviewMode)
                  _buildDropdown("Status", statusCtrl,
                      ['draft', 'pending', 'published', 'rejected']),
              ],
            ),
            const SizedBox(height: 20),
            _multilineField("Short Description", descCtrl, maxLines: 4,
                validator: (v) => v!.isEmpty ? "Required" : null,
                enabled: canEdit),
            const SizedBox(height: 20),

            // Markdown Content Section
            _buildMarkdownContentSection(canEdit),

            // Quiz Section
            const SizedBox(height: 24),
            _buildQuizSection(canEdit),

            const SizedBox(height: 24),
            if (canEdit || widget.isReviewMode)
              Align(
                alignment: Alignment.center,
                child: FilledButton.icon(
                  onPressed: saving ? null : _save,
                  icon: saving ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ) : const Icon(Icons.save),
                  label: Text(saving ? "Saving..." :
                  widget.isReviewMode ? "Submit Review" : "Save Topic"),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 12),
                    backgroundColor: widget.isReviewMode
                        ? AppColors.primary
                        : AppColors.secondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown({double? width, bool enabled = true}) {
    return SizedBox(
      width: width ?? 300,
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: InputDecoration(
          labelText: "Category",
          labelStyle: AppTextStyles.regular.copyWith(
              color: AppColors.textSecondary),
          filled: true,
          fillColor: enabled ? AppColors.surface : AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
        items: _categories.map((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }).toList(),
        validator: (value) => value == null ? "Please select a category" : null,
        onChanged: enabled ? (value) {
          setState(() {
            _selectedCategory = value;
          });
        } : null,
      ),
    );
  }

  Widget _buildMarkdownContentSection(bool canEdit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Topic Content", style: AppTextStyles.subHeading),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.help_outline, size: 20),
              onPressed: _showMarkdownHelp,
              tooltip: "Markdown Help",
            ),
            const Spacer(),
            if (contentCtrl.text.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    showPreview = !showPreview;
                  });
                },
                icon: Icon(showPreview ? Icons.edit : Icons.visibility),
                label: Text(showPreview ? "Edit" : "Preview"),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (showPreview)
          _buildMarkdownPreview()
        else
          _multilineField(
            "Use Markdown formatting for rich content",
            contentCtrl,
            maxLines: 16,
            validator: (v) => v!.isEmpty ? "Required" : null,
            enabled: canEdit,
          ),
      ],
    );
  }

  Widget _buildMarkdownPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      constraints: const BoxConstraints(minHeight: 200),
      width: double.infinity,
      child: SingleChildScrollView(
        child: MarkdownBody(
          data: contentCtrl.text.isNotEmpty ? contentCtrl.text : "*No content to preview*",
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
              fontFamily: 'monospace',
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
        ),
      ),
    );
  }

  Widget _buildQuizSection(bool canEdit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Quiz Questions", style: AppTextStyles.subHeading),
            if (canEdit) ...[
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(addingQuiz ? Icons.close : Icons.add),
                onPressed: () => setState(() => addingQuiz = !addingQuiz),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        if (addingQuiz) _buildQuizForm(),

        if (quizQuestions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text("Added Questions (${quizQuestions.length})",
              style: AppTextStyles.regular.copyWith(
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...quizQuestions
              .asMap()
              .entries
              .map((entry) {
            final index = entry.key;
            final question = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(question['question']),
                subtitle: Text(
                    "Correct: ${question['options'][question['correctIndex']]}"),
                trailing: canEdit ? IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: () => _removeQuizQuestion(index),
                ) : null,
              ),
            );
          }),
        ] else
          if (!addingQuiz)
            const Text(
                "No quiz questions added yet", style: AppTextStyles.regular),
      ],
    );
  }

  Widget _buildQuizForm() {
    return Form(
      key: _quizForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _textField(
              "Question", questionCtrl, (v) => v!.isEmpty ? "Required" : null),
          const SizedBox(height: 16),
          Text("Options", style: AppTextStyles.regular.copyWith(
              fontWeight: FontWeight.bold)),
          ...optionCtrls
              .asMap()
              .entries
              .map((entry) {
            final index = entry.key;
            final ctrl = entry.value;
            return Column(
                children: [
                  Row(
                    children: [
                      Radio<int>(
                        value: index,
                        groupValue: correctAnswerIndex,
                        onChanged: (value) =>
                            setState(() => correctAnswerIndex = value!),
                      ),
                      Expanded(
                        child: _textField("Option ${index + 1}", ctrl,
                                (v) => v!.isEmpty ? "Required" : null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                ]
            );
          }),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.surface,
            ),
            onPressed: _addQuizQuestion,
            child: const Text("Add Question"),
          ),
        ],
      ),
    );
  }

  Widget _textField(String label, TextEditingController c,
      String? Function(String?)? validator,
      {double? width, bool enabled = true}) {
    final field = TextFormField(
      controller: c,
      style: AppTextStyles.regular,
      validator: validator,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.regular.copyWith(
            color: AppColors.textSecondary),
        filled: true,
        fillColor: enabled ? AppColors.surface : AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),
    );
    if (width == null) return field;
    return SizedBox(width: width, child: field);
  }

  Widget _buildDropdown(String label, TextEditingController c,
      List<String> options,
      {bool enabled = true}) {
    return SizedBox(
      width: 300,
      child: DropdownButtonFormField<String>(
        value: c.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.regular.copyWith(
              color: AppColors.textSecondary),
          filled: true,
          fillColor: enabled ? AppColors.surface : AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
        items: options.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value.toUpperCase()),
          );
        }).toList(),
        onChanged: enabled ? (value) {
          setState(() {
            c.text = value!;
          });
        } : null,
      ),
    );
  }

  Widget _multilineField(String label, TextEditingController c,
      {int maxLines = 8,
        String? Function(String?)? validator, bool enabled = true}) {
    return TextFormField(
      controller: c,
      style: AppTextStyles.regular,
      maxLines: maxLines,
      validator: validator,
      enabled: enabled,
      decoration: InputDecoration(
        alignLabelWithHint: true,
        labelText: label,
        labelStyle: AppTextStyles.regular.copyWith(
            color: AppColors.textSecondary),
        filled: true,
        fillColor: enabled ? AppColors.surface : AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a category"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => saving = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final data = {
        'title': titleCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'category': _selectedCategory!.trim(),
        'content': contentCtrl.text.trim(),
        'level': levelCtrl.text.trim(),
        'status': widget.isReviewMode ? statusCtrl.text.trim() : 'pending',
        'published': statusCtrl.text.trim() == 'published',
        'quizQuestions': quizQuestions,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Add author information if creating new topic
      if (widget.topicId == null) {
        data['authorId'] = currentUser!.uid;
        data['authorName'] =
        (currentUser.displayName ?? currentUser.email) as Object;
        data['authors'] = [currentUser.uid]; // For collaboration
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      if (widget.topicId == null) {
        final id = await repo.createTopic(data);

        // CREATE NOTIFICATION FOR REVIEWERS WHEN NEW TOPIC IS SUBMITTED
        await _createReviewerNotification(id, titleCtrl.text.trim());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Topic created successfully and sent for review"),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pushReplacementNamed(context, '/creator/topics');
        }
      } else {
        await repo.updateTopic(widget.topicId!, data);

        // CREATE NOTIFICATION FOR REVIEWERS WHEN TOPIC IS UPDATED AND PENDING
        if (data['status'] == 'pending') {
          await _createReviewerNotification(widget.topicId!, titleCtrl.text.trim());
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Topic updated successfully"),
              backgroundColor: AppColors.success,
            ),
          );
          if (widget.isReviewMode) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, '/creator/topics');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

// ADD THIS METHOD TO CREATE NOTIFICATIONS FOR REVIEWERS
  Future<void> _createReviewerNotification(String topicId, String topicTitle) async {
    try {
      // Get all users with reviewer role
      final reviewersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'reviewer')
          .get();

      final currentUser = FirebaseAuth.instance.currentUser;
      final authorName = currentUser?.displayName ?? currentUser?.email ?? 'Unknown Creator';

      // Create notification for each reviewer
      for (final reviewerDoc in reviewersSnapshot.docs) {
        final reviewerId = reviewerDoc.id;

        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': reviewerId,
          'title': 'New Topic for Review',
          'message': '$authorName submitted "$topicTitle" for review',
          'type': 'new',
          'topicId': topicId,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': currentUser?.uid,
        });
      }

      print('Created notifications for ${reviewersSnapshot.docs.length} reviewers');
    } catch (e) {
      print('Error creating reviewer notifications: $e');
    }
  }
}

class _MarkdownHelpItem extends StatelessWidget {
  final String syntax;
  final String description;

  const _MarkdownHelpItem({
    required this.syntax,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              syntax,
              style: const TextStyle(
                fontFamily: 'Monospace',
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(description),
          ),
        ],
      ),
    );
  }
}