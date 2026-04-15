import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:swiftspace/features/booking/domain/entities/commitment.dart';
import 'package:swiftspace/features/booking/domain/entities/booking.dart';
import 'package:swiftspace/features/booking/presentation/state/booking_provider.dart';
import 'package:swiftspace/features/chat/presentation/state/chat_provider.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/features/payment/presentation/pages/escrow_payment_screen.dart';
import 'package:swiftspace/features/media_ai/presentation/pages/video_player_screen.dart';
import 'package:swiftspace/features/media_ai/presentation/pages/virtual_walkthrough_screen.dart';
import 'package:swiftspace/features/chat/presentation/pages/chat_detail_screen.dart';
import 'package:swiftspace/shared/widgets/inspection_date_picker.dart';
import 'package:swiftspace/features/negotiation/presentation/state/negotiation_provider.dart';
import 'package:swiftspace/features/negotiation/presentation/pages/agent_negotiation_screen.dart';
import 'package:swiftspace/features/negotiation/presentation/pages/negotiation_screen.dart';
import 'package:swiftspace/features/negotiation/presentation/pages/rental_agreement_screen.dart';
import 'package:swiftspace/features/negotiation/domain/entities/negotiation.dart';

class PropertyManagementScreen extends StatefulWidget {
  final UnifiedCommitment commitment;
  final bool isAgent;

  const PropertyManagementScreen({
    super.key, 
    required this.commitment,
    this.isAgent = false,
  });

  @override
  State<PropertyManagementScreen> createState() => _PropertyManagementScreenState();
}

