import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';

class AdminShell extends StatefulWidget {
  final String title;
  final Widget child;
  final int currentIndex;
  final List<Widget>? actions;
  final int unreadNotifications;

  const AdminShell({
    super.key,
    required this.title,
    required this.child,
    required this.currentIndex,
    this.actions,
    this.unreadNotifications = 0,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  User? currentUser;
  Map<String, dynamic>? profileData;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _profileSubscription;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _unreadNotifications = widget.unreadNotifications;

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
      _setupNotificationListener();
    }
  }

  Future<void> _loadProfileData() async {
    if (currentUser != null) {
      try {
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

  void _setupNotificationListener() {
    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: currentUser?.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _unreadNotifications = snapshot.docs.length;
        });
      }
    });
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
          style: AppTextStyles.heading.copyWith(color: AppColors.secondary, fontSize: 28),
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
      drawer: isWide ? null : _AdminDrawer(
        currentIndex: widget.currentIndex,
        profileData: profileData,
        unreadNotifications: _unreadNotifications,
      ),
      body: Row(
        children: [
          if (isWide) _AdminDrawer(
            currentIndex: widget.currentIndex,
            profileData: profileData,
            unreadNotifications: _unreadNotifications,
          ),
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
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'route': '/admin/dashboard',
        'badgeCount': 0,
      },
      {
        'icon': Icons.article_outlined,
        'label': 'Topics',
        'route': '/admin/topics',
        'badgeCount': 0,
      },
      {
        'icon': Icons.people_outlined,
        'label': 'Users',
        'route': '/admin/users',
        'badgeCount': 0,
      },
      {
        'icon': Icons.notifications_outlined,
        'label': 'Alerts',
        'route': '/admin/alerts',
        'badgeCount': _unreadNotifications,
      },
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
        final badgeCount = item['badgeCount'] as int;
        return BottomNavigationBarItem(
          icon: _buildNavIcon(item['icon'] as IconData, badgeCount),
          label: item['label'] as String,
        );
      }).toList(),
    );
  }

  Widget _buildNavIcon(IconData icon, int badgeCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 24),
        if (badgeCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badgeCount > 9 ? '9+' : badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  final int currentIndex;
  final Map<String, dynamic>? profileData;
  final int unreadNotifications;

  const _AdminDrawer({
    required this.currentIndex,
    this.profileData,
    required this.unreadNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final drawerItems = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard', 'route': '/admin/dashboard', 'index': 0, 'badgeCount': 0},
      {'icon': Icons.article_outlined, 'label': 'Topics', 'route': '/admin/topics', 'index': 1, 'badgeCount': 0},
      {'icon': Icons.people_outlined, 'label': 'Users', 'route': '/admin/users', 'index': 2, 'badgeCount': 0},
      {'icon': Icons.notifications_outlined, 'label': 'Alerts', 'route': '/admin/alerts', 'index': 3, 'badgeCount': unreadNotifications},
      {'icon': Icons.analytics_outlined, 'label': 'Analytics', 'route': '/admin/analytics', 'index': 4, 'badgeCount': 0},
      {'icon': Icons.feedback_outlined, 'label': 'Feedback', 'route': '/admin/feedback', 'index': 5, 'badgeCount': 0},
      {'icon': Icons.report_outlined, 'label': 'Reports', 'route': '/admin/reports', 'index': 6, 'badgeCount': 0},
      {'icon': Icons.settings_outlined, 'label': 'Settings', 'route': '/admin/settings', 'index': 7, 'badgeCount': 0},
      {'icon': Icons.help_outline, 'label': 'Help Center', 'route': '/admin/help', 'index': 8, 'badgeCount': 0},
      {'icon': Icons.exit_to_app, 'label': 'Logout', 'route': '/signin', 'index': 9, 'isLogout': true, 'badgeCount': 0},
    ];

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      width: 280,
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
                        profileData?['name'] ?? "Admin Panel",
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        profileData?['role']?.toString().toUpperCase() ?? "ADMINISTRATOR",
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
            final badgeCount = item['badgeCount'] as int;
            return _drawerItem(
              context,
              index,
              icon,
              label,
              route,
              badgeCount,
              isLogout: isLogout,
            );
          }),
        ],
      ),
    );
  }

  Widget _drawerItem(
      BuildContext context,
      int idx,
      IconData icon,
      String label,
      String route,
      int badgeCount, {
        bool isLogout = false,
      }) {
    final selected = currentIndex == idx;
    final bool isWide = MediaQuery.of(context).size.width >= 1000;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: selected ? AppColors.secondary.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (!isWide && Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
            if (isLogout) {
              _ProfileDialog.showConfirmLogout();
            } else if (idx != currentIndex) {
              Navigator.pushNamed(context, route);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                        icon,
                        color: isLogout ? AppColors.error : (selected ? AppColors.secondary : AppColors.textSecondary)
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surface, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              badgeCount > 9 ? '9+' : badgeCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isLogout ? AppColors.error : (selected ? AppColors.secondary : AppColors.textPrimary),
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (badgeCount > 0 && !isLogout)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeCount > 9 ? '9+' : badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
              profileData?['name'] ?? 'Admin User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? 'admin@zachuma.com',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              profileData?['role']?.toString().toUpperCase() ?? 'ADMINISTRATOR',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _profileMenuItem(context, Icons.account_circle, "My Profile", () {
              Navigator.pop(context);
              Future.microtask(() => Navigator.pushNamed(context, '/admin/profile'));
            }),
            _profileMenuItem(context, Icons.settings, "Account Settings", () {
              Navigator.pop(context);
              Future.microtask(() => Navigator.pushNamed(context, '/admin/settings'));
            }),
            _profileMenuItem(context, Icons.help_outline, "Help & Support", () {
              Navigator.pop(context);
              Future.microtask(() => Navigator.pushNamed(context, '/admin/help'));
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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