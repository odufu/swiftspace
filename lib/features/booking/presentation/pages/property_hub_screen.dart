import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/features/booking/presentation/state/booking_provider.dart';
import 'package:swiftspace/features/booking/domain/entities/booking.dart';
import 'package:swiftspace/features/booking/domain/entities/commitment.dart';
import 'package:swiftspace/features/payment/presentation/pages/escrow_payment_screen.dart';
import 'package:swiftspace/features/chat/presentation/pages/chat_list_screen.dart';
import 'package:swiftspace/features/booking/presentation/pages/property_management_screen.dart';
import 'package:swiftspace/core/utils/responsive.dart';

// -------------------------------------------------------
// Main Property Hub Screen
// -------------------------------------------------------
class PropertyHubScreen extends StatefulWidget {
  const PropertyHubScreen({super.key});

  @override
  State<PropertyHubScreen> createState() => _PropertyHubScreenState();
}

class _PropertyHubScreenState extends State<PropertyHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = ['Active Hub', 'History'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
    final escrowTx = MockEscrowStore().transactions;
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Property Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: false,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.messageSquare),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Active Hub'),
              Tab(text: 'History'),
            ],
            onTap: (_) => sl<AudioManager>().playClick(context),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? 800 : 1200),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildActiveTab(escrowTx, isDark, theme),
              _buildHistoryTab(escrowTx, isDark, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTab(List<EscrowTransaction> escrowTx, bool isDark, ThemeData theme) {
    final bookings = Provider.of<BookingProvider>(context).bookings;
    final activeBookings = bookings.where((b) => b.status != BookingStatus.completed && b.status != BookingStatus.cancelled).toList();
    final activeEscrow = escrowTx.where((tx) => tx.state != EscrowState.released && tx.state != EscrowState.refunded).toList();

    final List<UnifiedCommitment> commitments = [
      ...activeBookings.map((b) => UnifiedCommitment.fromBooking(b)),
      ...activeEscrow.map((tx) => UnifiedCommitment.fromEscrow(tx)),
    ];

    if (commitments.isEmpty) return _buildEmptyState(theme, icon: LucideIcons.layoutDashboard, message: 'Your property journey starts here.\nEverything you commit to will appear in this hub.');

    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : (isMobile ? 1 : 2),
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        mainAxisExtent: 220,
      ),
      itemCount: commitments.length,
      itemBuilder: (context, index) => _PropertyCommitmentCard(commitment: commitments[index], isDark: isDark, theme: theme),
    );
  }

  Widget _buildHistoryTab(List<EscrowTransaction> escrowTx, bool isDark, ThemeData theme) {
    final bookings = Provider.of<BookingProvider>(context).bookings;
    final pastBookings = bookings.where((b) => b.status == BookingStatus.completed || b.status == BookingStatus.cancelled).toList();
    final closedEscrow = escrowTx.where((tx) => tx.state == EscrowState.released || tx.state == EscrowState.refunded).toList();

    final List<UnifiedCommitment> history = [
      ...pastBookings.map((b) => UnifiedCommitment.fromBooking(b)),
      ...closedEscrow.map((tx) => UnifiedCommitment.fromEscrow(tx)),
    ];

    if (history.isEmpty) return _buildEmptyState(theme, icon: LucideIcons.history, message: 'No closed deals or past visits yet.');

    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : (isMobile ? 1 : 2),
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        mainAxisExtent: 220,
      ),
      itemCount: history.length,
      itemBuilder: (context, index) => _PropertyCommitmentCard(commitment: history[index], isDark: isDark, theme: theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme, {IconData? icon, String? message}) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon ?? LucideIcons.clipboardList, size: 64, color: Colors.grey[400]),
      const SizedBox(height: 16),
      Text('No activity here yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
      const SizedBox(height: 8),
      Text(message ?? 'Properties you interact with financially\nwill appear here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500])),
    ]));
  }
}

// -------------------------------------------------------
// Uniform Property Commitment Card
// -------------------------------------------------------
class _PropertyCommitmentCard extends StatelessWidget {
  final UnifiedCommitment commitment;
  final bool isDark;
  final ThemeData theme;

  const _PropertyCommitmentCard({required this.commitment, required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () {
          sl<AudioManager>().playClick(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyManagementScreen(commitment: commitment)));
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CachedNetworkImage(
                    imageUrl: commitment.property.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20)),
                    child: Text(commitment.statusLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(commitment.property.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(LucideIcons.mapPin, size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(commitment.property.locationName, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(commitment.nextActionLabel, style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey[400]),
                    ],
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
