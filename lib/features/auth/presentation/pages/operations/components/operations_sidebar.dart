import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/core/constants/app_constants.dart';

class OperationsSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onEntrySelected;

  const OperationsSidebar({
    super.key,
    required this.selectedIndex,
    required this.onEntrySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 48),
          _buildLogo(),
          const SizedBox(height: 48),
          _buildNavItem(0, 'Overview', LucideIcons.layoutDashboard),
          _buildNavItem(1, 'Users', LucideIcons.users),
          _buildNavItem(2, 'Realtors', LucideIcons.briefcase),
          _buildNavItem(3, 'Properties', LucideIcons.home),
          const Spacer(),
          _buildNavItem(-1, 'Settings', LucideIcons.settings),
          _buildNavItem(-2, 'Logout', LucideIcons.logOut),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(LucideIcons.globe, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Text(
          'OPERATIONS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: () => onEntrySelected(index),
        selected: isSelected,
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primaryLight : Colors.grey,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryLight : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selectedTileColor: AppColors.primaryLight.withValues(alpha: 0.1),
      ),
    );
  }
}
