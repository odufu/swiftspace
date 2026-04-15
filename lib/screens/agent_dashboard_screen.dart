import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'property_onboarding_screen.dart';
import '../services/audio_manager.dart';
import '../main.dart';
import 'splash_screen.dart';
import 'escrow_payment_screen.dart';
import 'agent_hub_tab.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/property.dart';
import 'agent_property_edit_screen.dart';
import '../providers/property_provider.dart';

class AgentDashboardScreen extends StatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _DashboardOverviewTab(),
    const _MyPropertiesTab(),
    const AgentHubTab(),
    const _AgentAccountingTab(),
    const _AgentProfileTab(),
  ];

  void _onTabTapped(int index) {
    AudioManager().playClick(context);
    AudioManager().triggerHaptic(context);
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: theme.colorScheme.surface,
          items: const [
            BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard), label: 'Overview'),
            BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Properties'),
            BottomNavigationBarItem(icon: Icon(LucideIcons.users), label: 'CRM & Leads'),
            BottomNavigationBarItem(icon: Icon(LucideIcons.landmark), label: 'Accounting'),
            BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// Overview Tab
// ---------------------------------------------------------
class _DashboardOverviewTab extends StatelessWidget {
  const _DashboardOverviewTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                         Text('Agent Portal', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                         const SizedBox(width: 8),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                           decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                           child: const Text('GOLD TIER', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                         )
                      ],
                    ),
                    const Text('Welcome back, Joel', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Tier Progress Card
            Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.amber.withValues(alpha: 0.05),
                 border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                 borderRadius: BorderRadius.circular(16),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       const Text('Next Tier: Platinum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                       Text('18/25 Sales', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                     ],
                   ),
                   const SizedBox(height: 12),
                   ClipRRect(
                     borderRadius: BorderRadius.circular(4),
                     child: LinearProgressIndicator(
                       value: 18/25,
                       backgroundColor: Colors.grey.withValues(alpha: 0.2),
                       valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                       minHeight: 8,
                     ),
                   ),
                   const SizedBox(height: 8),
                   Text('Complete 7 more sales to unlock the Platinum Badge and boost buyer trust.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                 ],
               ),
            ),

            const SizedBox(height: 24),
            
            // Financial Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C3E50), Color(0xFF000000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))
                 ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Revenue & Fees Generated', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  const Text('₦5,420,000', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat('Leads Paid', '42', Colors.greenAccent),
                      _buildMiniStat('Active Deals', '8', Colors.orangeAccent),
                      _buildMiniStat('Ads Spend', '₦30k', Colors.redAccent),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Escrow Vault Summary
            const AgentEscrowSummaryCard(),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reputation & Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('View all', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
               ),
               child: Row(
                 children: [
                   Column(
                     children: [
                       const Text('4.8', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                       Row(
                         children: List.generate(5, (index) => Icon(LucideIcons.star, color: index < 4 ? Colors.amber : Colors.grey, size: 14)),
                       ),
                       const SizedBox(height: 4),
                       const Text('42 Reviews', style: TextStyle(color: Colors.grey, fontSize: 12)),
                     ],
                   ),
                   const SizedBox(width: 24),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Text('"Very professional and fast response!"', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
                         const SizedBox(height: 8),
                         Text('- Michael O.', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                       ],
                     ),
                   )
                 ],
               ),
            ),

            const SizedBox(height: 32),
            const Text('Performance Matrix', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Consumer<PropertyProvider>(
                    builder: (context, provider, _) {
                      final totalViews = provider.myProperties.fold(0, (sum, p) => sum + p.viewsCount);
                      return _buildMetricCard(context, LucideIcons.eye, 'Total Views', '${(totalViews/1000).toStringAsFixed(1)}k', '+12%', Colors.blue);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Consumer<PropertyProvider>(
                    builder: (context, provider, _) {
                      final totalInteractions = provider.myProperties.fold(0, (sum, p) => sum + p.favoritesCount + p.videoViewsCount);
                      return _buildMetricCard(context, LucideIcons.mousePointerClick, 'Interactions', '$totalInteractions', '+5%', Colors.purple);
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
                      // Heuristic for Hot Leads: Properties with high view count or those wishlisted
                      final hotLeads = provider.myProperties.fold(0, (sum, p) => sum + (p.favoritesCount > 0 ? 1 : 0));
                      return _buildMetricCard(context, LucideIcons.users, 'Saved Listings', '$hotLeads', '+8%', Colors.orange);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard(context, LucideIcons.checkCircle, 'Conversions', '18', '+2%', Colors.green)),
              ],
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, IconData icon, String title, String value, String trend, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: isDark ? 0.2 : 0.1)),
        boxShadow: [
           BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(trend, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// Properties Tab
// ---------------------------------------------------------
class _MyPropertiesTab extends StatelessWidget {
  const _MyPropertiesTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(LucideIcons.filter), onPressed: (){}),
        ],
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, provider, child) {
          final properties = provider.myProperties;
          if (properties.isEmpty) {
            return const Center(child: Text('No properties listed yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final p = properties[index];
              return _buildPropertyItem(context, p);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AudioManager().playClick(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PropertyOnboardingScreen()));
        },
        icon: const Icon(LucideIcons.plus),
        label: const Text('Add Property', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPropertyItem(BuildContext context, Property p) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = p.isActive ? Colors.green : Colors.grey;
    final status = p.isActive ? 'Active' : 'Off Market';

    return GestureDetector(
      onTap: () {
        AudioManager().playClick(context);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AgentPropertyEditScreen(propertyId: p.id),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(p.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        children: [
                          Icon(LucideIcons.eye, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${p.viewsCount}', style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Icon(LucideIcons.heart, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${p.favoritesCount}', style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Icon(LucideIcons.moreVertical, size: 16, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(p.formattedPrice, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _AgentAccountingTab extends StatefulWidget {
  const _AgentAccountingTab();

  @override
  State<_AgentAccountingTab> createState() => _AgentAccountingTabState();
}

class _AgentAccountingTabState extends State<_AgentAccountingTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final transactions = MockEscrowStore().transactions;
    
    // Calculate Stats
    final totalEarnings = transactions.where((t) => t.state == EscrowState.released).fold<double>(0, (sum, t) => sum + t.amount);
    final pendingEscrow = transactions.where((t) => t.state == EscrowState.held || t.state == EscrowState.inspectionPassed).fold<double>(0, (sum, t) => sum + t.amount);
    final overdueCount = transactions.where((t) => t.state == EscrowState.overdue).length;

    String fmt(double v) {
      if (v >= 1000000) return '₦${(v / 1000000).toStringAsFixed(1)}M';
      if (v >= 1000) return '₦${(v / 1000).toStringAsFixed(0)}k';
      return '₦${v.toStringAsFixed(0)}';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounting & Finances', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Top Stats Row
          Row(
            children: [
              Expanded(child: _buildValueCard('Total Earnings', fmt(totalEarnings), Colors.green, LucideIcons.trendingUp)),
              const SizedBox(width: 16),
              Expanded(child: _buildValueCard('In Escrow', fmt(pendingEscrow), Colors.orange, LucideIcons.lock)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Overdue Check Section
          if (overdueCount > 0)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, color: Colors.red),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Overdue Payments Detected', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        Text('$overdueCount client(s) have defaulted on installments.', style: const TextStyle(fontSize: 12, color: Colors.red)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      AudioManager().playSuccess(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Automated reminders sent to defaulting clients!'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    child: const Text('Send Reminders', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          const Text('Financial Documents (Invoices/Receipts)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // List of Invoices extracted from all transactions
          ...transactions.expand((tx) => tx.invoices.map((inv) => _buildInvoiceItem(theme, isDark, inv, tx))),
          
          if (transactions.expand((t) => t.invoices).isEmpty)
             _buildEmptyAccounting(theme),

          const SizedBox(height: 32),
          const Text('Upcoming Installments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // List of Installments
          ...transactions.expand((tx) => tx.installments.where((i) => !i.isPaid).map((inst) => _buildInstallmentItem(theme, isDark, inst, tx))),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildValueCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(ThemeData theme, bool isDark, AccountInvoice inv, EscrowTransaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: (inv.type == 'Receipt' ? Colors.green : Colors.blue).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(inv.type == 'Receipt' ? LucideIcons.checkCircle : LucideIcons.fileText, color: inv.type == 'Receipt' ? Colors.green : Colors.blue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${inv.type} #${inv.id.split('-').last}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(tx.propertyTitle, style: TextStyle(color: Colors.grey[600], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₦${inv.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${inv.date.day}/${inv.date.month}/${inv.date.year}', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(LucideIcons.moreVertical, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildInstallmentItem(ThemeData theme, bool isDark, EscrowInstallment inst, EscrowTransaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: inst.isOverdue ? Colors.red.withValues(alpha: 0.05) : (isDark ? Colors.grey[900] : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: inst.isOverdue ? Colors.red.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inst.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Client: ${tx.clientName}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₦${inst.amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: inst.isOverdue ? Colors.red : null)),
              Text(inst.isOverdue ? 'OVERDUE' : 'Due: ${inst.dueDate.day}/${inst.dueDate.month}', style: TextStyle(color: inst.isOverdue ? Colors.red : Colors.grey[500], fontSize: 11, fontWeight: inst.isOverdue ? FontWeight.bold : null)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAccounting(ThemeData theme) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(children: [
        Icon(LucideIcons.folderOpen, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 12),
        const Text('No financial history yet', style: TextStyle(color: Colors.grey)),
      ]),
    ));
  }
}

// ---------------------------------------------------------
// Agent Profile Tab
// ---------------------------------------------------------
class _AgentProfileTab extends StatelessWidget {
  const _AgentProfileTab();

  void _logout(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber, width: 3),
                        image: const DecorationImage(
                          image: NetworkImage('https://i.pravatar.cc/150?img=11'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Joel Developer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Text('GOLD BROKER', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 48),

              const Text('Ecosystem Sync', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              _buildActionTile(
                context: context,
                title: 'Switch to User Mode',
                subtitle: 'Explore properties as a buyer/renter',
                icon: LucideIcons.repeat,
                color: theme.colorScheme.primary,
                onTap: () {
                  AudioManager().playClick(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainLayout()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 24),

              const Text('Agent Preferences', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              _buildActionTile(
                context: context,
                title: 'Payout Methods',
                subtitle: 'Manage bank accounts and wallets',
                icon: LucideIcons.creditCard,
                color: Colors.green,
                onTap: () {},
              ),
              
              const SizedBox(height: 24),
              const Text('Danger Zone', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              _buildActionTile(
                context: context,
                title: 'Logout',
                subtitle: 'Sign out of your agent account safely',
                icon: LucideIcons.logOut,
                color: Colors.red,
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({required BuildContext context, required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
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

