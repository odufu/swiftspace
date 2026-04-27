import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/core/constants/app_constants.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/di/injection_container.dart';

class AccountingTab extends StatefulWidget {
  const AccountingTab({super.key});

  @override
  State<AccountingTab> createState() => _AccountingTabState();
}

class _AccountingTabState extends State<AccountingTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
        children: [
          const Text(
            'Billing & Subscription',
            style: TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your professional plan and view billing history.',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Current Plan Card (Premium Glassmorphism)
          _buildCurrentPlanCard(theme, isDark),
          
          const SizedBox(height: 32),

          const Text(
            'Listing Capacity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          
          _buildUsageTracker(theme, isDark),

          const SizedBox(height: 32),
          
          const Text(
            'Billing History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),

          // Mock Billing History
          _buildBillingItem(theme, isDark, 'INV-8821', 'Elite Professional - Monthly', '₦25,000', 'Paid', 'Apr 12, 2024'),
          _buildBillingItem(theme, isDark, 'INV-7710', 'Elite Professional - Monthly', '₦25,000', 'Paid', 'Mar 12, 2024'),
          _buildBillingItem(theme, isDark, 'INV-6604', 'Professional Tier - Monthly', '₦15,000', 'Paid', 'Feb 12, 2024'),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, const Color(0xFF072D20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.crown, color: Colors.amber, size: 14),
                    SizedBox(width: 8),
                    Text(
                      'ELITE PROFESSIONAL',
                      style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.moreHorizontal, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '₦25,000',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const Text(
            'Billed monthly • Next: May 12, 2024',
            style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 32),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 20),
          _buildBenefitRow('Unlimited Verified Listings', true),
          _buildBenefitRow('Priority Search Placement', true),
          _buildBenefitRow('AI Description Optimizer', true),
          _buildBenefitRow('360 Virtual Tour Hosting', true),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(String text, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(LucideIcons.checkCircle2, color: active ? AppColors.primaryLight : Colors.white24, size: 16),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : Colors.white38,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageTracker(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Listings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                '8 / 10 Active',
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.8,
            backgroundColor: theme.dividerColor.withValues(alpha: 0.05),
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Text(
            'You are at 80% capacity. Upgrade to Elite for unlimited listings.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingItem(ThemeData theme, bool isDark, String id, String plan, String amount, String status, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(LucideIcons.fileText, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  'Invoice $id • $date',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.2),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('PAID', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
