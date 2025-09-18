import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/admin_repository.dart';
import 'admin_shell.dart';

class AdminUsers extends StatelessWidget {
  const AdminUsers({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AdminRepository();
    return AdminShell(
      title: "Users",
      currentIndex: 2,
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Manage Users", style: AppTextStyles.heading.copyWith(fontSize: 24)),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: repo.streamUsers(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snap.hasError) {
                    return Center(
                      child: Text(
                          "Error loading users",
                          style: AppTextStyles.regular.copyWith(color: AppColors.error)
                      ),
                    );
                  }

                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                          "No users found.",
                          style: AppTextStyles.regular
                      ),
                    );
                  }

                  final docs = snap.data!.docs;

                  return LayoutBuilder(
                    builder: (_, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      if (isWide) {
                        return _UsersTable(repo: repo, docs: docs);
                      } else {
                        return _UsersList(repo: repo, docs: docs);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersTable extends StatelessWidget {
  final AdminRepository repo;
  final List<QueryDocumentSnapshot> docs;
  const _UsersTable({required this.repo, required this.docs});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.8),
          child: DataTable(
            columnSpacing: 20,
            horizontalMargin: 16,
            columns: [
              DataColumn(
                label: Text("Name", style: AppTextStyles.midFont),
              ),
              DataColumn(
                label: Text("Email", style: AppTextStyles.midFont),
              ),
              DataColumn(
                label: Text("Role", style: AppTextStyles.midFont),
              ),
              DataColumn(
                label: Text("Status", style: AppTextStyles.midFont),
              ),
              DataColumn(
                label: Text("Actions", style: AppTextStyles.midFont),
              ),
            ],
            rows: docs.map((e) {
              final id = e.id;
              final d = e.data() as Map<String, dynamic>;
              final blocked = (d['blocked'] ?? false) == true;
              final role = (d['role'] ?? 'user').toString();

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      d['name'] ?? '—',
                      style: AppTextStyles.regular,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Text(
                      d['email'] ?? '—',
                      style: AppTextStyles.regular,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(role).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: AppTextStyles.regular.copyWith(
                            color: _getRoleColor(role),
                            fontWeight: FontWeight.w600
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: blocked ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        blocked ? 'BLOCKED' : 'ACTIVE',
                        style: AppTextStyles.regular.copyWith(
                            color: blocked ? AppColors.error : AppColors.success,
                            fontSize: 14,
                            fontWeight: FontWeight.w600
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        // Role selection dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.accent),
                          ),
                          child: DropdownButton<String>(
                            value: role,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            style: AppTextStyles.regular.copyWith(fontSize: 14),
                            onChanged: (String? newRole) {
                              if (newRole != null && newRole != role) {
                                _confirmRoleChange(context, id, role, newRole, repo);
                              }
                            },
                            items: _buildRoleDropdownItems(role),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Block/Unblock button
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: blocked ? AppColors.success : AppColors.error,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onPressed: () => _confirmStatusChange(context, id, !blocked, repo),
                          child: Text(
                            blocked ? "Unblock" : "Block",
                            style: AppTextStyles.regular.copyWith(
                                color: AppColors.surface,
                                fontWeight: FontWeight.w600
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.secondary;
      case 'creator':
        return AppColors.primary;
      case 'reviewer':
        return AppColors.warning;
      case 'expert':
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _UsersList extends StatelessWidget {
  final AdminRepository repo;
  final List<QueryDocumentSnapshot> docs;
  const _UsersList({required this.repo, required this.docs});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final id = docs[i].id;
        final d = docs[i].data() as Map<String, dynamic>;
        return _UserTile(repo: repo, id: id, d: d);
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final AdminRepository repo;
  final String id;
  final Map<String, dynamic> d;
  const _UserTile({required this.repo, required this.id, required this.d});

  @override
  Widget build(BuildContext context) {
    final blocked = (d['blocked'] ?? false) == true;
    final role = (d['role'] ?? 'user').toString();

    return Card(
      color: AppColors.surface,
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d['name'] ?? '—',
                        style: AppTextStyles.midFont,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d['email'] ?? '—',
                        style: AppTextStyles.notificationText,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Role selection dropdown
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: DropdownButton<String>(
                      value: role,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                      style: AppTextStyles.regular.copyWith(fontSize: 14),
                      onChanged: (String? newRole) {
                        if (newRole != null && newRole != role) {
                          _confirmRoleChange(context, id, role, newRole, repo);
                        }
                      },
                      items: _buildRoleDropdownItems(role),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    decoration: BoxDecoration(
                      color: blocked ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      blocked ? 'BLOCKED' : 'ACTIVE',
                      style: AppTextStyles.notificationText.copyWith(
                          color: blocked ? AppColors.error : AppColors.success,
                          fontWeight: FontWeight.w600
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: blocked ? AppColors.success : AppColors.error,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _confirmStatusChange(context, id, !blocked, repo),
                child: Text(
                  blocked ? "Unblock User" : "Block User",
                  style: AppTextStyles.regular.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w600
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.secondary;
      case 'creator':
        return AppColors.primary;
      case 'reviewer':
        return AppColors.warning;
      case 'expert':
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }
}

// Helper function to build dropdown items for roles
List<DropdownMenuItem<String>> _buildRoleDropdownItems(String currentRole) {
  // Define standard roles
  const standardRoles = ['user', 'creator', 'reviewer', 'admin'];

  // Create items for standard roles
  final items = standardRoles.map((role) => DropdownMenuItem<String>(
    value: role,
    child: Text(role[0].toUpperCase() + role.substring(1)),
  )).toList();

  // If current role is not a standard role, add it to the list
  if (currentRole.isNotEmpty && !standardRoles.contains(currentRole)) {
    items.add(DropdownMenuItem<String>(
      value: currentRole,
      child: Text(currentRole[0].toUpperCase() + currentRole.substring(1)),
    ));
  }

  return items;
}

// Helper function to confirm role changes
void _confirmRoleChange(BuildContext context, String userId, String currentRole, String newRole, AdminRepository repo) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Change User Role"),
        content: Text("Are you sure you want to change this user's role from ${currentRole.toUpperCase()} to ${newRole.toUpperCase()}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              repo.setUserRole(userId, newRole);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("User role updated to ${newRole.toUpperCase()}"),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text("Confirm"),
          ),
        ],
      );
    },
  );
}

// Helper function to confirm status changes
void _confirmStatusChange(BuildContext context, String userId, bool newStatus, AdminRepository repo) {
  final action = newStatus ? "block" : "unblock";
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("${action.toUpperCase()} User"),
        content: Text("Are you sure you want to $action this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              repo.setUserStatus(userId, newStatus);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("User ${action}ed successfully"),
                  backgroundColor: newStatus ? AppColors.error : AppColors.success,
                ),
              );
            },
            child: const Text("Confirm"),
          ),
        ],
      );
    },
  );
}