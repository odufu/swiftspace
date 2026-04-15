import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/features/negotiation/domain/entities/negotiation.dart';
import 'package:swiftspace/features/negotiation/presentation/state/negotiation_provider.dart';
import 'package:intl/intl.dart';

class AgentNegotiationScreen extends StatefulWidget {
  final String sessionId;

  const AgentNegotiationScreen({super.key, required this.sessionId});

  @override
  State<AgentNegotiationScreen> createState() => _AgentNegotiationScreenState();
}

class _AgentNegotiationScreenState extends State<AgentNegotiationScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _termsController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  bool _isCountering = false;

  @override
  void dispose() {
    _amountController.dispose();
    _termsController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendCounter(NegotiationSession session) {
    if (_amountController.text.isEmpty) return;
    
    final amountString = _amountController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final amount = double.tryParse(amountString) ?? 0.0;
    
    Provider.of<NegotiationProvider>(context, listen: false).agentCounter(
      widget.sessionId, 
      amount, 
      _termsController.text.isNotEmpty ? _termsController.text : null, 
      _messageController.text.isNotEmpty ? _messageController.text : null,
    );
    
    _amountController.clear();
    _termsController.clear();
    _messageController.clear();
    setState(() {
      _isCountering = false;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<NegotiationProvider>(
      builder: (context, provider, child) {
        final session = provider.sessions.firstWhere(
          (s) => s.id == widget.sessionId,
          orElse: () => throw Exception('Session not found'),
        );
        
        final isAgentTurn = session.status == NegotiationStatus.clientOffer || 
                            session.status == NegotiationStatus.clientCountered;
                             
        return Scaffold(
          appBar: AppBar(
            title: const Text('Offer Management', style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            elevation: 0,
            backgroundColor: theme.colorScheme.surface,
          ),
          body: Column(
            children: [
              _buildHeader(session, theme, isDark),
              Expanded(
                child: _buildThread(session, theme),
              ),
              if (isAgentTurn) 
                _isCountering ? _buildCounterComposer(session, theme) : _buildResponseActions(session, theme)
              else 
                _buildStatusFooter(session, theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(NegotiationSession session, ThemeData theme, bool isDark) {
    String statusText;
    Color statusColor;
    
    switch (session.status) {
      case NegotiationStatus.agreed:
        statusText = 'AGREED';
        statusColor = Colors.green;
        break;
      case NegotiationStatus.rejected:
      case NegotiationStatus.dealEnded:
        statusText = 'DEAL ENDED';
        statusColor = Colors.red;
        break;
      case NegotiationStatus.withdrawn:
        statusText = 'WITHDRAWN';
        statusColor = Colors.grey;
        break;
      default:
        statusText = 'NEGOTIATING';
        statusColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.user, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offer from ${session.clientName}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  session.property.title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThread(NegotiationSession session, ThemeData theme) {
    if (session.history.isEmpty) return const SizedBox();

    int currentRound = (session.history.length / 2).ceil() + (session.history.length % 2 == 0 ? 0 : 1);
    if (currentRound > session.maxRounds) currentRound = session.maxRounds;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Negotiation Limit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                  Text('Round $currentRound of ${session.maxRounds}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: currentRound / session.maxRounds,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: session.history.length,
            itemBuilder: (context, index) {
              final offer = session.history[index];
              final isAgentSender = offer.side == OfferSide.agent;
              final isAgreedOffer = session.status == NegotiationStatus.agreed && index == session.history.length - 1;
              return _buildOfferBubble(offer, isAgentSender, isAgreedOffer, theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOfferBubble(NegotiationOffer offer, bool isAgentSender, bool isAgreedOffer, ThemeData theme) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isAgentSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isAgentSender) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.user, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isAgreedOffer 
                    ? LinearGradient(colors: [Colors.green.withValues(alpha: 0.1), Colors.green.withValues(alpha: 0.05)])
                    : isAgentSender 
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
                          )
                        : null,
                color: !isAgreedOffer && !isAgentSender ? theme.colorScheme.surface : null,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isAgentSender ? const Radius.circular(0) : const Radius.circular(20),
                  bottomLeft: !isAgentSender ? const Radius.circular(0) : const Radius.circular(20),
                ),
                border: isAgreedOffer ? Border.all(color: Colors.green.withValues(alpha: 0.5)) : null,
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
                children: [
                  if (isAgreedOffer)
                    const Row(
                      children: [
                        Icon(LucideIcons.checkCircle2, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text('AGREED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  if (isAgreedOffer) const SizedBox(height: 8),
                  
                  Text(
                    '₦${(offer.amount / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(
                      color: isAgentSender && !isAgreedOffer ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  
                  if (offer.proposedTerms != null && offer.proposedTerms!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isAgentSender && !isAgreedOffer 
                            ? Colors.black.withValues(alpha: 0.1) 
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.fileText, 
                            size: 14, 
                            color: isAgentSender && !isAgreedOffer ? Colors.white70 : Colors.grey[600]
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              offer.proposedTerms!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isAgentSender && !isAgreedOffer ? Colors.white : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  if (offer.message != null && offer.message!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '"${offer.message}"',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: isAgentSender && !isAgreedOffer ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  Text(
                    dateFormat.format(offer.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isAgentSender && !isAgreedOffer ? Colors.white54 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isAgentSender) const SizedBox(width: 8), 
        ],
      ),
    );
  }

  Widget _buildResponseActions(NegotiationSession session, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Provider.of<NegotiationProvider>(context, listen: false).agentReject(session.id);
                },
                icon: const Icon(LucideIcons.xCircle, size: 18),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _isCountering = true);
                },
                icon: const Icon(LucideIcons.messageSquare, size: 18),
                label: const Text('Counter'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Provider.of<NegotiationProvider>(context, listen: false).agentAccept(session.id);
                },
                icon: const Icon(LucideIcons.checkCircle2, size: 18),
                label: const Text('Accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterComposer(NegotiationSession session, ThemeData theme) {
    if (_amountController.text.isEmpty && session.history.isNotEmpty) {
        _amountController.text = session.askingPrice.toInt().toString();
    }

    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Counter Amount (₦)',
                    border: OutlineInputBorder(),
                    prefixText: '₦ ',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _termsController,
            decoration: const InputDecoration(
              labelText: 'Proposed Terms (Optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            minLines: 1,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Message (Optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            minLines: 1,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isCountering = false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => _sendCounter(session),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Send Counter Offer'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatusFooter(NegotiationSession session, ThemeData theme) {
    if (session.status == NegotiationStatus.agentCountered) {
      return Container(
        padding: const EdgeInsets.all(24).copyWith(bottom: MediaQuery.of(context).padding.bottom + 24),
        color: theme.colorScheme.surface,
        width: double.infinity,
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Awaiting Client Response...',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
    
    if (session.status == NegotiationStatus.agreed) {
       return Container(
        padding: const EdgeInsets.all(24).copyWith(bottom: MediaQuery.of(context).padding.bottom + 24),
        color: theme.colorScheme.surface,
        width: double.infinity,
        child: const Column(
          children: [
            Icon(LucideIcons.checkCircle2, color: Colors.green, size: 48),
            SizedBox(height: 16),
            Text(
              'Offer Agreed.',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Client will now proceed to escrow.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // Rejected, Withdrawn, Deal Ended
    return Container(
        padding: const EdgeInsets.all(24).copyWith(bottom: MediaQuery.of(context).padding.bottom + 24),
        color: theme.colorScheme.surface,
        width: double.infinity,
        child: Column(
          children: [
            Icon(
              session.status == NegotiationStatus.withdrawn ? LucideIcons.logOut : LucideIcons.xCircle, 
              color: Colors.grey[600], 
              size: 48
            ),
            const SizedBox(height: 16),
            Text(
              session.status == NegotiationStatus.withdrawn ? 'Client Withdrew Offer' : 'Deal Ended',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      );
  }
}
