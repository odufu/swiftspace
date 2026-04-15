import 'package:swiftspace/features/property/domain/entities/property.dart';

enum NegotiationStatus {
  clientOffer,
  agentCountered,
  clientCountered,
  agreed,
  rejected,
  withdrawn,
  dealEnded,
}

enum OfferSide { client, agent }

class NegotiationOffer {
  final String id;
  final OfferSide side;
  final double amount;
  final String? proposedTerms;
  final String? message;
  final DateTime timestamp;
  final bool isCounterOffer;

  NegotiationOffer({
    required this.id,
    required this.side,
    required this.amount,
    this.proposedTerms,
    this.message,
    required this.timestamp,
    this.isCounterOffer = false,
  });
}

class NegotiationSession {
  final String id;
  final String bookingId;
  final Property property;
  final String clientName;
  final String agentName;
  final double askingPrice;
  NegotiationStatus status;
  final List<NegotiationOffer> history;
  final int maxRounds;

  NegotiationSession({
    required this.id,
    required this.bookingId,
    required this.property,
    required this.clientName,
    required this.agentName,
    required this.askingPrice,
    this.status = NegotiationStatus.clientOffer,
    this.history = const [],
    this.maxRounds = 5,
  });

  NegotiationSession copyWith({
    NegotiationStatus? status,
    List<NegotiationOffer>? history,
  }) {
    return NegotiationSession(
      id: id,
      bookingId: bookingId,
      property: property,
      clientName: clientName,
      agentName: agentName,
      askingPrice: askingPrice,
      status: status ?? this.status,
      history: history ?? this.history,
      maxRounds: maxRounds,
    );
  }
}
