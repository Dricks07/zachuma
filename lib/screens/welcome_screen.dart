import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:za_chuma/constants.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<Offset> _textOffsetAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _logoAnimation =
        CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack);
    _logoController.forward();

    // Text slide & fade animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _textOffsetAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _textController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _markSeenAndNavigate(BuildContext context, String route) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seenWelcome', true);
    } catch (_) {
      // ignore
    }
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            width: screenWidth,
            height: screenHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  ScaleTransition(
                    scale: _logoAnimation,
                    child: CircleAvatar(
                      radius: isTablet ? 125 : screenWidth * 0.3,
                      backgroundImage:
                      const AssetImage("assets/images/logo-blue.png"),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),

                  // Animated welcome text
                  SlideTransition(
                    position: _textOffsetAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Welcome to ZaChuma',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading.copyWith(
                            color: AppColors.primary,
                            fontSize: isTablet ? 36 : 30,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        Text(
                          'ZaChuma is your go-to financial literacy app, designed to equip you with the knowledge and skills you need to take control of your money. Whether you\'re just starting out or ready to dive into advanced financial concepts, our easy-to-follow courses will guide you every step of the way.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.regular.copyWith(
                            fontSize: isTablet ? 18 : 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.08),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton(
                        'Sign In',
                        AppColors.secondary,
                        isTablet ? 180 : (screenWidth - 60) / 2 - 10,
                        isTablet ? 56 : 48,
                            () => _markSeenAndNavigate(context, '/signin'),
                      ),
                      SizedBox(width: 20),
                      _buildButton(
                        'Sign Up',
                        AppColors.primary,
                        isTablet ? 180 : (screenWidth - 60) / 2 - 10,
                        isTablet ? 56 : 48,
                            () => _markSeenAndNavigate(context, '/signup'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
      String text, Color color, double width, double height, VoidCallback onTap) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        child: Text(
          text,
          style: AppTextStyles.regular.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}