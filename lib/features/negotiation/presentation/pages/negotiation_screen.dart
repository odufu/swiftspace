import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/features/negotiation/domain/entities/negotiation.dart';
import 'package:swiftspace/features/negotiation/presentation/state/negotiation_provider.dart';
import 'package:swiftspace/features/payment/presentation/pages/escrow_payment_screen.dart';
import 'package:intl/intl.dart';

class NegotiationScreen extends StatefulWidget {
  final String sessionId;

  const NegotiationScreen({super.key, required this.sessionId});

  @override
  State<NegotiationScreen> createState() => _NegotiationScreenState();
}

class _NegotiationScreenState extends State<NegotiationScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _termsController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  @override
  void dispose() {
    _amountController.dispose();
    _termsController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitOffer(NegotiationSession session) {
    if (_amountController.text.isEmpty) return;
    
    final amountString = _amountController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final amount = double.tryParse(amountString) ?? 0.0;
    
    Provider.of<NegotiationProvider>(context, listen: false).clientSubmitOffer(
      widget.sessionId, 
      amount, 
      _termsController.text.isNotEmpty ? _termsController.text : null, 
      _messageController.text.isNotEmpty ? _messageController.text : null,
    );
    
    _amountController.clear();
    _termsController.clear();
    _messageController.clear();
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
        
        final isClientTurn = session.status == NegotiationStatus.clientOffer || 
                             session.status == NegotiationStatus.agentCountered;
                             
        return Scaffold(
          appBar: AppBar(
            title: const Text('Negotiation', style: TextStyle(fontWeight: FontWeight.bold)),
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
              if (isClientTurn) _buildComposer(session, theme)
              else _buildStatusFooter(session, theme),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              session.property.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.property.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Asking: ₦${(session.askingPrice / 1000).toStringAsFixed(0)}k',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
    if (session.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.messageSquare, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Start the negotiation',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            Text(
              'Make your first offer below',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }    // Combined history length mapped to turns
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
                  Text('Bargain Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
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
              final isClient = offer.side == OfferSide.client;
              final isAgreedOffer = session.status == NegotiationStatus.agreed && index == session.history.length - 1;
              return _buildOfferBubble(offer, isClient, isAgreedOffer, theme);
            },
          ),
        ),
      ],
    );
  } 


  Widget _buildOfferBubble(NegotiationOffer offer, bool isClient, bool isAgreedOffer, ThemeData theme) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isClient ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isClient) ...[
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
                    : isClient 
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
                          )
                        : null,
                color: !isAgreedOffer && !isClient ? theme.colorScheme.surface : null,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isClient ? const Radius.circular(0) : const Radius.circular(20),
                  bottomLeft: !isClient ? const Radius.circular(0) : const Radius.circular(20),
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
                      color: isClient && !isAgreedOffer ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  
                  if (offer.proposedTerms != null && offer.proposedTerms!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isClient && !isAgreedOffer 
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
                            color: isClient && !isAgreedOffer ? Colors.white70 : Colors.grey[600]
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              offer.proposedTerms!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isClient && !isAgreedOffer ? Colors.white : theme.colorScheme.onSurface,
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
                        color: isClient && !isAgreedOffer ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  Text(
                    dateFormat.format(offer.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isClient && !isAgreedOffer ? Colors.white54 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isClient) const SizedBox(width: 8), // Gap before screen edge
        ],
      ),
    );
  }

  Widget _buildComposer(NegotiationSession session, ThemeData theme) {
    // If agent previously countered, pre-fill with their counter amount
    if (_amountController.text.isEmpty && session.history.isNotEmpty) {
      final lastOffer = session.history.last;
      if (lastOffer.side == OfferSide.agent) {
        _amountController.text = lastOffer.amount.toInt().toString();
      }
    } else if (_amountController.text.isEmpty) {
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
                    labelText: 'Offer Amount (₦)',
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
              hintText: 'e.g. 3-month payment plan',
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
              hintText: 'Add a personal note...',
            ),
            maxLines: 2,
            minLines: 1,
          ),
          const SizedBox(height: 16),
          if (session.history.isNotEmpty) 
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Provider.of<NegotiationProvider>(context, listen: false).clientWithdraw(session.id);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Withdraw'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _submitOffer(session),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Submit Counter'),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _submitOffer(session),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Submit Offer'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusFooter(NegotiationSession session, ThemeData theme) {
    if (session.status == NegotiationStatus.clientCountered || session.status == NegotiationStatus.clientOffer) {
      return Container(
        padding: const EdgeInsets.all(24).copyWith(bottom: MediaQuery.of(context).padding.bottom + 24),
        color: theme.colorScheme.surface,
        width: double.infinity,
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Awaiting Agent Response...',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Provider.of<NegotiationProvider>(context, listen: false).clientWithdraw(session.id);
              },
              child: const Text('Withdraw Offer'),
            ),
          ],
        ),
      );
    }
    
    if (session.status == NegotiationStatus.agreed) {
       final agreedPrice = session.history.last.amount;
       return Container(
        padding: const EdgeInsets.all(24).copyWith(bottom: MediaQuery.of(context).padding.bottom + 24),
        color: theme.colorScheme.surface,
        width: double.infinity,
        child: Column(
          children: [
            const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Congratulations! Offer Agreed.',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EscrowPaymentScreen(
                            propertyTitle: session.property.title,
                            location: session.property.locationName,
                            propertyImage: session.property.imageUrl,
                            amount: agreedPrice,
                            dealType: session.property.priceTerm != 'buy' ? 'Rental Agreement' : 'Purchase',
                          ),
                        ),
                      );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Proceed to Escrow →'),
              ),
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
              session.status == NegotiationStatus.withdrawn ? 'Offer Withdrawn' : 'Deal Ended',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              session.status == NegotiationStatus.rejected ? 'The agent has rejected the offer parameters.' : 'This negotiation thread is closed.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
  }
}
