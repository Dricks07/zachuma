import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';

class CreatorShell extends StatefulWidget {
  final String title;
  final Widget child;
  final int currentIndex;
  final List<Widget>? actions;

  const CreatorShell({
    super.key,
    required this.title,
    required this.child,
    required this.currentIndex,
    this.actions,
  });

  @override
  State<CreatorShell> createState() => _CreatorShellState();
}

class _CreatorShellState extends State<CreatorShell> {
  User? currentUser;
  Map<String, dynamic>? profileData;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _profileSubscription;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;

      if (user == null) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/signin', (route) => false);
      } else {
        setState(() => currentUser = user);
        _loadProfileData();
      }
    });

    if (currentUser != null) {
      _loadProfileData();
    }
  }

  Future<void> _loadProfileData() async {
    if (currentUser != null) {
      try {
        // Set up real-time listener for profile data
        _profileSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .snapshots()
            .listen((snapshot) {
          if (mounted && snapshot.exists) {
            setState(() => profileData = snapshot.data());
          }
        });
      } catch (e) {
        debugPrint("Failed to load profile data: $e");
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1000;
    final showBottomNav = !isWide && widget.currentIndex >= 0 && widget.currentIndex <= 3;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 1,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          "ZaChuma",
          style: AppTextStyles.heading.copyWith(color: AppColors.secondary),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (widget.actions != null) ...widget.actions!,
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showProfilePopup(context),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: profileData?['photoUrl'] != null
                    ? ClipOval(
                  child: Image.network(
                    profileData!['photoUrl'],
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.person_outline, color: Colors.white),
                  ),
                )
                    : const Icon(Icons.person_outline, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      drawer: isWide ? null : _CreatorDrawer(currentIndex: widget.currentIndex, profileData: profileData),
      body: Row(
        children: [
          if (isWide) _CreatorDrawer(currentIndex: widget.currentIndex, profileData: profileData),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: widget.child,
            ),
          ),
        ],
      ),
      bottomNavigationBar: showBottomNav ? _buildBottomNav(context) : null,
    );
  }

  void _showProfilePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ProfileDialog(profileData: profileData),
    );
  }

  BottomNavigationBar _buildBottomNav(BuildContext context) {
    final navItems = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard', 'route': '/creator/dashboard'},
      {'icon': Icons.article_outlined, 'label': 'My Topics', 'route': '/creator/topics'},
      {'icon': Icons.add_box, 'label': 'Add', 'route': '/creator/addContent'},
      {'icon': Icons.notifications_outlined, 'label': 'Alerts', 'route': '/creator/alerts'},
    ];

    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      selectedItemColor: AppColors.secondary,
      unselectedItemColor: AppColors.textPrimary,
      type: BottomNavigationBarType.fixed,
      onTap: (idx) {
        if (idx < navItems.length && idx != widget.currentIndex) {
          Navigator.pushReplacementNamed(context, navItems[idx]['route'] as String);
        }
      },
      items: navItems.map((item) {
        return BottomNavigationBarItem(
          icon: Icon(item['icon'] as IconData),
          label: item['label'] as String,
        );
      }).toList(),
    );
  }
}

class _CreatorDrawer extends StatelessWidget {
  final int currentIndex;
  final Map<String, dynamic>? profileData;

  const _CreatorDrawer({required this.currentIndex, this.profileData});

  @override
  Widget build(BuildContext context) {
    final drawerItems = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard', 'route': '/creator/dashboard', 'index': 0},
      {'icon': Icons.article_outlined, 'label': 'My Topics', 'route': '/creator/topics', 'index': 1},
      {'icon': Icons.add_box, 'label': 'Add Topic', 'route': '/creator/addContent', 'index': 2},
      {'icon': Icons.notifications_outlined, 'label': 'Alerts', 'route': '/creator/alerts', 'index': 3},
      {'icon': Icons.feedback_outlined, 'label': 'Feedback', 'route': '/creator/feedback', 'index': 4},
      {'icon': Icons.help_outline, 'label': 'Help Center', 'route': '/creator/help', 'index': 5},
      {'icon': Icons.exit_to_app, 'label': 'Logout', 'route': '/signin', 'index': 6, 'isLogout': true},
    ];

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      width: MediaQuery.of(context).size.width * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.accent, width: 0.5)),
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: profileData?['photoUrl'] != null
                      ? ClipOval(
                    child: Image.network(
                      profileData!['photoUrl'],
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.person, size: 20, color: Colors.white),
                    ),
                  )
                      : const Icon(Icons.person, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profileData?['name'] ?? "Creator Panel",
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        profileData?['role']?.toString().toUpperCase() ?? "CONTENT CREATOR",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(indent: 16, endIndent: 16, height: 1),
          const SizedBox(height: 16),
          ...List.generate(drawerItems.length, (i) {
            final item = drawerItems[i];
            final isLogout = (item['isLogout'] ?? false) as bool;
            final icon = item['icon'] as IconData;
            final label = item['label'] as String;
            final route = item['route'] as String;
            final index = item['index'] as int;
            return _drawerItem(context, index, icon, label, route, isLogout: isLogout);
          }),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, int idx, IconData icon, String label, String route, {bool isLogout = false}) {
    final selected = currentIndex == idx;
    final bool isWide = MediaQuery.of(context).size.width >= 1000;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: selected ? AppColors.secondary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (!isWide && Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
            if (isLogout) {
              _ProfileDialog.showConfirmLogout();
            } else if (idx != currentIndex) {
              Navigator.pushReplacementNamed(context, route);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: isLogout ? AppColors.error : (selected ? AppColors.secondary : AppColors.textSecondary)),
                const SizedBox(width: 16),
                Text(label,
                    style: TextStyle(
                      color: isLogout ? AppColors.error : (selected ? AppColors.secondary : AppColors.textPrimary),
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileDialog extends StatelessWidget {
  final Map<String, dynamic>? profileData;
  const _ProfileDialog({Key? key, this.profileData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: profileData?['photoUrl'] != null
                  ? ClipOval(
                child: Image.network(
                  profileData!['photoUrl'],
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.person, size: 40, color: Colors.white),
                ),
              )
                  : const Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              profileData?['name'] ?? 'Content Creator',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? 'creator@zachuma.com',
              style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              profileData?['role']?.toString().toUpperCase() ?? 'CONTENT CREATOR',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _profileMenuItem(context, Icons.account_circle, "My Profile", () {
              Navigator.pop(context);
              Future.microtask(() => Navigator.pushNamed(context, '/creator/profile'));
            }),
            _profileMenuItem(context, Icons.settings, "Account Settings", () {
              Navigator.pop(context);
              Future.microtask(() => Navigator.pushNamed(context, '/creator/settings'));
            }),
            _profileMenuItem(context, Icons.help_outline, "Help & Support", () {
              Navigator.pop(context);
              Future.microtask(() => Navigator.pushNamed(context, '/creator/help'));
            }),
            const Divider(height: 1),
            _profileMenuItem(context, Icons.logout, "Logout", () => _ProfileDialog.showConfirmLogout(), isLogout: true),
          ],
        ),
      ),
    );
  }

  Widget _profileMenuItem(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? AppColors.error : AppColors.primary),
      title: Text(label, style: TextStyle(color: isLogout ? AppColors.error : AppColors.textPrimary)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 24,
    );
  }

  static void showConfirmLogout() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut();
              navigatorKey.currentState?.pushNamedAndRemoveUntil('/signin', (route) => false);
              ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                const SnackBar(
                  content: Text("Logged out successfully"),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}