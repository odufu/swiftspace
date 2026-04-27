import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swiftspace/features/booking/domain/entities/commitment.dart';
import 'package:swiftspace/features/booking/presentation/state/booking_provider.dart';
import 'package:swiftspace/features/booking/presentation/pages/property_management_screen.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/features/negotiation/presentation/state/negotiation_provider.dart';
import 'package:swiftspace/features/booking/domain/entities/booking.dart';
import 'package:swiftspace/features/negotiation/domain/entities/negotiation.dart';
import 'package:swiftspace/features/negotiation/presentation/pages/agent_negotiation_screen.dart';
import 'package:swiftspace/core/constants/app_constants.dart';

class CrmLeadsTab extends StatefulWidget {
  const CrmLeadsTab({super.key});

  @override
  State<CrmLeadsTab> createState() => _CrmLeadsTabState();
}

class _CrmLeadsTabState extends State<CrmLeadsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CRM & Leads',
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage prospective clients and ongoing deals.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
        Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: theme.dividerColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            tabs: const [
              Tab(text: 'Inspections'),
              Tab(text: 'Offers'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLeadList(inspectionLeads, theme),
              _buildNegotiationList(context, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeadList(List<UnifiedCommitment> commitments, ThemeData theme) {
    if (commitments.isEmpty) {
      return _buildEmptyState(LucideIcons.userPlus, 'No leads found in this category.');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: commitments.length,
      itemBuilder: (context, index) {
        return _LeadCard(commitment: commitments[index]);
      },
    );
  }

  Widget _buildNegotiationList(BuildContext context, ThemeData theme) {
    final negProvider = Provider.of<NegotiationProvider>(context);
    final sessions = negProvider.sessions;

    if (sessions.isEmpty) {
      return _buildEmptyState(LucideIcons.landmark, 'No active offers found.');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        return _NegotiationCard(session: sessions[index]);
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _NegotiationCard extends StatelessWidget {
  final NegotiationSession session;

  const _NegotiationCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lastOffer = session.history.isNotEmpty ? session.history.last : null;
    final isAwaitingAgent = session.status == NegotiationStatus.clientOffer || 
                            session.status == NegotiationStatus.clientCountered;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isAwaitingAgent ? Colors.orange.withValues(alpha: 0.3) : theme.dividerColor.withValues(alpha: 0.08),
          width: isAwaitingAgent ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10, 
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            sl<AudioManager>().playClick(context);
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => AgentNegotiationScreen(sessionId: session.id),
            ));
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: session.property.imageUrl,
                    width: 72,
                    height: 72,
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
                          _buildStatusBadge(session.status),
                          if (isAwaitingAgent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                              child: const Text('ACTION REQ', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(session.property.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        lastOffer != null 
                            ? '₦${(lastOffer.amount / 1000).toStringAsFixed(0)}k • ${lastOffer.side == OfferSide.client ? 'Client' : 'You'}'
                            : 'Awaiting Offer',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(NegotiationStatus status) {
    String label;
    Color color;

    switch (status) {
      case NegotiationStatus.clientOffer:
      case NegotiationStatus.clientCountered:
        label = 'NEW OFFER';
        color = Colors.orange;
        break;
      case NegotiationStatus.agentCountered:
        label = 'PENDING';
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final UnifiedCommitment commitment;

  const _LeadCard({required this.commitment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            sl<AudioManager>().playClick(context);
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => PropertyManagementScreen(commitment: commitment, isAgent: true),
            ));
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: commitment.property.imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatus(context),
                      const SizedBox(height: 6),
                      Text(
                        commitment.property.title, 
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prospective ${commitment.type == CommitmentType.inspection ? 'Viewer' : 'Buyer'}', 
                        style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatus(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<NegotiationProvider>(
      builder: (context, negProvider, child) {
        String label = commitment.statusLabel.toUpperCase();
        Color color = theme.colorScheme.primary;
        
        if (commitment.type == CommitmentType.inspection) {
           final booking = commitment.originalObject as InspectionBooking;
           final session = negProvider.getSessionByBookingId(booking.id);
           if (session != null) {
             label = session.status == NegotiationStatus.agreed ? 'AGREED' : 'OFFER MADE';
             color = session.status == NegotiationStatus.agreed ? Colors.green : Colors.orange;
           }
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        );
      },
    );
  }
}
