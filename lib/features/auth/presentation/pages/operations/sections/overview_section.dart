import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/features/auth/presentation/state/admin_provider.dart';
import 'package:swiftspace/features/chat/presentation/state/chat_provider.dart';

class OverviewSection extends StatelessWidget {
  const OverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(adminProvider),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildGrowthChart()),
              const SizedBox(width: 24),
              Expanded(child: _buildRecentChats(chatProvider)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AdminProvider ap) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCard('Total Users', '${ap.totalUsers}', LucideIcons.users, Colors.blue),
        _buildStatCard('Active Realtors', '${ap.totalRealtors}', LucideIcons.briefcase, Colors.green),
        _buildStatCard('Total Properties', '${ap.totalProperties}', LucideIcons.home, Colors.orange),
        _buildStatCard('Pending Requests', '${ap.pendingVerifications}', LucideIcons.clock, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildGrowthChart() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Growth', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Spacer(),
          Center(child: Text('Analytics Visualization Placeholder', style: TextStyle(color: Colors.grey))),
          Spacer(),
        ],
      ),
    );
  }

  Widget _buildRecentChats(ChatProvider cp) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Inquiries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: cp.rooms.isEmpty
                ? const Center(child: Text('No recent inquiries', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: cp.rooms.length > 5 ? 5 : cp.rooms.length,
                    itemBuilder: (context, index) {
                      final room = cp.rooms[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(room.propertyImageUrl),
                        ),
                        title: Text(room.propertyTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(room.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(LucideIcons.chevronRight, size: 16),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
