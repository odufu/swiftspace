import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:swiftspace/core/theme/theme_provider.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/features/agent/presentation/pages/agent_dashboard_screen.dart';
import 'package:swiftspace/features/auth/presentation/pages/agent_application_screen.dart';
import 'package:swiftspace/features/auth/presentation/pages/admin_verification_screen.dart';
import 'package:swiftspace/features/auth/presentation/pages/splash_screen.dart'; // For mock logout
import 'package:swiftspace/features/auth/presentation/state/user_preferences_provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // Synced with UserPreferencesProvider

  void _showTargetNotifications() {
    AudioManager().playClick(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _TargetNotificationsModal(),
    );
  }

  void _showAppSettings() {
    AudioManager().playClick(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AppSettingsModal(),
    );
  }

  void _logout() {
    AudioManager().playClick(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userPrefs = Provider.of<UserPreferencesProvider>(context);
    final isAgent = userPrefs.isAgent;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
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
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.primary, width: 3),
                            image: const DecorationImage(
                              image: NetworkImage('https://i.pravatar.cc/150?img=11'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.surface, width: 2),
                            ),
                            child: const Icon(LucideIcons.camera, color: Colors.white, size: 16),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Joel Developer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('joel@swiftspace.com', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Account & Ecosystem
              const Text('Ecosystem Sync', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              _buildActionTile(
                title: isAgent ? 'Enter Agent Dashboard' : 'Apply to Become an Agent',
                subtitle: isAgent ? 'Manage your listings, CRM & Sales' : 'List properties and build your portfolio',
                icon: isAgent ? LucideIcons.briefcase : LucideIcons.fileSignature,
                color: isAgent ? Colors.green : Colors.blue,
                onTap: () async {
                  if (isAgent) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const AgentDashboardScreen()),
                      (route) => false,
                    );
                  } else {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentApplicationScreen()));
                    if (result == true) {
                      userPrefs.toggleAgentMode(true);
                    }
                  }
                },
              ),
              _buildActionTile(
                title: 'Admin Verification Portal',
                subtitle: 'Review & verify pending property listings',
                icon: LucideIcons.shieldCheck,
                color: Colors.deepOrange,
                onTap: () {
                  AudioManager().playClick(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVerificationScreen()));
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
                   AudioManager().playSuccess(context);
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
