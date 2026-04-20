import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/core/utils/responsive.dart';
import 'package:swiftspace/core/constants/app_constants.dart';
import 'package:swiftspace/features/auth/presentation/state/auth_provider.dart';
import 'package:swiftspace/features/auth/presentation/pages/operations/components/operations_sidebar.dart';
import 'package:swiftspace/features/auth/presentation/pages/operations/sections/overview_section.dart';
import 'package:swiftspace/features/auth/presentation/pages/operations/sections/users_section.dart';
import 'package:swiftspace/features/auth/presentation/pages/operations/sections/realtors_section.dart';
import 'package:swiftspace/features/auth/presentation/pages/operations/sections/properties_section.dart';

class OperationsDashboard extends StatefulWidget {
  const OperationsDashboard({super.key});

  @override
  State<OperationsDashboard> createState() => _OperationsDashboardState();
}

class _OperationsDashboardState extends State<OperationsDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _titles = [
    'System Overview',
    'User Management',
    'Realtor Hub',
    'Property Inventory',
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: !isDesktop ? _buildDrawer() : null,
      bottomNavigationBar: !isDesktop ? _buildBottomNav() : null,
      body: Row(
        children: [
          if (isDesktop)
            OperationsSidebar(
              selectedIndex: _selectedIndex,
              onEntrySelected: (index) => setState(() => _selectedIndex = index),
            ),
          Expanded(
            child: Column(
              children: [
                _buildAppBar(isDesktop),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDesktop) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(LucideIcons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          Text(
            _selectedIndex >= 0 && _selectedIndex < _titles.length 
                ? _titles[_selectedIndex] 
                : _selectedIndex == -1 ? 'Settings' : 'Operations',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(LucideIcons.bell, size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 18,
            backgroundImage: authProvider.profile?.avatarUrl != null
                ? NetworkImage(authProvider.profile!.avatarUrl!)
                : null,
            child: authProvider.profile?.avatarUrl == null
                ? const Icon(LucideIcons.user, size: 20)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return const OverviewSection();
      case 1: return const UsersSection();
      case 2: return const RealtorsSection();
      case 3: return const PropertiesSection();
      case -1: return const Center(child: Text('Settings Screen Placeholder'));
      default: return const OverviewSection();
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: OperationsSidebar(
        selectedIndex: _selectedIndex,
        onEntrySelected: (index) {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard), label: 'Stats'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.users), label: 'Users'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.briefcase), label: 'Pros'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Props'),
      ],
    );
  }
}
