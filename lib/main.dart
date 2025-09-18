// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:za_chuma/constants.dart';
import 'package:za_chuma/screens/admin/admin_alerts.dart';
import 'package:za_chuma/screens/admin/admin_analytics.dart';
import 'package:za_chuma/screens/admin/admin_topics.dart';
import 'package:za_chuma/screens/admin/admin_dash.dart';
import 'package:za_chuma/screens/admin/admin_feedback.dart';
import 'package:za_chuma/screens/admin/admin_help.dart';
import 'package:za_chuma/screens/admin/admin_profile.dart';
import 'package:za_chuma/screens/admin/admin_reports.dart';
import 'package:za_chuma/screens/admin/admin_settings.dart';
import 'package:za_chuma/screens/admin/admin_users.dart';
import 'package:za_chuma/screens/sign_in_screen.dart';
import 'package:za_chuma/screens/sign_up_screen.dart';
import 'package:za_chuma/screens/splash_screen.dart';
import 'package:za_chuma/screens/welcome_screen.dart';

import 'package:za_chuma/screens/user/chatbot_screen.dart';
import 'package:za_chuma/screens/user/dashboard_screen.dart';
import 'package:za_chuma/screens/user/profile_screen.dart';
import 'package:za_chuma/screens/user/topics_screen.dart';
import 'package:za_chuma/screens/user/learning_screen.dart';

import 'package:za_chuma/screens/creator/creator_dash.dart';
import 'package:za_chuma/screens/creator/creator_alerts.dart';
import 'package:za_chuma/screens/creator/creator_help.dart';
import 'package:za_chuma/screens/creator/creator_profile.dart';
import 'package:za_chuma/screens/creator/creator_topics.dart';
import 'package:za_chuma/screens/creator/creator_addContent.dart';
import 'package:za_chuma/screens/creator/creator_feedback.dart';
import 'package:za_chuma/screens/creator/creator_topic_detail.dart';

import 'package:za_chuma/screens/reviewer/reviewer_dash.dart';
import 'package:za_chuma/screens/reviewer/reviewer_alerts.dart';
import 'package:za_chuma/screens/reviewer/reviewer_help.dart';
import 'package:za_chuma/screens/reviewer/reviewer_profile.dart';
import 'package:za_chuma/screens/reviewer/reviewer_review.dart';
import 'package:za_chuma/screens/reviewer/reviewer_topic_review.dart';
import 'package:za_chuma/services/database_helper.dart';
import 'package:za_chuma/services/sync_service.dart';

/// Add a global navigator key so we can navigate safely from async logout
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local database
  final dbHelper = DatabaseHelper();
  await dbHelper.database;

  // Sync data on app start
  final syncService = SyncService();
  await syncService.syncData();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZaChuma',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // <-- important for logout
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: const TextTheme(
          headlineLarge: AppTextStyles.heading,
          titleLarge: AppTextStyles.subHeading,
          bodyLarge: AppTextStyles.regular,
          bodyMedium: AppTextStyles.midFont,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            textStyle: AppTextStyles.midFont.copyWith(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.textSecondary, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          labelStyle: AppTextStyles.midFont.copyWith(color: AppColors.textSecondary),
        ),
      ),
      // Start app at SplashScreen always
      home: const SplashScreen(),
      // routes
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => const AuthWrapper(),
        '/welcome': (context) => const WelcomeScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/admin/dashboard': (context) => const AdminDash(),
        '/admin/topics': (context) => const AdminTopics(),
        '/admin/users': (context) => const AdminUsers(),
        '/admin/alerts': (context) => const AdminAlerts(),
        '/admin/settings': (context) => const AdminSettings(),
        '/admin/analytics': (context) => const AdminAnalytics(),
        '/admin/feedback': (context) => const AdminFeedback(),
        '/admin/reports': (context) => const AdminReports(),
        '/admin/help': (context) => const AdminHelp(),
        '/admin/profile': (context) => const AdminProfile(),

        // For Creator
        '/creator/dashboard': (context) => const CreatorDash(),
        '/creator/topics': (context) => const CreatorTopics(),
        '/creator/addContent': (context) => const AddContent(),
        '/creator/alerts': (context) => const CreatorAlerts(),
        '/creator/help': (context) => const CreatorHelp(),
        '/creator/profile': (context) => const CreatorProfile(),
        '/creator/feedback': (context) => const CreatorFeedback(),
        '/creator/topicDetail': (context) => const TopicDetail(topicId: '', topicData: {}),

        // For Reviewer
        '/reviewer/dashboard': (context) => const ReviewerDash(),
        '/reviewer/review': (context) => const ReviewerReview(),
        '/reviewer/alerts': (context) => const ReviewerAlerts(),
        '/reviewer/help': (context) => const ReviewerHelp(),
        '/reviewer/profile': (context) => const ReviewerProfile(),
        '/reviewer/topicReview': (context) => const ReviewerTopicReview(topicId: '', topicData: {}),


        //User Routes
        '/user/dashboard': (context) => const DashboardScreen(),
        '/user/profile': (context) => const ProfileScreen(),
        '/user/chatbot': (context) => const ChatbotScreen(),
        '/user/topics': (context) => const TopicsScreen(),
        '/user/learning': (context) => const LearningScreen(topicId: '', topicTitle: ''),
      },
    );
  }
}

/// AuthWrapper decides where the user goes after splash hands off
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // still waiting for auth (optional: show a small loader)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        // User is logged in
        if (snapshot.hasData) {
          return const DashboardScreen();
        }

        // User is NOT logged in
        return const SignInScreen();
      },
    );
  }
}