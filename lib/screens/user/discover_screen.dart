import 'dart:math';
import 'package:flutter/material.dart';
import 'package:za_chuma/constants.dart';
import 'package:za_chuma/screens/user/user_shell.dart';
import 'package:za_chuma/services/sync_service.dart';
import 'package:za_chuma/screens/user/topicview_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final SyncService _syncService = SyncService();
  List<Map<String, dynamic>> _topics = [];
  bool _loading = true;

  // List of available background images
  final List<String> _backgroundImages = [
    'assets/images/bg_image1.png',
    'assets/images/bg_image2.png',
    'assets/images/bg_image3.png',
    'assets/images/bg_image4.png',
    'assets/images/bg_image5.png',
    'assets/images/bg_image6.png',
    'assets/images/bg_image7.png',
  ];

  // Predetermined categories with proper grouping
  final List<Map<String, dynamic>> _categories = [
    // 1. Money Basics
    {
      'title': 'Savings',
      'icon': Icons.savings,
      'color': AppColors.success,
      'group': 'Money Basics',
    },
    {
      'title': 'Budgeting',
      'icon': Icons.account_balance_wallet,
      'color': AppColors.primary,
      'group': 'Money Basics',
    },
    {
      'title': 'Banking',
      'icon': Icons.account_balance,
      'color': AppColors.accent,
      'group': 'Money Basics',
    },
    {
      'title': 'Credit & Credit Scores',
      'icon': Icons.credit_card,
      'color': AppColors.warning,
      'group': 'Money Basics',
    },
    {
      'title': 'Debt Management',
      'icon': Icons.money_off,
      'color': AppColors.error,
      'group': 'Money Basics',
    },

    // 2. Wealth Building
    {
      'title': 'Investing',
      'icon': Icons.trending_up,
      'color': AppColors.success,
      'group': 'Wealth Building',
    },
    {
      'title': 'Stocks',
      'icon': Icons.show_chart,
      'color': AppColors.primary,
      'group': 'Wealth Building',
    },
    {
      'title': 'Bonds',
      'icon': Icons.assignment,
      'color': AppColors.accent,
      'group': 'Wealth Building',
    },
    {
      'title': 'Mutual Funds',
      'icon': Icons.pie_chart,
      'color': AppColors.warning,
      'group': 'Wealth Building',
    },
    {
      'title': 'Real Estate',
      'icon': Icons.home_work,
      'color': AppColors.error,
      'group': 'Wealth Building',
    },
    {
      'title': 'Cryptocurrency',
      'icon': Icons.currency_bitcoin,
      'color': AppColors.success,
      'group': 'Wealth Building',
    },
    {
      'title': 'Entrepreneurship',
      'icon': Icons.business_center,
      'color': AppColors.primary,
      'group': 'Wealth Building',
    },
    {
      'title': 'Side Hustles',
      'icon': Icons.work,
      'color': AppColors.accent,
      'group': 'Wealth Building',
    },
    {
      'title': 'Passive Income',
      'icon': Icons.autorenew,
      'color': AppColors.warning,
      'group': 'Wealth Building',
    },

    // 3. Financial Planning
    {
      'title': 'Retirement & Early Retirement',
      'icon': Icons.self_improvement,
      'color': AppColors.error,
      'group': 'Financial Planning',
    },
    {
      'title': 'Insurance',
      'icon': Icons.security,
      'color': AppColors.success,
      'group': 'Financial Planning',
    },
    {
      'title': 'Taxes & Tax Planning',
      'icon': Icons.receipt,
      'color': AppColors.primary,
      'group': 'Financial Planning',
    },
    {
      'title': 'Education & College Planning',
      'icon': Icons.school,
      'color': AppColors.accent,
      'group': 'Financial Planning',
    },
    {
      'title': 'Estate Planning',
      'icon': Icons.assignment_turned_in,
      'color': AppColors.warning,
      'group': 'Financial Planning',
    },

    // 4. Advanced Finance
    {
      'title': 'Market Analysis',
      'icon': Icons.analytics,
      'color': AppColors.error,
      'group': 'Advanced Finance',
    },
    {
      'title': 'Portfolio Management',
      'icon': Icons.manage_accounts,
      'color': AppColors.success,
      'group': 'Advanced Finance',
    },
    {
      'title': 'Asset Allocation',
      'icon': Icons.all_inclusive,
      'color': AppColors.primary,
      'group': 'Advanced Finance',
    },
    {
      'title': 'Investment Strategies',
      'icon': Icons.timeline,
      'color': AppColors.accent,
      'group': 'Advanced Finance',
    },
    {
      'title': 'Wealth Preservation',
      'icon': Icons.lock,
      'color': AppColors.warning,
      'group': 'Advanced Finance',
    },

    // 5. Financial Wellness
    {
      'title': 'Money Mindset',
      'icon': Icons.psychology,
      'color': AppColors.error,
      'group': 'Financial Wellness',
    },
    {
      'title': 'Frugal Living',
      'icon': Icons.eco,
      'color': AppColors.success,
      'group': 'Financial Wellness',
    },
    {
      'title': 'Financial Goals & Independence',
      'icon': Icons.flag,
      'color': AppColors.primary,
      'group': 'Financial Wellness',
    },
    {
      'title': 'Cash Flow Management',
      'icon': Icons.stacked_bar_chart,
      'color': AppColors.accent,
      'group': 'Financial Wellness',
    },
    {
      'title': 'Net Worth Tracking',
      'icon': Icons.track_changes,
      'color': AppColors.warning,
      'group': 'Financial Wellness',
    },
    {
      'title': 'Behavioral Finance',
      'icon': Icons.people,
      'color': AppColors.error,
      'group': 'Financial Wellness',
    },
    {
      'title': 'Financial Security',
      'icon': Icons.lock,
      'color': AppColors.success,
      'group': 'Financial Wellness',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  // Helper method to assign a consistent image to a topic based on its ID
  String _getTopicImage(String topicId) {
    final random = Random(topicId.hashCode);
    return _backgroundImages[random.nextInt(_backgroundImages.length)];
  }

  Future<void> _loadTopics() async {
    try {
      final topics = await _syncService.getTopics();

      // Assign images to each topic
      final topicsWithImages = topics.map((topic) {
        return {
          ...topic,
          'assignedImage': _getTopicImage(topic['id']),
        };
      }).toList();

      setState(() {
        _topics = topicsWithImages;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  // Get actual topic count for each category
  int _getTopicCountForCategory(String category) {
    return _topics.where((topic) => topic['category'] == category).length;
  }

  // Get topics by category
  List<Map<String, dynamic>> _getTopicsForCategory(String category) {
    return _topics.where((topic) => topic['category'] == category).toList();
  }

  // Get popular topics (highest rated)
  List<Map<String, dynamic>> get _popularTopics {
    if (_topics.isEmpty) return [];
    final sorted = List<Map<String, dynamic>>.from(_topics)
      ..sort((a, b) => (b['rating'] ?? 0.0).compareTo(a['rating'] ?? 0.0));
    return sorted.take(4).toList();
  }

  // Get new topics (assuming we have a date field, or use random for demo)
  List<Map<String, dynamic>> get _newTopics {
    if (_topics.isEmpty) return [];
    final shuffled = List<Map<String, dynamic>>.from(_topics)..shuffle();
    return shuffled.take(3).toList();
  }


  @override
  Widget build(BuildContext context) {
    return UserShell(
      title: 'Discover',
      currentIndex: 2,
      showFAB: true,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadTopics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 24),



              _buildSectionTitle('Browse Categories'),
              const SizedBox(height: 12),
              _buildCategoriesGrid(),
              const SizedBox(height: 24),

              if (_popularTopics.isNotEmpty) ...[
                _buildSectionTitle('Popular Topics'),
                const SizedBox(height: 12),
                _buildPopularTopics(),
                const SizedBox(height: 24),
              ],

              if (_newTopics.isNotEmpty) ...[
                _buildSectionTitle('New Content'),
                const SizedBox(height: 12),
                _buildNewTopics(),
                const SizedBox(height: 24),
              ],

              _buildQuickStats(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), AppColors.accent.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue Your Financial Journey',
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discover new ways to grow your wealth and achieve financial freedom',
                  style: AppTextStyles.regular.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/user/topics');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Explore All Topics',
                    style: AppTextStyles.midFont.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.auto_awesome,
            size: 60,
            color: AppColors.primary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.subHeading.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    // Filter categories that actually have topics
    final categoriesWithTopics = _categories.where((category) {
      return _getTopicCountForCategory(category['title']) > 0;
    }).toList();

    if (categoriesWithTopics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.category, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No categories with topics yet',
                style: AppTextStyles.regular.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15, // Adjusted to prevent overflow
      ),
      itemCount: categoriesWithTopics.length,
      itemBuilder: (context, index) {
        final category = categoriesWithTopics[index];
        final topicCount = _getTopicCountForCategory(category['title']);
        return _buildCategoryCard(category, topicCount);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, int topicCount) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showCategoryTopics(context, category['title']);
        },
        child: Container(
          padding: const EdgeInsets.all(12), // Reduced padding to prevent overflow
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                category['color'].withOpacity(0.1),
                category['color'].withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10), // Reduced padding
                decoration: BoxDecoration(
                  color: category['color'].withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category['icon'],
                  color: category['color'],
                  size: 20, // Reduced icon size
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category['title'],
                style: AppTextStyles.midFont.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 14, // Reduced font size
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$topicCount topic${topicCount != 1 ? 's' : ''}',
                style: AppTextStyles.regular.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11, // Reduced font size
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryTopics(BuildContext context, String category) {
    final categoryTopics = _getTopicsForCategory(category);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: AppTextStyles.heading.copyWith(fontSize: 24),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${categoryTopics.length} topic${categoryTopics.length != 1 ? 's' : ''} available',
              style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: categoryTopics.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No topics found in this category',
                      style: AppTextStyles.regular.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: categoryTopics.length,
                itemBuilder: (context, index) {
                  final topic = categoryTopics[index];
                  return _buildTopicListTile(topic);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularTopics() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _popularTopics.length,
        itemBuilder: (context, index) {
          final topic = _popularTopics[index];
          return Container(
            width: 280,
            margin: EdgeInsets.only(
              right: index == _popularTopics.length - 1 ? 0 : 12,
            ),
            child: _buildTopicCard(topic, true),
          );
        },
      ),
    );
  }

  Widget _buildNewTopics() {
    return Column(
      children: _newTopics.map((topic) {
        return _buildTopicListTile(topic);
      }).toList(),
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> topic, bool showRating) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TopicOverview(topicId: topic['id']),
            ),
          );
        },
        child: Stack(
          children: [
            // Background Image
            Container(
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage(topic['assignedImage'] ?? _backgroundImages.first),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.textPrimary.withOpacity(0.6)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    topic['title'] ?? 'Untitled',
                    style: AppTextStyles.midFont.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        topic['duration'] ?? '30m',
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      if (showRating) ...[
                        Icon(Icons.star, size: 14, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          (topic['rating'] ?? 4.0).toStringAsFixed(1),
                          style: AppTextStyles.regular.copyWith(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicListTile(Map<String, dynamic> topic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: AssetImage(topic['assignedImage'] ?? _backgroundImages.first),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          topic['title'] ?? 'Untitled',
          style: AppTextStyles.midFont.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${topic['duration'] ?? '30m'} • ${topic['level'] ?? 'Beginner'}',
          style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TopicOverview(topicId: topic['id']),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressCard(Map<String, dynamic> topic) {
    final progress = topic['progress'] ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TopicOverview(topicId: topic['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: AssetImage(topic['assignedImage'] ?? _backgroundImages.first),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic['title'] ?? 'Untitled',
                      style: AppTextStyles.midFont.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: AppColors.textSecondary.withOpacity(0.2),
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${progress.toStringAsFixed(0)}% completed',
                      style: AppTextStyles.regular.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_circle_fill, color: AppColors.primary, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final totalTopics = _topics.length;
    final totalDuration = _topics.fold(0, (sum, topic) {
      final duration = topic['duration']?.toString() ?? '30m';
      final minutes = int.tryParse(duration.replaceAll('m', '')) ?? 30;
      return sum + minutes;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.library_books, '$totalTopics', 'Topics'),
          _buildStatItem(Icons.access_time, '${totalDuration}m', 'Content'),
          _buildStatItem(Icons.category, '${_categories.length}', 'Categories'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.midFont.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.regular.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}