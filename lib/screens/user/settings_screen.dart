import 'package:flutter/material.dart';
import '../../constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: AppColors.background),
            child: Stack(
              children: [
                Positioned(
                  left: 11,
                  top: 20,
                  child: Container(
                    width: 380,
                    height: 32,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 12.81,
                          top: 0,
                          child: SizedBox(
                            width: 58,
                            height: 30,
                            child: Text(
                              '9:45',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.midFont.copyWith(fontSize: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 61,
                  top: 62,
                  child: SizedBox(
                    width: 280,
                    height: 40,
                    child: Text(
                      'Settings',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading.copyWith(fontSize: 30),
                    ),
                  ),
                ),
                Positioned(
                  left: 366.52,
                  top: 249,
                  child: SizedBox(
                    width: 17.48,
                    height: 24,
                    child: Text(
                      '>',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 33,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 74.23,
                  top: 249,
                  child: SizedBox(
                    width: 303.94,
                    height: 24,
                    child: Text(
                      'Fonts',
                      style: AppTextStyles.midFont.copyWith(fontSize: 19),
                    ),
                  ),
                ),
                Positioned(
                  left: 19,
                  top: 249,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: AppColors.secondary),
                  ),
                ),
                Positioned(
                  left: 366.44,
                  top: 414,
                  child: SizedBox(
                    width: 17.56,
                    height: 24,
                    child: Text(
                      '>',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 33,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 72.92,
                  top: 414,
                  child: SizedBox(
                    width: 305.22,
                    height: 24,
                    child: Text(
                      'About us',
                      style: AppTextStyles.midFont.copyWith(fontSize: 19),
                    ),
                  ),
                ),
                Positioned(
                  left: 19,
                  top: 413,
                  child: Container(
                    width: 25,
                    height: 25,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(),
                    child: Stack(),
                  ),
                ),
                Positioned(
                  left: 366.71,
                  top: 195,
                  child: SizedBox(
                    width: 17.29,
                    height: 24,
                    child: Text(
                      '>',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 33,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 77.65,
                  top: 195,
                  child: SizedBox(
                    width: 300.58,
                    height: 24,
                    child: Text(
                      'Personal Info',
                      style: AppTextStyles.midFont.copyWith(fontSize: 19),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 804,
                  child: Container(
                    width: 402,
                    height: 70,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 15,
                          top: 41,
                          child: SizedBox(
                            width: 65,
                            height: 20,
                            child: Text(
                              'Home',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.notificationText.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 168,
                          top: 41,
                          child: SizedBox(
                            width: 70,
                            height: 20,
                            child: Text(
                              'Discover',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.notificationText.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 92,
                          top: 40.59,
                          child: SizedBox(
                            width: 65,
                            height: 20.41,
                            child: Text(
                              'Courses',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.notificationText.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 249,
                          top: 40.22,
                          child: SizedBox(
                            width: 60,
                            height: 20,
                            child: Text(
                              'Alerts',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.notificationText.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 315,
                          top: 41,
                          child: SizedBox(
                            width: 77,
                            height: 20,
                            child: Text(
                              'Settings',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.notificationText.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 366.76,
                  top: 139,
                  child: SizedBox(
                    width: 17.24,
                    height: 24,
                    child: Text(
                      '>',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 33,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 78.49,
                  top: 139,
                  child: SizedBox(
                    width: 299.75,
                    height: 24,
                    child: Text(
                      'Themes',
                      style: AppTextStyles.midFont.copyWith(fontSize: 19),
                    ),
                  ),
                ),
                Positioned(
                  left: 365.76,
                  top: 359,
                  child: SizedBox(
                    width: 17.24,
                    height: 24,
                    child: Text(
                      '>',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 33,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 77.49,
                  top: 359,
                  child: SizedBox(
                    width: 299.75,
                    height: 24,
                    child: Text(
                      'Rate us',
                      style: AppTextStyles.midFont.copyWith(fontSize: 19),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  top: 358,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(color: AppColors.secondary),
                  ),
                ),
                Positioned(
                  left: 366.76,
                  top: 303,
                  child: SizedBox(
                    width: 17.24,
                    height: 24,
                    child: Text(
                      '>',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 33,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 78.49,
                  top: 303,
                  child: SizedBox(
                    width: 299.75,
                    height: 24,
                    child: Text(
                      'Language',
                      style: AppTextStyles.midFont.copyWith(fontSize: 19),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  top: 304,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: const Color(0xFFD9D9D9)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}