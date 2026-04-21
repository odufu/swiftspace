import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:swiftspace/core/theme/theme_provider.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/features/agent/presentation/pages/professional_dashboard_screen.dart';
import 'package:swiftspace/features/auth/presentation/pages/agent_application_screen.dart';
import 'package:swiftspace/features/auth/presentation/pages/admin_verification_screen.dart';
import 'package:swiftspace/features/auth/presentation/pages/operations/operations_dashboard.dart';
import 'package:swiftspace/features/auth/presentation/pages/splash_screen.dart';
import 'package:swiftspace/features/auth/presentation/state/auth_provider.dart';
import 'package:swiftspace/features/auth/presentation/pages/edit_profile_screen.dart';
import 'package:swiftspace/features/auth/domain/models/user_profile.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // Synced with UserPreferencesProvider

  void _showTargetNotifications() {
    sl<AudioManager>().playClick(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _TargetNotificationsModal(),
    );
  }

  void _showAppSettings() {
    sl<AudioManager>().playClick(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AppSettingsModal(),
    );
  }

  void _logout() async {
    sl<AudioManager>().playClick(context);
    await Provider.of<AuthProvider>(context, listen: false).signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.profile;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: authProvider.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              // User Identity Header
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            sl<AudioManager>().playClick(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                          },
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.primary, width: 3),
                              image: profile?.avatarUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(profile!.avatarUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: profile?.avatarUrl == null
                                ? const Icon(LucideIcons.user, size: 50, color: Colors.grey)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              sl<AudioManager>().playClick(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.colorScheme.surface, width: 2),
                              ),
                              child: const Icon(LucideIcons.edit2, color: Colors.white, size: 16),
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile?.fullName ?? 'No Name Set',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.email ?? 'no-email@example.com',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Chip(
                      label: Text(
                        (profile?.role.name ?? 'user').toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Account & Ecosystem
              const Text('Ecosystem Sync', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              // Agent / Professional Section
              if (profile?.role == UserRole.user)
                _buildActionTile(
                  title: 'Apply to Become an Agent',
                  subtitle: 'List properties and build your portfolio',
                  icon: LucideIcons.fileSignature,
                  color: Colors.blue,
                  onTap: () async {
                    final result = await Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const AgentApplicationScreen())
                    );
                    if (result == true) {
                      authProvider.updateRole(UserRole.agent);
                    }
                  },
                ),

              if (profile?.role == UserRole.agent || profile?.role == UserRole.admin || profile?.role == UserRole.sadmin)
                _buildActionTile(
                  title: 'Enter Agent Dashboard',
                  subtitle: 'Manage listings, CRM & Sales',
                  icon: LucideIcons.briefcase,
                  color: Colors.green,
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfessionalDashboardScreen()),
                      (route) => false,
                    );
                  },
                ),

              if (profile?.role == UserRole.admin || profile?.role == UserRole.sadmin)
                _buildActionTile(
                  title: 'Operations Dashboard',
                  subtitle: 'Central Management & Verification',
                  icon: LucideIcons.shieldCheck,
                  color: Colors.deepPurple,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsDashboard()));
                  },
                ),

              const SizedBox(height: 24),

              // Preferences & Settings
              const Text('Preferences', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              _buildActionTile(
                title: 'Target Notifications',
                subtitle: 'Set auto-alerts for specific houses',
                icon: LucideIcons.bell,
                color: Colors.purple,
                onTap: _showTargetNotifications,
              ),
              _buildActionTile(
                title: 'App Settings',
                subtitle: 'Theme, Sounds & Haptics',
                icon: LucideIcons.settings,
                color: Colors.orange,
                onTap: _showAppSettings,
              ),
              
              const SizedBox(height: 24),

              // Danger Zone
              const Text('Danger Zone', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              _buildActionTile(
                title: 'Logout',
                subtitle: 'Sign out of your account securely',
                icon: LucideIcons.logOut,
                color: Colors.red,
                onTap: _logout,
              ),
              
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: const Icon(LucideIcons.chevronRight, size: 20),
        onTap: onTap,
      ),
    );
  }
}

// ----------------------------------------------------
// Target Notifications Sub-Modal
// ----------------------------------------------------
class _TargetNotificationsModal extends StatefulWidget {
  const _TargetNotificationsModal();
  @override
  State<_TargetNotificationsModal> createState() => _TargetNotificationsModalState();
}
class _TargetNotificationsModalState extends State<_TargetNotificationsModal> {
  double _minPrice = 1000000;
  double _maxPrice = 8000000;
  PropertyType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Target Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Set your ideal property parameters. Our AI will alert you instantly.', style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4)),
            const SizedBox(height: 24),
            
            Text('Price Range (₦)', style: const TextStyle(fontWeight: FontWeight.w600)),
            RangeSlider(
               values: RangeValues(_minPrice, _maxPrice),
               min: 0,
               max: 10000000,
               divisions: 100,
               activeColor: theme.colorScheme.primary,
               labels: RangeLabels('₦${(_minPrice/1000000).toStringAsFixed(1)}M', '₦${(_maxPrice/1000000).toStringAsFixed(1)}M'),
               onChanged: (values) => setState(() { _minPrice = values.start; _maxPrice = values.end; }),
            ),
            const SizedBox(height: 16),
            
            Text('Target Property Type', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
               spacing: 8,
               children: PropertyType.values.map((type) {
                 final isSelected = _selectedType == type;
                 return ChoiceChip(
                   label: Text(type.name),
                   selected: isSelected,
                   onSelected: (selected) => setState(() => _selectedType = selected ? type : null),
                   selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                   labelStyle: TextStyle(color: isSelected ? theme.colorScheme.primary : (isDark ? Colors.white : Colors.black)),
                 );
               }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                   sl<AudioManager>().playSuccess(context);
                   Navigator.pop(context);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Target Preferences Saved!')));
                },
                style: ElevatedButton.styleFrom(
                   backgroundColor: theme.colorScheme.primary,
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Targets', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// App Settings Sub-Modal
// ----------------------------------------------------
class _AppSettingsModal extends StatelessWidget {
  const _AppSettingsModal();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('App Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Dark Theme'),
            secondary: Icon(isDark ? LucideIcons.moon : LucideIcons.sun),
            value: isDark,
            activeThumbColor: theme.colorScheme.primary,
            onChanged: (val) => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(!isDark),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('In-App Sounds'),
            subtitle: const Text('Play futuristic clicks & alerts'),
            secondary: const Icon(LucideIcons.volume2),
            value: true, 
            activeThumbColor: theme.colorScheme.primary,
            onChanged: (val) {}, // Normally connected to provider
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
