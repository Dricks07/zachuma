import 'package:flutter/material.dart';
import 'package:za_chuma/constants.dart';
import 'package:za_chuma/services/sync_service.dart';

class TopicOverview extends StatefulWidget {
  final String topicId;

  const TopicOverview({super.key, required this.topicId});

  @override
  State<TopicOverview> createState() => _TopicOverviewState();
}

class _TopicOverviewState extends State<TopicOverview> {
  final SyncService _syncService = SyncService();
  Map<String, dynamic>? _topicData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    print('🔍 TopicOverview initiated with topicId: "${widget.topicId}"');
    _loadTopicData();
  }

  Future<void> _loadTopicData() async {
    try {
      await _syncService.syncData();
      final topics = await _syncService.getTopics();

      print('📚 Looking for topic with ID: "${widget.topicId}"');
      print('📚 Available topics:');
      for (var t in topics) {
        print('   - ID: "${t['id']}", Title: "${t['title']}"');
      }

      Map<String, dynamic> topic = {};

      // Try to find by exact match first
      if (widget.topicId.isNotEmpty) {
        topic = topics.firstWhere(
              (t) => t['id'] == widget.topicId,
          orElse: () => {},
        );
      }

      // If no exact match and topicId is empty, take the first available topic for testing
      if (topic.isEmpty && topics.isNotEmpty) {
        print('⚠️ No exact match found, using first available topic for testing');
        topic = topics.first;
      }

      if (topic.isNotEmpty) {
        print('✅ Found topic: "${topic['title']}" (ID: ${topic['id']})');
        setState(() {
          _topicData = topic;
          _loading = false;
        });
      } else {
        print('❌ No topic found');
        setState(() => _loading = false);
      }
    } catch (e) {
      print('❌ Error loading topic data: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_topicData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Course Overview',
            style: TextStyle(
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
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Topic not found',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Manrope',
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTopicData,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and title
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Course Overview',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 48), // For balance
                ],
              ),
              const SizedBox(height: 16),

              // Course image
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(_topicData!['imageUrl']?.isNotEmpty == true
                        ? _topicData!['imageUrl']
                        : "https://placehold.co/402x240"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                _topicData!['title'] ?? 'Financial Literacy',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Duration and Level
              Row(
                children: [
                  Icon(Icons.access_time, size: 20, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(
                    _topicData!['duration'] ?? '30 min',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.signal_cellular_alt, size: 20, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(
                    _topicData!['level']?.toString().toUpperCase() ?? 'BEGINNER',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Overview section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBE0E5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _topicData!['description'] ??
                          'Dive into Financial Literacy and stop living paycheck to paycheck. Master your money in just 10 minutes a day and watch your financial stress disappear.',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Get Started button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // Use the actual topic ID from the loaded data, not widget.topicId
                    final actualTopicId = _topicData!['id'];
                    final topicTitle = _topicData!['title'];

                    print('🚀 Navigating to learning screen with:');
                    print('   topicId: "$actualTopicId"');
                    print('   topicTitle: "$topicTitle"');

                    Navigator.pushNamed(context, '/user/learning', arguments: {
                      'topicId': actualTopicId,  // Use the actual ID from loaded data
                      'topicTitle': topicTitle,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5CAFD6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Get Started',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
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
}