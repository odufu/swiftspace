import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/commitment.dart';
import '../providers/booking_provider.dart';
import 'escrow_payment_screen.dart';
import 'property_management_screen.dart';
import '../services/audio_manager.dart';
import '../providers/negotiation_provider.dart';
import '../models/booking.dart';
import '../models/negotiation.dart';
import 'agent_negotiation_screen.dart';
class AgentHubTab extends StatefulWidget {
  const AgentHubTab({super.key});

  @override
  State<AgentHubTab> createState() => _AgentHubTabState();
}

class _AgentHubTabState extends State<AgentHubTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Seed mock negotiations for demonstration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final properties = Provider.of<BookingProvider>(context, listen: false).bookings.map((b) => b.property).toList();
      Provider.of<NegotiationProvider>(context, listen: false).seedMockNegotiations(properties);
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
    final bookingProvider = Provider.of<BookingProvider>(context);
    
    final inspectionLeads = bookingProvider.bookings.map((b) => UnifiedCommitment.fromBooking(b)).toList();
    final escrowLeads = MockEscrowStore().transactions.map((t) => UnifiedCommitment.fromEscrow(t)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Interactions & Leads', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Manage prospective clients and ongoing deals.', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.colorScheme.primary,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 24),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Inspections'),
            Tab(text: 'Escrow Deals'),
            Tab(text: 'Offers'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLeadList(inspectionLeads, theme),
              _buildLeadList(escrowLeads, theme),
              _buildNegotiationList(context, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeadList(List<UnifiedCommitment> commitments, ThemeData theme) {
    if (commitments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.userPlus, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No leads found in this category.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: commitments.length,
      itemBuilder: (context, index) {
        return LeadCommitmentCard(commitment: commitments[index], theme: theme);
      },
    );
  }

  Widget _buildNegotiationList(BuildContext context, ThemeData theme) {
    final negProvider = Provider.of<NegotiationProvider>(context);
    final sessions = negProvider.sessions;

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.landmark, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No active offers found.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        return NegotiationCard(session: sessions[index], theme: theme);
      },
    );
  }
}

class NegotiationCard extends StatelessWidget {
  final NegotiationSession session;
  final ThemeData theme;

  const NegotiationCard({super.key, required this.session, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final lastOffer = session.history.isNotEmpty ? session.history.last : null;
    final isAwaitingAgent = session.status == NegotiationStatus.clientOffer || 
                            session.status == NegotiationStatus.clientCountered;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAwaitingAgent ? Colors.orange.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
          width: isAwaitingAgent ? 2 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () {
          AudioManager().playClick(context);
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => AgentNegotiationScreen(sessionId: session.id),
          ));
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: session.property.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
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
                        _buildStatusBadge(),
                        if (isAwaitingAgent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                            child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(session.property.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      lastOffer != null 
                          ? 'Last Offer: ₦${(lastOffer.amount / 1000).toStringAsFixed(0)}k by ${lastOffer.side == OfferSide.client ? 'Client' : 'You'}'
                          : 'Awaiting Initial Offer',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    String label;
    Color color;

    switch (session.status) {
      case NegotiationStatus.clientOffer:
      case NegotiationStatus.clientCountered:
        label = 'AWAITING YOU';
        color = Colors.orange;
        break;
      case NegotiationStatus.agentCountered:
        label = 'AWAITING CLIENT';
        color = Colors.blue;
        break;
      case NegotiationStatus.agreed:
        label = 'AGREED';
        color = Colors.green;
        break;
      case NegotiationStatus.rejected:
      case NegotiationStatus.dealEnded:
        label = 'CLOSED';
        color = Colors.red;
        break;
      case NegotiationStatus.withdrawn:
        label = 'WITHDRAWN';
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class LeadCommitmentCard extends StatelessWidget {
  final UnifiedCommitment commitment;
  final ThemeData theme;

  const LeadCommitmentCard({super.key, required this.commitment, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () {
          AudioManager().playClick(context);
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => PropertyManagementScreen(commitment: commitment, isAgent: true),
          ));
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: commitment.property.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(LucideIcons.image)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<NegotiationProvider>(
                      builder: (context, negProvider, child) {
                        String label = commitment.statusLabel.toUpperCase();
                        Color color = theme.colorScheme.primary;
                        
                        if (commitment.type == CommitmentType.inspection) {
                           final booking = commitment.originalObject as InspectionBooking;
                           final session = negProvider.getSessionByBookingId(booking.id);
                           if (session != null) {
                             label = session.status == NegotiationStatus.agreed ? 'AGREED' : 'NEGOTIATING';
                             color = session.status == NegotiationStatus.agreed ? Colors.green : Colors.orange;
                           }
                        }
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(commitment.property.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Lead: Prospective ${commitment.type == CommitmentType.inspection ? 'Viewer' : 'Buyer'}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
