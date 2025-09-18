// lib/screens/creator/creator_topics.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/admin_repository.dart';
import 'creator_shell.dart';
import 'creator_topic_detail.dart';
import 'package:za_chuma/screens/creator/creator_addContent.dart';

class CreatorTopics extends StatefulWidget {
  const CreatorTopics({super.key});

  @override
  State<CreatorTopics> createState() => _CreatorTopicsState();
}

class _CreatorTopicsState extends State<CreatorTopics> {
  final repo = AdminRepository();
  final searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';
  String _filterStatus = 'all';

  // Available status filters
  final List<Map<String, dynamic>> statusFilters = [
    {'value': 'all', 'label': 'All', 'color': AppColors.primary},
    {'value': 'published', 'label': 'Published', 'color': AppColors.success},
    {'value': 'pending', 'label': 'Pending', 'color': AppColors.warning},
    {'value': 'draft', 'label': 'Draft', 'color': AppColors.textSecondary},
    {'value': 'rejected', 'label': 'Rejected', 'color': AppColors.error},
  ];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CreatorShell(
      title: "My Topics",
      currentIndex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and New Topic button in the same row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "My Topics",
                style: AppTextStyles.heading.copyWith(fontSize: 24),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddContent()),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.surface,
                ),
                label: const Text("New Topic"),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search field
          TextField(
            controller: searchCtrl,
            focusNode: _searchFocusNode,
            style: AppTextStyles.regular,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: "Search my topics...",
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _searchFocusNode.hasFocus
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.textSecondary,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2.0,
                ),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),

          // Status filters
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: statusFilters.map((filter) {
                final isSelected = _filterStatus == filter['value'];
                final defaultColor = AppColors.textSecondary;
                final selectedColor = filter['color'];

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      filter['label'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : defaultColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    backgroundColor: Colors.white,
                    selectedColor: selectedColor,
                    checkmarkColor: Colors.white,
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: isSelected ? selectedColor : defaultColor,
                        width: 1.5,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _filterStatus = selected ? filter['value'] : 'all';
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Topics list
          Expanded(
            child: _buildMyTopics(),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTopics() {
    return StreamBuilder<QuerySnapshot>(
      stream: repo.streamTopics(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  "Error loading topics",
                  style: AppTextStyles.subHeading,
                ),
                const SizedBox(height: 8),
                Text(
                  snap.error.toString(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.regular,
                ),
              ],
            ),
          );
        }

        // Filter by current user and search query
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final docs = snap.data!.docs.where((e) {
          final m = e.data() as Map<String, dynamic>;
          final t = (m['title'] ?? '').toString().toLowerCase();
          final status = (m['status'] ?? 'draft').toString();
          final authorId = (m['authorId'] ?? '').toString();

          return authorId == currentUserId &&
              (_query.isEmpty || t.contains(_query)) &&
              (_filterStatus == 'all' || status == _filterStatus);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off,
                    size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  "No topics found",
                  style: AppTextStyles.subHeading,
                ),
                const SizedBox(height: 8),
                Text(
                  _query.isEmpty
                      ? "Try adjusting your filters"
                      : "No results for '$_query'",
                  style:
                  AppTextStyles.regular.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int crossAxisCount;

            if (width > 1200) {
              crossAxisCount = 3;
            } else if (width > 800) {
              crossAxisCount = 2;
            } else {
              crossAxisCount = 1;
            }

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
              ),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final id = docs[i].id;
                final d = docs[i].data() as Map<String, dynamic>;
                return _TopicCard(
                  id: id,
                  title: d['title'] ?? 'Untitled',
                  description: d['description'] ?? '',
                  category: d['category'] ?? 'General',
                  status: d['status'] ?? 'draft',
                  level: d['level'] ?? 'beginner',
                  onOpen: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TopicDetail(topicId: id, topicData: d),
                    ),
                  ),
                  onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddContent(topicId: id, existing: d),
                    ),
                  ),
                  onDelete: () async {
                    final ok = await _confirm(
                      context,
                      "Delete Topic?",
                      "This action cannot be undone.",
                    );
                    if (ok) {
                      await repo.deleteTopic(id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Topic deleted")),
                        );
                      }
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<bool> _confirm(BuildContext context, String title, String message) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: AppTextStyles.midFont),
        content: Text(message, style: AppTextStyles.regular),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    return r ?? false;
  }
}

class _TopicCard extends StatelessWidget {
  final String id;
  final String title;
  final String description;
  final String category;
  final String status;
  final String level;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TopicCard({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.level,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'published':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      case 'draft':
        return Colors.grey;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(0),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row for Category, Level, and Status Chips
              Row(
                children: [
                  Chip(
                    label: Text(
                      category,
                      style: AppTextStyles.regular.copyWith(fontSize: 12),
                    ),
                    backgroundColor: AppColors.primary.withOpacity(0.4),
                    labelStyle: const TextStyle(color: AppColors.primary),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                  const SizedBox(width: 10),
                  Chip(
                    label: Text(
                      level.isNotEmpty ? level[0].toUpperCase() + level.substring(1) : '',
                      style: AppTextStyles.regular.copyWith(fontSize: 12),
                    ),
                    backgroundColor: AppColors.accent.withOpacity(0.4),
                    labelStyle: const TextStyle(color: AppColors.secondary),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                  const SizedBox(width: 10),
                  Chip(
                    label: Text(
                      status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : '',
                      style: AppTextStyles.regular.copyWith(fontSize: 12),
                    ),
                    backgroundColor: _getStatusColor(status).withOpacity(0.4),
                    labelStyle: TextStyle(color: _getStatusColor(status)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                title,
                style: AppTextStyles.heading.copyWith(fontSize: 18),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Description
              Expanded(
                child: Text(
                  description,
                  style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text("Open"),
                    onPressed: onOpen,
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Edit"),
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text("Delete"),
                    onPressed: onDelete,
                    style:
                    TextButton.styleFrom(foregroundColor: AppColors.error),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}