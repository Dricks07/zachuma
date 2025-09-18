import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_screen.dart';
import 'sign_in_screen.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();

    _navigateUser();
  }

  Future<void> _redirectUserBasedOnRole(String role, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final quizDone = prefs.getBool('quizDone') ?? false;

    switch (role) {
      case 'admin':
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
        break;
      case 'creator':
        Navigator.pushReplacementNamed(context, '/creator/dashboard');
        break;
      case 'reviewer':
        Navigator.pushReplacementNamed(context, '/reviewer/dashboard');
        break;
      default: // Regular user
          Navigator.pushReplacementNamed(context, '/user/dashboard');
    }
  }

  Future<void> _navigateUser() async {
    await Future.delayed(const Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final role = await AuthService().getUserRole(user.uid);
      await _redirectUserBasedOnRole(role!, user.uid);
    } else {
      if (isFirstTime) {
        await prefs.setBool('isFirstTime', false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignInScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get responsive sizes
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: width,
        height: height,
        color: const Color(0xFF5CAFD6),
        child: Stack(
          children: [
            // ZaChuma text with scale animation
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ZaChuma',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFFF8800),
                        fontSize: width * 0.15, // responsive font size
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 4),
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Learn. Invest. Grow',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.05, // responsive font size
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}