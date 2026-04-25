import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import 'package:swiftspace/features/auth/domain/models/user_profile.dart';
import 'package:swiftspace/main.dart';
import 'package:swiftspace/features/agent/presentation/pages/professional_dashboard_screen.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/core/constants/app_constants.dart';

// Role data model — keeps build() clean
class _RoleOption {
  final int index;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _RoleOption({
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

const _roles = [
  _RoleOption(
    index: 0,
    icon: LucideIcons.search,
    title: 'Explorer',
    subtitle: 'Browse properties for rent or purchase.',
    color: AppColors.primaryDark,
  ),
  _RoleOption(
    index: 1,
    icon: LucideIcons.key,
    title: 'Real Estate Agent',
    subtitle: 'List and manage properties for clients.',
    color: Color(0xFF6366F1),
  ),
  _RoleOption(
    index: 2,
    icon: LucideIcons.home,
    title: 'Property Owner',
    subtitle: 'List your personal properties directly.',
    color: Color(0xFF10B981),
  ),
  _RoleOption(
    index: 3,
    icon: LucideIcons.building,
    title: 'Developer',
    subtitle: 'Showcase your new projects and estates.',
    color: Color(0xFFF59E0B),
  ),
  _RoleOption(
    index: 4,
    icon: LucideIcons.briefcase,
    title: 'Agency / Company',
    subtitle: 'Manage listings for your entire organization.',
    color: Color(0xFFEC4899),
  ),
];

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
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
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _selectRole(int index) {
    setState(() => _selectedIndex = index);
    sl<AudioManager>().playClick(context);
    sl<AudioManager>().triggerHaptic(context);

    final UserRole role;
    switch (index) {
      case 0:
        role = UserRole.user;
      case 1:
        role = UserRole.agent;
      case 2:
        role = UserRole.owner;
      case 3:
        role = UserRole.developer;
      case 4:
        role = UserRole.company;
      default:
        role = UserRole.user;
    }

    Provider.of<AuthProvider>(context, listen: false)
        .updateRole(role)
        .then((_) {
      if (!mounted) return;
      if (role == UserRole.user) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainLayout()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => const ProfessionalDashboardScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 1024) {
                return _buildDesktopLayout();
              } else if (constraints.maxWidth >= 600) {
                return _buildTabletLayout();
              } else {
                return _buildMobileLayout();
              }
            },
          ),
        ),
      ),
    );
  }

  // ── Mobile: single-column scrollable list ────────────────────────────
  Widget _buildMobileLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildLogoAndTitle(isDark),
            const SizedBox(height: 40),
            ..._roles.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildRoleCard(r),
                )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Tablet: centered max-width column ───────────────────────────────
  Widget _buildTabletLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildLogoAndTitle(isDark),
                const SizedBox(height: 40),
                ..._roles.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildRoleCard(r),
                    )),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Desktop: branding panel left, 2-column role grid right ──────────
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left branding panel (same as EmailAuthScreen)
        Expanded(
          flex: 4,
          child: _buildBrandingPanel(),
        ),
        // Right role selection area
        Expanded(
          flex: 5,
          child: SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What brings you to\nSwift Space?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select your role. Professional roles undergo a quick verification process.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // 2-column grid of role cards
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.7,
                      ),
                      itemCount: _roles.length,
                      itemBuilder: (context, i) =>
                          _buildRoleCardCompact(_roles[i]),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Shared components ────────────────────────────────────────────────

  Widget _buildLogoAndTitle(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  /// Full-width card for mobile / tablet
  Widget _buildRoleCard(_RoleOption role) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedIndex == role.index;

    return GestureDetector(
      onTap: () => _selectRole(role.index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? role.color.withValues(alpha: 0.1)
              : (isDark ? Colors.grey[900] : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? role.color
                : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: role.color.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ]
              : [
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: role.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(role.icon, color: role.color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.checkCircle2, color: role.color, size: 22),
          ],
        ),
      ),
    );
  }

  /// Compact square card for desktop 2-column grid
  Widget _buildRoleCardCompact(_RoleOption role) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedIndex == role.index;

    return GestureDetector(
      onTap: () => _selectRole(role.index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? role.color.withValues(alpha: 0.1)
              : (isDark ? Colors.grey[900] : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? role.color
                : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? role.color.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: isSelected ? 20 : 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: role.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(role.icon, color: role.color, size: 22),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(LucideIcons.checkCircle2, color: role.color, size: 18),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              role.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                role.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandingPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A5C), Color(0xFF0B4F6C), Color(0xFF01BAEF)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -80,
            child: _circle(300, Colors.white.withValues(alpha: 0.04)),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: _circle(260, Colors.white.withValues(alpha: 0.06)),
          ),
          Padding(
            padding: const EdgeInsets.all(56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(AppAssets.logo, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose your role and unlock\na tailored experience.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 17,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),
                _featureLine('🏠', 'Find & list properties with AI'),
                _featureLine('✅', 'Verified agents & secure deals'),
                _featureLine('📊', 'Smart analytics for professionals'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureLine(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
