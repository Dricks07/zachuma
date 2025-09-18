import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';

class UserShell extends StatefulWidget {
  final String title;
  final Widget child;
  final int currentIndex;
  final List<Widget>? actions;
  final bool showFAB;

  const UserShell({
    super.key,
    required this.title,
    required this.child,
    required this.currentIndex,
    this.actions,
    this.showFAB = false,
  });

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  User? currentUser;
  Map<String, dynamic>? profileData;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;

    // Listen to auth changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/signin', (route) => false);
      } else {
        setState(() => currentUser = user);
        _loadProfileData();
      }
    });

    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (currentUser != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (doc.exists) {
        setState(() => profileData = doc.data());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1000;
    final showBottomNav = !isWide && widget.currentIndex >= 0 && widget.currentIndex <= 4;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 1,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          widget.title,
          style: AppTextStyles.heading.copyWith(
            fontSize: 24,
            color: AppColors.secondary,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          if (widget.actions != null) ...widget.actions!,
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showProfilePopup(context),
            child: const Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person_outline, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      drawer: isWide ? null : _UserDrawer(currentIndex: widget.currentIndex, profileData: profileData),
      body: Row(
        children: [
          if (isWide) _UserDrawer(currentIndex: widget.currentIndex, profileData: profileData),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: widget.child,
            ),
          ),
        ],
      ),
      bottomNavigationBar: showBottomNav ? _buildBottomNav(context) : null,
      floatingActionButton: widget.showFAB ? _buildFAB() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _buildFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 75, right: 5),
      child: SizedBox(
        width: 100, // Custom width
        height: 90, // Custom height
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/user/chatbot');
          },
          backgroundColor: AppColors.primary,
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.question_answer, color: AppColors.surface, size: 32),
                Text(
                  "Ask ZaChuma",
                  style: AppTextStyles.midFont.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w600,
                    fontSize: 11, // Slightly smaller to fit more text
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfilePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ProfileDialog(profileData: profileData),
    );
  }

  BottomNavigationBar _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppColors.surface,
      currentIndex: widget.currentIndex,
      selectedItemColor: AppColors.secondary,
      unselectedItemColor: AppColors.textPrimary,
      type: BottomNavigationBarType.fixed,
      onTap: (idx) {
        final routes = [
          '/user/dashboard',
          '/user/topics',
          '/user/discover',
          '/user/alerts',
          '/user/settings'
        ];
        if (idx < routes.length && idx != widget.currentIndex) {
          Navigator.pushReplacementNamed(context, routes[idx]);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: "Topics"),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: "Discover"),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Alerts"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
      ],
    );
  }
}

/* ---------------------------- User Drawer Widget --------------------------- */
class _UserDrawer extends StatelessWidget {
  final int currentIndex;
  final Map<String, dynamic>? profileData;

  const _UserDrawer({required this.currentIndex, this.profileData});

  @override
  Widget build(BuildContext context) {
    final drawerItems = [
      {'icon': Icons.home, 'label': 'Dashboard', 'route': '/user/dashboard'},
      {'icon': Icons.book, 'label': 'Topics', 'route': '/user/topics'},
      {'icon': Icons.explore, 'label': 'Discover', 'route': '/user/discover'},
      {'icon': Icons.notifications, 'label': 'Alerts', 'route': '/user/alerts'},
      {'icon': Icons.settings, 'label': 'Settings', 'route': '/user/settings'},
      {'icon': Icons.help_outline, 'label': 'Help Center', 'route': '/user/help'},
      {'icon': Icons.exit_to_app, 'label': 'Logout', 'route': '/signin', 'isLogout': true},
    ];

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      width: MediaQuery.of(context).size.width * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.accent, width: 0.5)),
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        children: [
          GestureDetector(
            onTap: () => _showProfile(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: NetworkImage("https://placehold.co/40x40"),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(
                        color: AppColors.accent,
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileData?['name'] ?? "User",
                          style: AppTextStyles.regular.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          profileData?['email'] ?? "user@zachuma.com",
                          style: AppTextStyles.notificationText,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 16),
          ...List.generate(drawerItems.length, (i) {
            final item = drawerItems[i];
            final isLogout = (item['isLogout'] ?? false) as bool;
            final icon = item['icon'] as IconData;
            final label = item['label'] as String;
            final route = item['route'] as String;
            return _drawerItem(context, i, icon, label, route, isLogout: isLogout);
          }),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, int idx, IconData icon, String label, String route, {bool isLogout = false}) {
    final selected = currentIndex == idx;
    return Material(
      color: selected ? AppColors.secondary.withOpacity(0.1) : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
          if (isLogout) {
            _ProfileDialog.showConfirmLogout();
          } else if (idx != currentIndex) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: isLogout ? AppColors.error : (selected ? AppColors.secondary : AppColors.textSecondary)),
              const SizedBox(width: 16),
              Text(label,
                  style: AppTextStyles.midFont.copyWith(
                    color: isLogout ? AppColors.error : (selected ? AppColors.secondary : AppColors.textPrimary),
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfile(BuildContext context) {
    showDialog(context: context, builder: (_) => _ProfileDialog(profileData: profileData));
  }
}

/* ---------------------- Profile Dialog ---------------------- */
class _ProfileDialog extends StatelessWidget {
  final Map<String, dynamic>? profileData;
  const _ProfileDialog({Key? key, this.profileData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: const DecorationImage(
                  image: NetworkImage("https://placehold.co/80x80"),
                  fit: BoxFit.cover,
                ),
                border: Border.all(
                  color: AppColors.accent,
                  width: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(profileData?['name'] ?? "User", style: AppTextStyles.midFont.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(profileData?['email'] ?? "user@zachuma.com", style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _profileMenuItem(context, Icons.account_circle, "My Profile", () {
              Navigator.pop(context);
              Future.microtask(() => Navigator.pushNamed(context, '/user/profile'));
            }),
            _profileMenuItem(context, Icons.settings, "Account Settings", () {
              Navigator.pop(context);
              Future.microtask(() => Navigator.pushNamed(context, '/user/settings'));
            }),
            _profileMenuItem(context, Icons.help_outline, "Help & Support", () {
              Navigator.pop(context);
              Future.microtask(() => Navigator.pushNamed(context, '/user/help'));
            }),
            const Divider(height: 1),
            _profileMenuItem(context, Icons.logout, "Logout", () => showConfirmLogout(), isLogout: true),
          ],
        ),
      ),
    );
  }

  Widget _profileMenuItem(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? AppColors.error : AppColors.primary),
      title: Text(label, style: AppTextStyles.regular.copyWith(color: isLogout ? AppColors.error : AppColors.textPrimary)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 24,
    );
  }

  static void showConfirmLogout() {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text("Logout", style: AppTextStyles.midFont),
        content: Text("Are you sure you want to logout?", style: AppTextStyles.regular),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: AppTextStyles.regular.copyWith(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut();
              navigatorKey.currentState?.pushNamedAndRemoveUntil('/signin', (route) => false);
              ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                SnackBar(
                  content: Text("Logged out successfully", style: AppTextStyles.regular.copyWith(color: AppColors.surface)),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text("Logout", style: AppTextStyles.regular.copyWith(color: AppColors.surface)),
          ),
        ],
      ),
    );
  }
}