import 'dart:async';
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
      setState(() {
        _topics = topics;
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
    final todayTopic = _topics.isNotEmpty ? _topics[0] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Container(
          height: 220,
          width: double.infinity,
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.network(
                  todayTopic?['imageUrl']?.isNotEmpty == true
                      ? todayTopic!['imageUrl']
                      : "https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400&h=220&fit=crop",
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
                top: 16,
                left: 16,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        todayTopic?['title'] ?? 'Financial Literacy',
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
                bottom: 16,
                left: 16,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      height: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withOpacity(0.6),
                      ),
                      alignment: Alignment.center,
                      child: SingleChildScrollView(
                        child: Text(
                          todayTopic?['description'] ?? 'Learn essential financial concepts to manage your money effectively.',
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _topics.isNotEmpty
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TopicOverview(topicId: _topics[0]['id']),
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
    final recommendedCourses = _topics.length > 4 ? _topics.sublist(0, 4) : _topics;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: recommendedCourses.length,
        itemBuilder: (context, index) {
          final topic = recommendedCourses[index];
          return CourseCard(
            topicId: topic['id'],
            title: topic['title'] ?? 'Untitled',
            duration: topic['duration'] ?? '30m',
            rating: (topic['rating'] as num?)?.toDouble() ?? 4.0,
            imageUrl: topic['imageUrl'],
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
  final String? imageUrl;

  const CourseCard({
    super.key,
    required this.topicId,
    required this.title,
    required this.duration,
    required this.rating,
    this.imageUrl,
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
              // Background Image
              Positioned.fill(
                child: Image.network(
                  imageUrl?.isNotEmpty == true
                      ? imageUrl!
                      : "https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=200&h=200&fit=crop",
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
                        AppColors.textPrimary.withOpacity(0.3)
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
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withOpacity(0.5),
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