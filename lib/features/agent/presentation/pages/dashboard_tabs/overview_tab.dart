import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:swiftspace/core/constants/app_constants.dart';
import 'package:swiftspace/features/auth/presentation/state/auth_provider.dart';
import 'package:swiftspace/features/property/presentation/state/property_provider.dart';
import 'package:swiftspace/features/property/presentation/state/property_provider.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.profile;
    final roleName = profile?.role.portalName ?? 'Professional Suite';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Branded Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          roleName.toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'GOLD TIER',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome, ${profile?.fullName?.split(' ').first ?? 'User'}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    // Quick profile access
                  },
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage: profile?.avatarUrl != null 
                        ? NetworkImage(profile!.avatarUrl!) 
                        : null,
                    child: profile?.avatarUrl == null 
                        ? Icon(LucideIcons.user, color: theme.colorScheme.primary) 
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Branded Tier Progress Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Next Milestone: Elite Status',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '18 / 25 Sales',
                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    children: [
                      Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(seconds: 1),
                        height: 10,
                        width: (MediaQuery.of(context).size.width - 80) * (18/25),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primaryLight, AppColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Complete 7 more verified deals to unlock premium visibility tools.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Branded Revenue Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryLight, Color(0xFF072D20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.wallet, color: Colors.white.withValues(alpha: 0.6), size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'PORTFOLIO MARKET VALUE',
                        style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '₦5,420,000',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat('Active Leads', '42', Colors.greenAccent),
                      _buildMiniStat('Inquiries', '128', Colors.orangeAccent),
                      _buildMiniStat('Response Rate', '94%', Colors.blueAccent),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            
            // Interaction summary
            const SizedBox(height: 8),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reputation Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                TextButton(
                  onPressed: () {},
                  child: Text('Performance History', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildReputationCard(context, isDark),

            const SizedBox(height: 32),
            const Text('Performance Matrix', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Consumer<PropertyProvider>(
                    builder: (context, provider, _) {
                      final totalViews = provider.myProperties.fold(0, (sum, p) => sum + p.viewsCount);
                      return _buildMetricCard(
                        context, LucideIcons.eye, 'Total Views', 
                        '${(totalViews / 1000).toStringAsFixed(1)}k', '+12%', Colors.blue);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Consumer<PropertyProvider>(
                    builder: (context, provider, _) {
                      final totalInteractions = provider.myProperties.fold(0, (sum, p) => sum + p.favoritesCount + p.videoViewsCount);
                      return _buildMetricCard(
                        context, LucideIcons.mousePointerClick, 'Interactions', 
                        '$totalInteractions', '+5%', Colors.purple);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Consumer<PropertyProvider>(
                    builder: (context, provider, _) {
                      final hotLeads = provider.myProperties.fold(0, (sum, p) => sum + (p.favoritesCount > 0 ? 1 : 0));
                      return _buildMetricCard(
                        context, LucideIcons.users, 'Saved Listings', 
                        '$hotLeads', '+8%', Colors.orange);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    context, LucideIcons.checkCircle, 'Conversions', '18', '+2%', Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, IconData icon, String title, String value, String trend, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: isDark ? 0.2 : 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(trend, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildReputationCard(BuildContext context, bool isDark) {
     return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              const Text('4.8', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
              Row(
                children: List.generate(5, (index) => Icon(
                  LucideIcons.star, 
                  color: index < 4 ? Colors.amber : Colors.grey[300], 
                  size: 14,
                  fill: index < 4 ? 1.0 : 0.0,
                )),
              ),
              const SizedBox(height: 6),
              const Text('42 Reviews', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.quote, color: Colors.grey, size: 16),
                const SizedBox(height: 8),
                const Text(
                  '"Very professional and fast response!"',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                Text(
                  '— MICHAEL O.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
