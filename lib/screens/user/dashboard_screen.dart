import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:za_chuma/constants.dart';
import 'package:za_chuma/screens/user/topics_screen.dart';
import 'package:za_chuma/screens/user/user_shell.dart';
import 'package:za_chuma/services/sync_service.dart';
import 'package:za_chuma/screens/user/topicview_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SyncService _syncService = SyncService();
  final Connectivity _connectivity = Connectivity();
  List<Map<String, dynamic>> _topics = [];
  bool _loading = true;
  bool _syncing = false;
  bool _isOnline = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Variables to store today's topic and recommended topics
  Map<String, dynamic>? _todaysTopic;
  List<Map<String, dynamic>> _recommendedTopics = [];

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

  @override
  void initState() {
    super.initState();
    _loadTopics();
    _initConnectivity();
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  // Helper method to assign a consistent image to a topic based on its ID
  String _getTopicImage(String topicId) {
    final random = Random(topicId.hashCode);
    return _backgroundImages[random.nextInt(_backgroundImages.length)];
  }

  // Helper method to get a random topic based on the day
  Map<String, dynamic> _getTodaysTopic(List<Map<String, dynamic>> topics) {
    if (topics.isEmpty) return {};

    // Use the current date to seed the random generator for consistency throughout the day
    final now = DateTime.now();
    final daySeed = now.year * 10000 + now.month * 100 + now.day;
    final random = Random(daySeed);

    return topics[random.nextInt(topics.length)];
  }

  // Helper method to get recommended topics (max 4, excluding today's topic)
  List<Map<String, dynamic>> _getRecommendedTopics(
      List<Map<String, dynamic>> topics, Map<String, dynamic> todaysTopic) {
    if (topics.isEmpty) return [];

    // Filter out today's topic
    final filteredTopics = topics.where((topic) => topic != todaysTopic).toList();

    // If we have 4 or fewer topics after filtering, return them all
    if (filteredTopics.length <= 4) return filteredTopics;

    // Otherwise, select 4 random topics using a consistent seed
    final random = Random(DateTime.now().millisecondsSinceEpoch);
    final selectedIndices = <int>{};

    while (selectedIndices.length < 4) {
      selectedIndices.add(random.nextInt(filteredTopics.length));
    }

    return selectedIndices.map((index) => filteredTopics[index]).toList();
  }

  Future<void> _initConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });

      // Auto-sync when connection is restored
      if (_isOnline) {
        _manualSync();
      }
    });
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

      final todaysTopic = _getTodaysTopic(topicsWithImages);
      final recommendedTopics = _getRecommendedTopics(topicsWithImages, todaysTopic);

      setState(() {
        _topics = topicsWithImages;
        _todaysTopic = todaysTopic;
        _recommendedTopics = recommendedTopics;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _manualSync() async {
    if (_syncing) return;

    setState(() => _syncing = true);
    try {
      await _syncService.forceSync();
      await _loadTopics();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _syncing = false);
    }
  }

  Widget _buildSyncIndicator() {
    if (!_isOnline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'Offline',
              style: AppTextStyles.regular.copyWith(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (_syncing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Syncing...',
              style: AppTextStyles.regular.copyWith(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.sync),
      onPressed: _manualSync,
      tooltip: 'Sync data',
      color: AppColors.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return UserShell(
      title: 'ZaChuma',
      currentIndex: 0,
      showFAB: true,
      actions: [_buildSyncIndicator()],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _manualSync,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSectionTitle("Today's Topic"),
              const SizedBox(height: 8),
              _buildTodaysTopicCard(),
              const SizedBox(height: 18),
              _buildActionButtons(),
              const SizedBox(height: 24),
              _buildSectionTitle('Recommended'),
              const SizedBox(height: 8),
              _buildCourseGrid(context),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text(
        title,
        style: AppTextStyles.subHeading.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTodaysTopicCard() {
    final todayTopic = _todaysTopic ?? {};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Container(
          height: 220,
          width: double.infinity,
          child: Stack(
            children: [
              // Background Image - Using assigned offline image
              Positioned.fill(
                child: Image.asset(
                  todayTopic['assignedImage'] ?? _backgroundImages.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.primary.withOpacity(0.2),
                      child: Icon(Icons.book, size: 80, color: AppColors.surface),
                    );
                  },
                ),
              ),

              // Frosted Glass Title Container
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withOpacity(0.6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        todayTopic['title'] ?? 'Financial Literacy',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.subHeading.copyWith(
                          fontSize: 20,
                          color: AppColors.surface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Frosted Glass Content Container
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      height: 150,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withOpacity(0.6),
                      ),
                      alignment: Alignment.center,
                      child: SingleChildScrollView(
                        child: Text(
                          todayTopic['description'] ?? 'Learn essential financial concepts to manage your money effectively.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.regular.copyWith(
                            fontSize: 14,
                            color: AppColors.surface,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _todaysTopic != null && _todaysTopic!['id'] != null
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TopicOverview(topicId: _todaysTopic!['id']),
                  ),
                );
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 2,
              ),
              child: Text(
                'More on today\'s Topic',
                textAlign: TextAlign.center,
                style: AppTextStyles.midFont.copyWith(
                  fontSize: 14,
                  color: AppColors.surface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TopicsScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Explore More Topics',
                    style: AppTextStyles.midFont.copyWith(
                      fontSize: 14,
                      color: AppColors.surface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, color: AppColors.surface, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseGrid(BuildContext context) {
    // Ensure we never show more than 4 topics (2x2 grid)
    final displayTopics = _recommendedTopics.length > 4
        ? _recommendedTopics.sublist(0, 4)
        : _recommendedTopics;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, //ensure 2x2 grid
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: displayTopics.length,
        itemBuilder: (context, index) {
          final topic = displayTopics[index];
          return CourseCard(
            topicId: topic['id'],
            title: topic['title'] ?? 'Untitled',
            duration: topic['duration'] ?? '30m',
            rating: (topic['rating'] as num?)?.toDouble() ?? 4.0,
            imagePath: topic['assignedImage'],
          );
        },
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final String topicId;
  final String title;
  final String duration;
  final double rating;
  final String? imagePath;

  const CourseCard({
    super.key,
    required this.topicId,
    required this.title,
    required this.duration,
    required this.rating,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TopicOverview(topicId: topicId),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Background Image - Using assigned offline image
              Positioned.fill(
                child: Image.asset(
                  imagePath ?? 'assets/images/bg_image1.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.background,
                      child: Icon(Icons.book, size: 40, color: AppColors.textSecondary),
                    );
                  },
                ),
              ),

              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.textPrimary.withOpacity(0.8)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Content overlay
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.regular.copyWith(
                              fontSize: 14,
                              color: AppColors.surface,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          _buildStarRating(rating),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppColors.surface,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                duration,
                                style: AppTextStyles.notificationText.copyWith(
                                  fontSize: 12,
                                  color: AppColors.surface.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          if (index < rating.floor()) {
            return Icon(Icons.star, size: 14, color: AppColors.warning);
          } else if (index < rating.ceil() && rating % 1 != 0) {
            return Icon(Icons.star_half, size: 14, color: AppColors.warning);
          } else {
            return Icon(Icons.star_border, size: 14, color: AppColors.warning);
          }
        }),
      ),
    );
  }
}