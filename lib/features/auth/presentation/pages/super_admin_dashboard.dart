import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/features/auth/presentation/state/verification_provider.dart';
import 'package:swiftspace/features/auth/presentation/state/auth_provider.dart';
import 'package:swiftspace/features/auth/presentation/pages/admin_verification_screen.dart';
import 'package:swiftspace/features/auth/domain/models/user_profile.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/core/services/audio_manager.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load real pending requests from Supabase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VerificationProvider>(context, listen: false).loadPendingRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final verificationProvider = Provider.of<VerificationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Dynamic Sadmin Theme (Deep Indigo)
    const sadminColor = Color(0xFF4F46E5); 

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(theme, sadminColor, authProvider),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsGrid(verificationProvider, sadminColor),
                  const SizedBox(height: 32),
                  _buildTabSection(theme, sadminColor),
                ],
              ),
            ),
          ),
          _buildDynamicList(verificationProvider, sadminColor, theme),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, Color primaryColor, AuthProvider authProvider) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: const Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Super Admin',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
            ),
            Text(
              'Swift Space Operations',
              style: TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
        background: Stack(
          children: [
            Positioned(
              right: -50,
              top: -50,
              child: CircleAvatar(
                radius: 100,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            sl<AudioManager>().playClick(context);
            authProvider.signOut();
          },
          icon: const Icon(LucideIcons.logOut, color: Colors.white),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatsGrid(VerificationProvider vp, Color primaryColor) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Partners Pending', '${vp.pendingRequests.length}', LucideIcons.userPlus, Colors.amber),
        _buildStatCard('Properties', '${vp.pendingVerifications.length}', LucideIcons.home, Colors.blue),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection(ThemeData theme, Color primaryColor) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: primaryColor,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.tab,
        onTap: (index) => setState(() {}),
        tabs: const [
          Tab(text: 'Onboarding Hub'),
          Tab(text: 'Portal Links'),
        ],
      ),
    );
  }

  Widget _buildDynamicList(VerificationProvider vp, Color primaryColor, ThemeData theme) {
    if (_tabController.index == 1) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildPortalCard(
                'Property Verification Portal',
                'Verify legal documents for property listings.',
                LucideIcons.shieldCheck,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVerificationScreen())),
                primaryColor,
              ),
              const SizedBox(height: 16),
              _buildPortalCard(
                'System Analytics',
                'View platform-wide growth metrics.',
                LucideIcons.barChart3,
                () {},
                Colors.teal,
              ),
            ],
          ),
        ),
      );
    }

    final requests = vp.pendingRequests;
    if (vp.isRequestsLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (requests.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text('No pending onboarding applications'),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final request = requests[index];
            return _buildRequestCard(request, vp, primaryColor, theme);
          },
          childCount: requests.length,
        ),
      ),
    );
  }

  Widget _buildRequestCard(UserProfile user, VerificationProvider vp, Color primaryColor, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryColor.withValues(alpha: 0.1),
                child: Icon(LucideIcons.user, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName ?? 'Anonymous User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(user.email, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.role.displayName.toUpperCase(), 
                  style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTag(LucideIcons.clock, 'New Application'),
              const SizedBox(width: 8),
              _buildTag(LucideIcons.calendar, '${user.yearsExperience} Years Exp'),
            ],
          ),
          if (user.governmentIdUrl != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  sl<AudioManager>().playClick(context);
                  _showDocumentDialog(context, user);
                },
                icon: const Icon(LucideIcons.fileSearch, size: 16),
                label: const Text('Review Application Documents'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    sl<AudioManager>().playClick(context);
                    vp.rejectProfessional(user.id);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    sl<AudioManager>().playSuccess(context);
                    vp.approveProfessional(user.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDocumentDialog(BuildContext context, UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Verification Documents', 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
                ],
              ),
              const SizedBox(height: 24),
              _buildDocPreview('Government ID', user.governmentIdUrl),
              const SizedBox(height: 16),
              _buildDocPreview('Broker / Professional License', user.brokerLicenseUrl),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close Preview', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocPreview(String label, String? url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: url != null 
            ? Image.network(url, height: 180, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Center(child: Text('Document Unavailable')),
                ),
              )
            : Container(
                height: 180,
                color: Colors.grey[100],
                child: const Center(child: Text('No Document Uploaded')),
              ),
        ),
      ],
    );
  }

  Widget _buildTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPortalCard(String title, String subtitle, IconData icon, VoidCallback onTap, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
