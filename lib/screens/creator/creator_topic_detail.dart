// lib/screens/creator/creator_topic_detail.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../constants.dart';
import '../../services/admin_repository.dart';
import 'creator_shell.dart';

class TopicDetail extends StatefulWidget {
  final String topicId;
  final Map<String, dynamic> topicData;
  const TopicDetail({super.key, required this.topicId, required this.topicData});

  @override
  State<TopicDetail> createState() => _TopicDetailState();
}

class _TopicDetailState extends State<TopicDetail> {
  final repo = AdminRepository();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final data = widget.topicData;
    final imageUrl = data['imageUrl'] as String?;

    return CreatorShell(
      title: data['title']?.toString() ?? 'Topic Detail',
      currentIndex: 1,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete, color: AppColors.error),
          onPressed: () => _confirmDelete(context),
          tooltip: "Delete topic",
        ),
      ],
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and metadata
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title']?.toString() ?? 'Untitled Topic',
                      style: AppTextStyles.heading.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 8),

                    // Status, level, and category chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            (data['status']?.toString() ?? 'draft').toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(data['status'] ?? 'draft'),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: _getStatusColor(data['status'] ?? 'draft').withOpacity(0.1),
                        ),
                        Chip(
                          label: Text(
                            (data['level']?.toString() ?? 'beginner').toUpperCase(),
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                        ),
                        Chip(
                          label: Text(
                            data['category']?.toString() ?? 'General',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: AppColors.accent.withOpacity(0.1),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Description
                    Text(
                      data['description']?.toString() ?? 'No description available',
                      style: AppTextStyles.regular.copyWith(fontSize: 16),
                    ),

                    const SizedBox(height: 16),

                    // Metadata row
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "Created: ${_formatDate(data['createdAt'])}",
                          style: AppTextStyles.regular.copyWith(color: Colors.grey, fontSize: 14),
                        ),
                        const Spacer(),
                        if (data['reviewedAt'] != null) ...[
                          const Icon(Icons.verified, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            "Reviewed: ${_formatDate(data['reviewedAt'])}",
                            style: AppTextStyles.regular.copyWith(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Content section - Updated to render Markdown
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.article, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          "Content",
                          style: AppTextStyles.subHeading.copyWith(fontSize: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.grey[200],
                    ),
                    const SizedBox(height: 16),
                    // Render Markdown content instead of plain text
                    _buildMarkdownContent(data['content']),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quiz section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.quiz, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          "Quiz Questions",
                          style: AppTextStyles.subHeading.copyWith(fontSize: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.grey[200],
                    ),
                    const SizedBox(height: 16),
                    _buildQuizSection(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Delete button at the bottom
            Center(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                icon: const Icon(Icons.delete),
                label: const Text("Delete Topic"),
                onPressed: () => _confirmDelete(context),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkdownContent(String? content) {
    if (content == null || content.isEmpty) {
      return Text(
        'No content available',
        style: AppTextStyles.regular.copyWith(fontSize: 16, height: 1.5),
      );
    }

    // Use MarkdownBody for inline rendering without height constraints
    return MarkdownBody(
      data: content,
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
        ),
        blockquoteDecoration: BoxDecoration(
          color: Colors.grey[100],
          //borderLeft: BorderSide(
            //color: AppColors.primary,
           // width: 4,
         // ),
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "Unknown date";

    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return "${date.day}/${date.month}/${date.year}";
      }
      return timestamp.toString();
    } catch (e) {
      return "Invalid date";
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'published': return AppColors.success;
      case 'pending': return AppColors.warning;
      case 'rejected': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  Widget _buildQuizSection() {
    // Check if quizQuestions exist in the topic data
    if (widget.topicData.containsKey('quizQuestions') &&
        (widget.topicData['quizQuestions'] as List).isNotEmpty) {
      final quizQuestions = List<Map<String, dynamic>>.from(widget.topicData['quizQuestions'] ?? []);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: quizQuestions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          final options = question['options'] as List<dynamic>? ?? [];
          final correctIndex = question['correctIndex'] as int? ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Q${index + 1}: ${question['question']?.toString() ?? 'No question text'}",
                    style: AppTextStyles.midFont.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  if (options.isNotEmpty)
                    ...options.asMap().entries.map((optionEntry) {
                      final optionIndex = optionEntry.key;
                      final option = optionEntry.value;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              optionIndex == correctIndex
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: optionIndex == correctIndex
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option.toString(),
                                style: AppTextStyles.regular,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Correct Answer: ${options.isNotEmpty && correctIndex < options.length ? options[correctIndex] : 'Not specified'}",
                      style: AppTextStyles.regular.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    } else {
      // If no quiz questions exist in the topic data, try to fetch from subcollection
      return StreamBuilder<QuerySnapshot>(
        stream: repo.streamQuizQuestions(widget.topicId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Text("Error loading quiz: ${snap.error}", style: AppTextStyles.regular);
          }

          final questions = snap.data!.docs;

          if (questions.isEmpty) {
            return Text("No quiz questions yet.", style: AppTextStyles.regular);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: questions.map((doc) {
              final question = doc.data() as Map<String, dynamic>;
              final options = question['options'] as List<dynamic>? ?? [];
              final correctIndex = question['correctIndex'] as int? ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question['question']?.toString() ?? 'No question text',
                        style: AppTextStyles.midFont.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),

                      if (options.isNotEmpty)
                        ...options.asMap().entries.map((optionEntry) {
                          final optionIndex = optionEntry.key;
                          final option = optionEntry.value;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  optionIndex == correctIndex
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: optionIndex == correctIndex
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    option.toString(),
                                    style: AppTextStyles.regular,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Correct Answer: ${options.isNotEmpty && correctIndex < options.length ? options[correctIndex] : 'Not specified'}",
                          style: AppTextStyles.regular.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Topic"),
        content: const Text("Are you sure you want to delete this topic? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await repo.deleteTopic(widget.topicId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Topic deleted successfully"),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error deleting topic: $e"),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}