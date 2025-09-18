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
    _loadTopicData();
  }

  Future<void> _loadTopicData() async {
    try {
      await _syncService.syncData();
      final topics = await _syncService.getTopics();
      final topic = topics.firstWhere(
            (t) => t['id'] == widget.topicId,
        orElse: () => {},
      );

      if (topic.isNotEmpty) {
        setState(() {
          _topicData = topic;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
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
        body: Center(child: Text('Topic not found')),
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

              // Duration
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
                    Navigator.pushNamed(context, '/user/learning', arguments: {
                      'topicId': widget.topicId,
                      'topicTitle': _topicData!['title'],
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