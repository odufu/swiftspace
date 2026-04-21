import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:swiftspace/core/constants/app_constants.dart';
import 'package:swiftspace/features/auth/presentation/state/auth_provider.dart';
import 'package:swiftspace/features/auth/presentation/pages/professional_application_screen.dart';
import 'package:swiftspace/features/auth/presentation/pages/splash_screen.dart';
import 'package:swiftspace/main.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/features/chat/presentation/state/chat_provider.dart';
import 'package:swiftspace/features/chat/presentation/state/notification_provider.dart';
import 'package:swiftspace/features/chat/domain/entities/notification.dart';
import 'package:swiftspace/core/presentation/widgets/common/badge_icon.dart';

// Import New Modular Tabs
import 'dashboard_tabs/overview_tab.dart';
import 'dashboard_tabs/my_properties_tab.dart';
import 'dashboard_tabs/crm_leads_tab.dart';
import 'dashboard_tabs/accounting_tab.dart';
import 'dashboard_tabs/profile_tab.dart';

class ProfessionalDashboardScreen extends StatefulWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  State<ProfessionalDashboardScreen> createState() =>
      _ProfessionalDashboardScreenState();
}

class _ProfessionalDashboardScreenState
    extends State<ProfessionalDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const OverviewTab(),
    const MyPropertiesTab(),
    const CrmLeadsTab(),
    const AccountingTab(),
    const ProfileTab(),
  ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    sl<AudioManager>().playClick(context);
    sl<AudioManager>().triggerHaptic(context);
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final isVerified = authProvider.profile?.isVerified ?? false;

    if (!isVerified) {
      return _buildPendingVerificationScreen(theme);
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PRO PORTAL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.grey,
              ),
            ),
            Text(
              AppConstants.appName.toUpperCase(),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.5,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer2<ChatProvider, NotificationProvider>(
            builder: (context, chat, note, child) {
              return Row(
                children: [
                  BadgeIcon(
                    icon: LucideIcons.messageSquare,
                    count: chat.totalUnreadCount,
                    onPressed: () {
                      _onTabTapped(2); // Goes to CRM (Index 2)
                    },
                  ),
                  BadgeIcon(
                    icon: LucideIcons.bell,
                    count: note.unreadCount,
                    onPressed: () {
                      _showNotificationSheet(context);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient Subtle Accent
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.03),
              ),
            ),
          ),

          IndexedStack(index: _currentIndex, children: _pages),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(theme, isDark),
    );
  }

  Widget _buildBottomNav(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            selectedItemColor: AppColors.primaryLight,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            backgroundColor: Colors.transparent,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.layoutDashboard, size: 22),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.layoutDashboard, size: 24),
                ),
                label: 'OVERVIEW',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.home, size: 22),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.home, size: 24),
                ),
                label: 'LISTINGS',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.users, size: 22),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.users, size: 24),
                ),
                label: 'CRM',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.creditCard, size: 22),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.creditCard, size: 24),
                ),
                label: 'BILLING',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.user, size: 22),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(LucideIcons.user, size: 24),
                ),
                label: 'PROFILE',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingVerificationScreen(ThemeData theme) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.profile;
    final isApplicationIncomplete = profile?.governmentIdUrl == null;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryLight.withValues(alpha: 0.1),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color:
                        (isApplicationIncomplete ? Colors.blue : Colors.amber)
                            .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isApplicationIncomplete
                        ? LucideIcons.fileSignature
                        : LucideIcons.shieldCheck,
                    color: isApplicationIncomplete ? Colors.blue : Colors.amber,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  isApplicationIncomplete
                      ? 'Credential Verification'
                      : 'Reviewing Your Info',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isApplicationIncomplete
                      ? 'To maintain the integrity of Swift Space, we require all professionals to submit government-issued identification and business licenses.'
                      : 'Our compliance team is currently verifying your documents. You will receive a notification once your professional portal is active.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 64),
                if (isApplicationIncomplete)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        sl<AudioManager>().playClick(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ProfessionalApplicationScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        elevation: 10,
                        shadowColor: AppColors.primaryLight.withValues(
                          alpha: 0.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'CONTINUE APPLICATION',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(
                        'ESTIMATED WAIT: < 24 HOURS',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () {
                    sl<AudioManager>().playClick(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainLayout()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    'GO TO EXPLORER MODE',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    sl<AudioManager>().playClick(context);
                    authProvider.signOut();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const SplashScreen()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    'SIGN OUT',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            final notes = provider.notifications;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Portal Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: provider.markAllAsRead,
                          child: const Text('Mark all read'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  if (notes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('All caught up!'),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final n = notes[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getNoteColor(
                                n.type,
                              ).withValues(alpha: 0.1),
                              child: Icon(
                                _getNoteIcon(n.type),
                                color: _getNoteColor(n.type),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              n.title,
                              style: TextStyle(
                                fontWeight: n.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              n.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              _formatTime(n.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            onTap: () => provider.markAsRead(n.id),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getNoteIcon(NotificationType type) {
    switch (type) {
      case NotificationType.inspection:
        return LucideIcons.calendar;
      case NotificationType.offer:
        return LucideIcons.landmark;
      case NotificationType.chat:
        return LucideIcons.messageSquare;
      case NotificationType.match:
        return LucideIcons.home;
      case NotificationType.system:
        return LucideIcons.info;
      default:
        return LucideIcons.bell;
    }
  }

  Color _getNoteColor(NotificationType type) {
    switch (type) {
      case NotificationType.inspection:
        return Colors.blue;
      case NotificationType.offer:
        return Colors.green;
      case NotificationType.chat:
        return Colors.orange;
      case NotificationType.match:
        return Colors.purple;
      case NotificationType.system:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
