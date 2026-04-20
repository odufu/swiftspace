import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/features/auth/presentation/state/admin_provider.dart';

class UsersSection extends StatefulWidget {
  const UsersSection({super.key});

  @override
  State<UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends State<UsersSection> {
  final _searchController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    final ap = Provider.of<AdminProvider>(context);
    final users = ap.allUsers.where((u) {
      final search = _searchController.text.toLowerCase();
      final name = u.fullName?.toLowerCase() ?? '';
      final email = u.email.toLowerCase();
      return name.contains(search) || email.contains(search);
    }).toList();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('User Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Spacer(),
              _buildSearchField(),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserTile(user, ap);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search users...',
          prefixIcon: const Icon(LucideIcons.search, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildUserTile(user, AdminProvider ap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[200],
        backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
        child: user.avatarUrl == null ? const Icon(LucideIcons.user, size: 20) : null,
      ),
      title: Text(user.fullName ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(user.email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRoleBadge(user.role),
          const SizedBox(width: 16),
          _buildActionMenu(user, ap),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.displayName.toUpperCase(),
        style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActionMenu(user, AdminProvider ap) {
    return PopupMenuButton(
      icon: const Icon(LucideIcons.moreVertical, size: 20),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'view', child: Text('View Details')),
        PopupMenuItem(
          value: 'status', 
          child: Text(user.isBlocked ? 'Unblock User' : 'Block User', style: TextStyle(color: user.isBlocked ? Colors.green : Colors.red)),
        ),
      ],
      onSelected: (value) {
        if (value == 'status') {
          ap.toggleUserStatus(user.id, !user.isBlocked);
        }
      },
    );
  }
}
