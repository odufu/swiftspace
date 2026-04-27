import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:swiftspace/core/constants/app_constants.dart';
import 'package:swiftspace/features/auth/presentation/state/auth_provider.dart';
import 'package:swiftspace/features/auth/presentation/pages/edit_profile_screen.dart';
import 'package:swiftspace/features/auth/presentation/pages/splash_screen.dart';
import 'package:swiftspace/main.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/di/injection_container.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.profile;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
        child: Column(
          children: [
            // Professional Credentials Header
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      sl<AudioManager>().playClick(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryLight, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryLight.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: profile?.avatarUrl != null
                                ? Image.network(profile!.avatarUrl!, fit: BoxFit.cover)
                                : Icon(LucideIcons.user, size: 50, color: Colors.grey[400]),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.surface, width: 3),
                            ),
                            child: const Icon(LucideIcons.camera, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    profile?.fullName ?? 'Professional',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile?.email ?? 'verified@swiftspace.com',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.award, color: Colors.amber, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'GOLD VERIFIED',
                          style: TextStyle(
                            color: Colors.amber[700],
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            _buildSectionHeader('Ecosystem Sync'),
            _buildActionTile(
              context: context,
              title: 'Switch to Explorer Mode',
              subtitle: 'Browse properties as a client',
              icon: LucideIcons.repeat,
              color: AppColors.primaryLight,
              onTap: () {
                sl<AudioManager>().playClick(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainLayout()),
                  (route) => false,
                );
              },
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('Professional Suite'),
            _buildActionTile(
              context: context,
              title: 'Payout Methods',
              subtitle: 'Manage connected bank accounts',
              icon: LucideIcons.creditCard,
              color: Colors.green,
              onTap: () {},
            ),
            _buildActionTile(
              context: context,
              title: 'Business Profile',
              subtitle: 'Update your professional bio',
              icon: LucideIcons.briefcase,
              color: Colors.blue,
              onTap: () {},
            ),
             _buildActionTile(
              context: context,
              title: 'Analytics Export',
              subtitle: 'Download monthly performance reports',
              icon: LucideIcons.download,
              color: Colors.purple,
              onTap: () {},
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('Security'),
            _buildActionTile(
              context: context,
              title: 'Logout',
              subtitle: 'Securely sign out of your portal',
              icon: LucideIcons.logOut,
              color: Colors.red,
              onTap: () async {
                sl<AudioManager>().playClick(context);
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SplashScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.grey,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            onTap: onTap,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
