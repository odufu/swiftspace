import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import 'package:swiftspace/features/auth/domain/models/user_profile.dart';
import 'package:swiftspace/main.dart';
import 'package:swiftspace/features/agent/presentation/pages/agent_dashboard_screen.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/core/constants/app_constants.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _selectRole(int index) {
    setState(() {
      _selectedIndex = index;
    });

    sl<AudioManager>().playClick(context);
    sl<AudioManager>().triggerHaptic(context);

    // Map index to role
    final UserRole role;
    switch (index) {
      case 0: role = UserRole.user; break;
      case 1: role = UserRole.agent; break;
      case 2: role = UserRole.owner; break;
      case 3: role = UserRole.developer; break;
      case 4: role = UserRole.company; break;
      default: role = UserRole.user;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    authProvider.updateRole(role).then((_) {
      if (!mounted) return;
      if (role == UserRole.user) {
        // User/Explorer mode
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainLayout()),
          (route) => false,
        );
      } else {
        // Professional modes - Dynamic Dashboard handles state
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AgentDashboardScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/logo.png',
                    width: 40,
                    height: 40,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'What brings you to\nSwift Space?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select how you want to use the platform. Each professional role undergoes a verification process for security.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  _buildRoleCard(
                    context,
                    index: 0,
                    icon: LucideIcons.search,
                    title: 'Explorer',
                    subtitle: 'I want to browse properties for rent or purchase.',
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(height: 16),
                  _buildRoleCard(
                    context,
                    index: 1,
                    icon: LucideIcons.key,
                    title: 'Real Estate Agent',
                    subtitle: 'Apply for agent status to list and manage properties for clients.',
                    color: const Color(0xFF6366F1),
                  ),
                  const SizedBox(height: 16),
                  _buildRoleCard(
                    context,
                    index: 2,
                    icon: LucideIcons.home,
                    title: 'Property Owner',
                    subtitle: 'Apply for owner status to list your personal properties directly.',
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 16),
                  _buildRoleCard(
                    context,
                    index: 3,
                    icon: LucideIcons.building,
                    title: 'Developer',
                    subtitle: 'Apply for developer status to showcase your new projects and estates.',
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 16),
                  _buildRoleCard(
                    context,
                    index: 4,
                    icon: LucideIcons.briefcase,
                    title: 'Agency / Company',
                    subtitle: 'Apply for corporate status to manage listings for your entire organization.',
                    color: const Color(0xFFEC4899),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, {required int index, required IconData icon, required String title, required String subtitle, required Color color}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _selectRole(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withValues(alpha: 0.1) 
              : (isDark ? Colors.grey[900] : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