class _PropertyManagementScreenState extends State<PropertyManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isOwnershipTransferred = false;
  bool _isLeaseSigned = false;
  bool _isPaid = false;
  bool _isMovedIn = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize chat room safely after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ChatProvider>(context, listen: false).createRoom(
          widget.commitment.id, 
          widget.commitment.property.title, 
          widget.commitment.property.imageUrl, 
          widget.commitment.property.listerName,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openMap() async {
    final lat = widget.commitment.property.location.latitude;
    final lng = widget.commitment.property.location.longitude;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
       await launchUrl(url);
    }
  }

  void _shareLocation() {
    Share.share('Check out this property location: https://www.google.com/maps/search/?api=1&query=${widget.commitment.property.location.latitude},${widget.commitment.property.location.longitude}');
  }

  void _confirmMoveIn() async {
    AudioManager().playSuccess(context);
    setState(() => _isMovedIn = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Possession confirmed! Welcome home.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.commitment.property.title, 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, shadows: [Shadow(blurRadius: 10, color: Colors.black45)])),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(widget.commitment.property.imageUrl, fit: BoxFit.cover),
                  Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black38, Colors.transparent, Colors.black87]))),
                  Center(
                    child: IconButton(
                      icon: const Icon(LucideIcons.playCircle, size: 64, color: Colors.white),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoUrl: widget.commitment.property.videoUrl ?? ''))),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(icon: const Icon(LucideIcons.share2), onPressed: _shareLocation),
              IconButton(icon: const Icon(LucideIcons.map), onPressed: _openMap),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: theme.colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Summary'),
                  Tab(text: 'Chat'),
                  Tab(text: 'Financials'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSummaryTab(theme, isDark),
            _buildChatTab(),
            _buildFinancialsTab(theme, isDark),
          ],
        ),
      ),
      bottomNavigationBar: _buildContextualActionButton(theme),
    );
  }

  Widget _buildSummaryTab(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildWorkflowGuide(theme),
        const SizedBox(height: 24),
        _buildStatusCard(theme),
        if (widget.isAgent) ...[
          const SizedBox(height: 24),
          _buildEngagementInsights(theme),
        ],
        const SizedBox(height: 24),
        const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        Row(
          children: [
            _actionTile(LucideIcons.navigation, 'Directions', _openMap, theme),
            const SizedBox(width: 12),
            _actionTile(LucideIcons.view, '360 Tour', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VirtualWalkthroughScreen())), theme),
            const SizedBox(width: 12),
            _actionTile(LucideIcons.fileText, 'Docs', () {}, theme),
          ],
        ),
        const SizedBox(height: 32),
        const Text('Property Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        _buildPreparationChecklist(theme),
        const SizedBox(height: 24),
        Text(widget.commitment.property.description, style: TextStyle(color: Colors.grey[600], height: 1.5)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.commitment.property.amenities.map((f) => Chip(
            label: Text(f, style: const TextStyle(fontSize: 12)),
            backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
            side: BorderSide.none,
          )).toList(),
        ),
        const SizedBox(height: 40),
        _buildSimulationShortcuts(theme),
      ],
    );
  }

  Widget _buildWorkflowGuide(ThemeData theme) {
    final booking = widget.commitment.originalObject is InspectionBooking 
        ? widget.commitment.originalObject as InspectionBooking 
        : null;
    
    if (booking == null) return const SizedBox.shrink();

    final negProvider = Provider.of<NegotiationProvider>(context, listen: false);
    final session = negProvider.getSessionByBookingId(booking.id);

    int currentStage = 0;
    if (booking.status == BookingStatus.completed) {
      currentStage = 1; // Negotiate
      if (session != null && session.status == NegotiationStatus.agreed) {
        currentStage = 2; // Sign
        if (_isLeaseSigned) {
          currentStage = 3; // Pay
          if (_isMovedIn) currentStage = 4;
        }
      }
    }

    final List<Map<String, dynamic>> stages = [
      {'label': 'Visit', 'icon': LucideIcons.calendar},
      {'label': 'Negotiate', 'icon': LucideIcons.messageSquare},
      {'label': 'Sign', 'icon': LucideIcons.penTool},
      {'label': 'Pay', 'icon': LucideIcons.creditCard},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DEAL PROGRESS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(stages.length, (index) {
            final isCompleted = index < currentStage;
            final isCurrent = index == currentStage;
            final color = isCompleted ? Colors.green : (isCurrent ? theme.colorScheme.primary : Colors.grey[300]);
            
            return Expanded(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color!.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 2),
                        ),
                        child: Icon(stages[index]['icon'], size: 16, color: color),
                      ),
                      const SizedBox(height: 4),
                      Text(stages[index]['label'], style: TextStyle(fontSize: 10, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: isCurrent ? Colors.black : Colors.grey)),
                    ],
                  ),
                  if (index < stages.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        color: isCompleted ? Colors.green : Colors.grey[200],
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSimulationShortcuts(ThemeData theme) {
     return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.flaskConical, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text('Quest Simulation (Dev Tool)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          _simButton('Skip to Negotiation', () {
             final booking = widget.commitment.originalObject as InspectionBooking;
             Provider.of<BookingProvider>(context, listen: false).finalizeInspection(booking.id, 'Simulated finalization.');
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status set to Finalized (Ready to Approve)')));
          }, theme),
          const SizedBox(height: 12),
          _simButton('Skip to Agreement', () {
             final booking = widget.commitment.originalObject as InspectionBooking;
             Provider.of<BookingProvider>(context, listen: false).rateAgent(booking.id, 5, 'Auto-approved.');
             final negProvider = Provider.of<NegotiationProvider>(context, listen: false);
             if (negProvider.getSessionByBookingId(booking.id) == null) {
                negProvider.startNegotiation(booking.id, booking.property, booking.property.price);
             }
             final session = negProvider.getSessionByBookingId(booking.id)!;
             final offer = NegotiationOffer(
                id: 'SIM-${DateTime.now().millisecondsSinceEpoch}',
                side: OfferSide.agent,
                amount: booking.property.price,
                message: 'Agreed!',
                timestamp: DateTime.now(),
             );
             
             // Ensure history is mutable and add the offer
             final updatedHistory = List<NegotiationOffer>.from(session.history)..add(offer);
             negProvider.updateSession(session.id, status: NegotiationStatus.agreed, history: updatedHistory);
             
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Negotiation Agreed (Ready to Sign)')));
          }, theme),
        ],
      ),
    );
  }

  Widget _simButton(String label, VoidCallback onPressed, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.amber[800],
          side: BorderSide(color: Colors.amber.withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap, ThemeData theme) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 24),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.commitment.statusLabel, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
              if (widget.commitment.property.priceTerm != 'buy' && widget.commitment.dueDate != null)
                _buildCountdownBadge(theme),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: widget.commitment.progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text('Next Action: ${widget.commitment.nextActionLabel}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEngagementInsights(ThemeData theme) {
    final p = widget.commitment.property;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.barChart3, size: 18, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              const Text('Property Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(LucideIcons.eye, '${p.viewsCount}', 'Views', theme),
              _buildMetricItem(LucideIcons.heart, '${p.favoritesCount}', 'Saves', theme),
              _buildMetricItem(LucideIcons.playCircle, '${p.videoViewsCount}', 'Video', theme),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This property has ${p.viewsCount} views. This specific lead represents ${p.viewsCount > 0 ? ((1 / p.viewsCount) * 100).toStringAsFixed(1) : '0'}% of your reached audience.',
            style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String value, String label, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.secondary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildCountdownBadge(ThemeData theme) {
    if (widget.commitment.dueDate == null) return const SizedBox.shrink();
    final diff = widget.commitment.dueDate!.difference(DateTime.now());
    final days = diff.inDays;
    final isOverdue = diff.isNegative;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.clock, size: 12, color: isOverdue ? Colors.red : Colors.orange),
          const SizedBox(width: 6),
          Text(
            isOverdue ? 'Overdue!' : 'Due in $days days',
            style: TextStyle(color: isOverdue ? Colors.red : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPreparationChecklist(ThemeData theme) {
    if (widget.commitment.checklist.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.listChecks, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Preparation Checklist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.commitment.checklist.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  item.isDone ? LucideIcons.checkCircle2 : LucideIcons.circle,
                  size: 16,
                  color: item.isDone ? Colors.green : Colors.grey[400],
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    color: item.isDone ? Colors.grey : null,
                    decoration: item.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    final chatProvider = Provider.of<ChatProvider>(context);
    final room = chatProvider.getRoomByProperty(widget.commitment.id);
    
    if (room == null) return const Center(child: Text('Initializing chat...'));
    return ChatDetailScreen(roomId: room.id);
  }

  Widget _buildFinancialsTab(ThemeData theme, bool isDark) {
    if (widget.commitment.type == CommitmentType.inspection) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.lock, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Financial records available after deal initiation.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final tx = widget.commitment.originalObject as EscrowTransaction;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Installment Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 20),
        ...tx.installments.map((inst) => _buildInstallmentTile(inst, theme, tx.id)),
        const SizedBox(height: 32),
        const Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        ...tx.invoices.map((inv) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(inv.type == 'Receipt' ? LucideIcons.checkCircle : LucideIcons.fileText, color: inv.type == 'Receipt' ? Colors.green : Colors.blue),
          title: Text('${inv.type} #${inv.id.split('-').last}'),
          subtitle: Text('${inv.date.day}/${inv.date.month}/${inv.date.year} • ₦${inv.amount.toStringAsFixed(0)}'),
          trailing: const Icon(LucideIcons.download, size: 18),
        )),
      ],
    );
  }

  Widget _buildInstallmentTile(EscrowInstallment inst, ThemeData theme, String txId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: inst.isPaid ? Colors.green.withOpacity(0.2) : (inst.isOverdue ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Icon(inst.isPaid ? LucideIcons.checkCircle2 : (inst.isOverdue ? LucideIcons.alertTriangle : LucideIcons.circle), 
            color: inst.isPaid ? Colors.green : (inst.isOverdue ? Colors.red : Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inst.title, style: TextStyle(fontWeight: FontWeight.bold, decoration: inst.isPaid ? TextDecoration.lineThrough : null)),
                Text('Due: ${inst.dueDate.day}/${inst.dueDate.month}/${inst.dueDate.year}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Text('₦${(inst.amount / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget? _buildContextualActionButton(ThemeData theme) {
    if (widget.isAgent) {
      return _buildAgentActionButtons(theme);
    }
    if (_isOwnershipTransferred) return null;

    String label = 'Next Action';
    VoidCallback? action;
    Color color = theme.colorScheme.primary;

    if (widget.commitment.type == CommitmentType.inspection) {
      final booking = widget.commitment.originalObject as InspectionBooking;
      if (booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed || booking.status == BookingStatus.postponed) {
        label = 'Reschedule Appointment';
        action = () async {
          final newDate = await showModalBottomSheet<DateTime>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => InspectionDatePicker(property: booking.property));
          if (newDate != null) {
            if (!mounted) return;
            Provider.of<BookingProvider>(context, listen: false).postponeBooking(booking.id, newDate, 'Client rescheduled via Management Hub.');
            setState(() {});
          }
        };
      } else if (booking.status == BookingStatus.finalized) {
        label = 'Finalize & Approve Visit';
        action = () => _showHandoverSheet(booking);
      } else if (booking.status == BookingStatus.completed) {
        final negProvider = Provider.of<NegotiationProvider>(context, listen: false);
        final session = negProvider.getSessionByBookingId(booking.id);
        
        if (session != null && session.status == NegotiationStatus.agreed) {
          if (_isMovedIn) {
            label = 'Deal Completed';
            color = Colors.grey;
            action = null;
          } else if (_isPaid) {
            label = 'Confirm Possession';
            color = Colors.green;
            action = () => _confirmMoveIn();
          } else if (_isLeaseSigned) {
            label = 'Setup Rent Circle & Pay';
            color = theme.colorScheme.primary;
            action = () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EscrowPaymentScreen(
                    propertyTitle: booking.property.title,
                    location: booking.property.locationName,
                    propertyImage: booking.property.imageUrl,
                    amount: session.history.last.amount,
                    dealType: 'Initial Rent Security',
                  ),
                ),
              );
              if (result == true) {
                if (!mounted) return;
                setState(() => _isPaid = true);
                AudioManager().playSuccess(context);
              }
            };
          } else {
            label = 'Sign Tenancy Agreement';
            color = Colors.indigo;
            action = () async {
              final signed = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => RentalAgreementScreen(
                  property: booking.property, 
                  negotiatedPrice: session.history.last.amount,
                ))
              );
              if (signed == true) {
                setState(() => _isLeaseSigned = true);
              }
            };
          }
        } else {
          label = 'Make an Offer';
          color = Colors.orange;
          action = () {
            final existingSession = negProvider.getSessionByBookingId(booking.id);
            if (existingSession == null) {
              final newSession = negProvider.startNegotiation(booking.id, booking.property, booking.property.price);
              Navigator.push(context, MaterialPageRoute(builder: (_) => NegotiationScreen(sessionId: newSession.id)));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => NegotiationScreen(sessionId: existingSession.id)));
            }
          };
        }
      }
    } else {
      final tx = widget.commitment.originalObject as EscrowTransaction;
      if (tx.state == EscrowState.overdue) {
        label = 'Settle Overdue Payment';
        color = Colors.red;
        action = () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => EscrowPaymentScreen(propertyTitle: tx.propertyTitle, location: tx.location, propertyImage: tx.propertyImage, amount: tx.installments.firstWhere((i) => !i.isPaid).amount, dealType: 'Outstanding Balance')));
          if (result == true) {
             if (!mounted) return;
             MockEscrowStore().payInstallment(tx.id, tx.installments.firstWhere((i) => !i.isPaid).id);
             setState(() {});
          }
        };
      } else if (tx.state == EscrowState.released) {
        label = 'Transfer Ownership';
        color = Colors.indigo;
        action = _simulateTransferOwnership;
      } else if (tx.state == EscrowState.inspectionPassed) {
        label = 'Proceed to Final Deposit';
        action = () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => EscrowPaymentScreen(propertyTitle: tx.propertyTitle, location: tx.location, propertyImage: tx.propertyImage, amount: tx.amount * 0.3, dealType: 'Final Settlement')));
          if (result == true) {
            if (!mounted) return;
            tx.state = EscrowState.released;
            setState(() {});
          }
        };
      }
    }

    if (action == null && widget.commitment.progress < 1.0) return null;
    
    // Fallback prompt if waiting for status change
    if (action == null) {
       return Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Icon(LucideIcons.clock, color: Colors.grey[400], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.isAgent 
                  ? 'Awaiting client response.' 
                  : 'Awaiting agent action to proceed to the next stage.',
                style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.transparent,
      child: ElevatedButton(
        onPressed: action,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: color.withOpacity(0.4),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  void _simulateTransferOwnership() {
    AudioManager().playSuccess(context);
    setState(() => _isMovedIn = true);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transfer Ownership?'),
        content: const Text('You have fully paid for this property. Would you like to initiate the digital title transfer and generate your certificate of ownership?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Maybe Later')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showTransferSuccess();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            child: const Text('Initiate Transfer'),
          ),
        ],
      ),
    );
  }

  void _showTransferSuccess() {
    AudioManager().playSuccess(context);
    setState(() => _isOwnershipTransferred = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.shieldCheck, size: 80, color: Colors.indigo),
            const SizedBox(height: 24),
            const Text('Ownership Transferred!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 12),
            const Text('Your digital title has been secured on the blockchain, and your certificate of ownership is being generated.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 15)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(LucideIcons.download),
              label: const Text('Download Certificate'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showHandoverSheet(InspectionBooking booking) {
    int currentRating = 5;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final theme = Theme.of(context);
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.sparkles, size: 64, color: Colors.amber),
                const SizedBox(height: 24),
                const Text('Inspection Successful!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('How was your experience with the agent?', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < currentRating ? LucideIcons.star : LucideIcons.star,
                        color: index < currentRating ? Colors.amber : Colors.grey[300],
                        size: 40,
                      ),
                      onPressed: () {
                        setSheetState(() => currentRating = index + 1);
                      },
                    );
                  }),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Approve and transition
                    Provider.of<BookingProvider>(context, listen: false)
                        .rateAgent(booking.id, currentRating, 'Inspection Completed Successfully.');
                    AudioManager().playSuccess(context);
                    Navigator.pop(ctx);
                    setState((){});
                    
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (!mounted) return;
                      final negProvider = Provider.of<NegotiationProvider>(context, listen: false);
                      final existingSession = negProvider.getSessionByBookingId(booking.id);
                      if (existingSession == null) {
                        final newSession = negProvider.startNegotiation(booking.id, booking.property, booking.property.price);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => NegotiationScreen(sessionId: newSession.id)));
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => NegotiationScreen(sessionId: existingSession.id)));
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Make an Offer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                     Provider.of<BookingProvider>(context, listen: false)
                        .rateAgent(booking.id, currentRating, 'Inspection Completed Successfully.');
                     AudioManager().playSuccess(context);
                     Navigator.pop(ctx);
                     setState((){});
                  },
                  child: const Text('Skip for now', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildAgentActionButtons(ThemeData theme) {
    if (widget.commitment.type != CommitmentType.inspection) {
      return const SizedBox.shrink(); // Assuming escrow has its own flow or similar fallback
    }
    
    final booking = widget.commitment.originalObject as InspectionBooking;
    
    String actionLabel = 'Confirm Action';
    IconData actionIcon = LucideIcons.checkCircle;
    Color actionColor = theme.colorScheme.primary;
    VoidCallback? onAction;
    
    // Determine the dynamic action based on booking status
    switch (booking.status) {
      case BookingStatus.pending:
        actionLabel = 'Accept Booking';
        onAction = () {
          Provider.of<BookingProvider>(context, listen: false).updateBookingStatus(booking.id, BookingStatus.confirmed);
        };
        break;
      case BookingStatus.confirmed:
      case BookingStatus.postponed:
        actionLabel = 'Commence Inspection';
        onAction = () {
          Provider.of<BookingProvider>(context, listen: false).updateBookingStatus(booking.id, BookingStatus.commenced);
        };
        break;
      case BookingStatus.commenced:
        actionLabel = 'Finalize Inspection';
        onAction = () {
          // Provide a simple finalize call. In a real app this might prompt for notes.
          Provider.of<BookingProvider>(context, listen: false).finalizeInspection(booking.id, 'Inspection successfully completed by agent.');
        };
        break;
      case BookingStatus.completed:
        actionLabel = 'View Offer';
        actionIcon = LucideIcons.messageSquare;
        actionColor = Colors.orange;
        onAction = () {
          final negProvider = Provider.of<NegotiationProvider>(context, listen: false);
          final session = negProvider.getSessionByBookingId(booking.id);
          if (session != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AgentNegotiationScreen(sessionId: session.id)));
          } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Awaiting client offer.')));
          }
        };
        break;
      case BookingStatus.finalized:
        return Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(color: theme.colorScheme.surface),
          child: const Text('Awaiting client approval and review.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        );
      case BookingStatus.declined:
      case BookingStatus.cancelled:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          // Decline / Cancel Button
          if (booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  AudioManager().playClick(context);
                  Provider.of<BookingProvider>(context, listen: false).updateBookingStatus(booking.id, BookingStatus.declined);
                  Navigator.pop(context);
                },
                icon: const Icon(LucideIcons.xCircle, size: 18),
                label: const Text('Decline'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed)
            const SizedBox(width: 16),
            
          // Primary Action Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                AudioManager().playSuccess(context);
                onAction?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$actionLabel initiated.')),
                );
              },
              icon: Icon(actionIcon, size: 18),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
