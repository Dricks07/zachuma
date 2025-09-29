import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:za_chuma/constants.dart';
import 'package:za_chuma/screens/user/user_shell.dart';
import 'package:za_chuma/services/sync_service.dart';
import 'package:za_chuma/screens/user/topicview_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  final SyncService _syncService = SyncService();
  final Connectivity _connectivity = Connectivity();
  List<Map<String, dynamic>> _topics = [];
  bool _loading = true;
  bool _syncing = false;
  bool _isOnline = true;
  String _searchQuery = '';
  String _filterLevel = 'all';
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

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

  // Level filters
  final List<Map<String, dynamic>> _levelFilters = [
    {'value': 'all', 'label': 'All Topics', 'color': AppColors.primary},
    {'value': 'beginner', 'label': 'Beginner', 'color': AppColors.success},
    {'value': 'intermediate', 'label': 'Intermediate', 'color': AppColors.warning},
    {'value': 'advanced', 'label': 'Advanced', 'color': AppColors.error},
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

      setState(() {
        _topics = topicsWithImages;
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

  List<Map<String, dynamic>> get _filteredTopics {
    var filtered = _topics;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((topic) {
        final title = (topic['title'] ?? '').toString().toLowerCase();
        final category = (topic['category'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery.toLowerCase()) ||
            category.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply level filter
    if (_filterLevel != 'all') {
      filtered = filtered.where((topic) {
        final level = (topic['level'] ?? 'beginner').toString().toLowerCase();
        return level == _filterLevel;
      }).toList();
    }

    return filtered;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final gridCount = isSmallScreen ? 2 : 3;

    return UserShell(
      title: 'ZaChuma',
      currentIndex: 1,
      showFAB: true,
      actions: [_buildSyncIndicator()],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _manualSync,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageHeading(context, isSmallScreen),
              const SizedBox(height: 16),
              _buildSearchBar(isSmallScreen),
              const SizedBox(height: 12),
              _buildFilterChips(isSmallScreen),
              const SizedBox(height: 16),
              _buildTopicsGrid(isSmallScreen, gridCount),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isSmallScreen) {
    return SizedBox(
      height: isSmallScreen ? 40 : 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _levelFilters.map((filter) {
          final isSelected = _filterLevel == filter['value'];
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
                  fontSize: isSmallScreen ? 12 : 14,
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
                  _filterLevel = selected ? filter['value'] : 'all';
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopicsGrid(bool isSmallScreen, int gridCount) {
    if (_filteredTopics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty && _filterLevel == 'all'
                    ? 'No topics available'
                    : 'No topics found',
                style: AppTextStyles.regular.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isEmpty && _filterLevel == 'all' && _isOnline)
                TextButton(
                  onPressed: _manualSync,
                  child: const Text('Try syncing again'),
                ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredTopics.length,
      itemBuilder: (context, index) {
        final topic = _filteredTopics[index];
        return _buildTopicCard(
          topic['id'],
          topic['title'] ?? 'Untitled',
          topic['duration'] ?? '10m',
          topic['level'] ?? 'beginner',
          topic['assignedImage'],
          isSmallScreen,
          rating: (topic['rating'] as num?)?.toDouble() ?? 4.0,
        );
      },
    );
  }

  Widget _buildTopicCard(String topicId, String title, String duration, String level, String? imagePath, bool isSmallScreen, {double rating = 4.0}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TopicOverview(topicId: topicId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            width: 0.5,
            color: AppColors.textSecondary,
          ),
        ),
        child: Stack(
          children: [
            // Background Image - Using offline image
            Container(
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage(imagePath ?? _backgroundImages.first),
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
                    AppColors.textPrimary.withOpacity(0.3)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Level badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getLevelColor(level).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  level.toUpperCase(),
                  style: AppTextStyles.regular.copyWith(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
                      color: AppColors.textPrimary.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.regular.copyWith(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: AppColors.surface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        _buildStarRating(rating, isSmallScreen),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: isSmallScreen ? 14 : 16,
                              color: AppColors.surface,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              duration,
                              style: AppTextStyles.notificationText.copyWith(
                                fontSize: isSmallScreen ? 12 : 14,
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
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return AppColors.success;
      case 'intermediate':
        return AppColors.warning;
      case 'advanced':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildSearchBar(bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 50 : 60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: isSmallScreen ? 24 : 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search Topics...',
                hintStyle: AppTextStyles.midFont.copyWith(
                  fontSize: isSmallScreen ? 16 : 18,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: AppTextStyles.midFont.copyWith(
                fontSize: isSmallScreen ? 16 : 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeading(BuildContext context, bool isSmallScreen) {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Topics',
            style: AppTextStyles.heading.copyWith(
              fontSize: isSmallScreen ? 24 : 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          // Removed filter icon button since we now have filter chips
          const SizedBox(width: 48), // Maintain balance
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          if (index < rating.floor()) {
            return Icon(Icons.star, size: isSmallScreen ? 14 : 16, color: AppColors.warning);
          } else if (index < rating.ceil() && rating % 1 != 0) {
            return Icon(Icons.star_half, size: isSmallScreen ? 14 : 16, color: AppColors.warning);
          } else {
            return Icon(Icons.star_border, size: isSmallScreen ? 14 : 16, color: AppColors.warning);
          }
        }),
      ),
    );
  }
}