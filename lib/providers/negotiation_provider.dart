import 'package:flutter/material.dart';
import '../models/negotiation.dart';
import '../models/property.dart';
import 'package:uuid/uuid.dart';

class NegotiationProvider with ChangeNotifier {
  final List<NegotiationSession> _sessions = [];
  final Uuid _uuid = const Uuid();

  List<NegotiationSession> get sessions => [..._sessions];

  NegotiationSession? getSessionByBookingId(String bookingId) {
    try {
      return _sessions.firstWhere((s) => s.bookingId == bookingId);
    } catch (_) {
      return null;
    }
  }

  NegotiationSession startNegotiation(String bookingId, Property property, double askingPrice) {
    var existingSession = getSessionByBookingId(bookingId);
    if (existingSession != null) return existingSession;

    final newSession = NegotiationSession(
      id: _uuid.v4(),
      bookingId: bookingId,
      property: property,
      clientName: 'Current User', // Mock client
      agentName: property.agentName,
      askingPrice: askingPrice,
      status: NegotiationStatus.clientOffer, // Starts awaiting first client offer
      history: [],
    );

    _sessions.add(newSession);
    notifyListeners();
    return newSession;
  }

  void clientSubmitOffer(String sessionId, double amount, String? terms, String? message) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;

    final session = _sessions[index];
    final isCounter = session.history.isNotEmpty;
    
    final newOffer = NegotiationOffer(
      id: _uuid.v4(),
      side: OfferSide.client,
      amount: amount,
      proposedTerms: terms,
      message: message,
      timestamp: DateTime.now(),
      isCounterOffer: isCounter,
    );

    _sessions[index] = session.copyWith(
      status: isCounter ? NegotiationStatus.clientCountered : NegotiationStatus.clientOffer,
      history: [...session.history, newOffer],
    );
    notifyListeners();
  }

  void agentAccept(String sessionId) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      _sessions[index] = _sessions[index].copyWith(status: NegotiationStatus.agreed);
      notifyListeners();
    }
  }

  void agentReject(String sessionId) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      _sessions[index] = _sessions[index].copyWith(status: NegotiationStatus.rejected);
      notifyListeners();
    }
  }

  void agentCounter(String sessionId, double amount, String? terms, String? message) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;

    final session = _sessions[index];
    
    final newOffer = NegotiationOffer(
      id: _uuid.v4(),
      side: OfferSide.agent,
      amount: amount,
      proposedTerms: terms,
      message: message,
      timestamp: DateTime.now(),
      isCounterOffer: true,
    );

    final newHistory = [...session.history, newOffer];
    
    _sessions[index] = session.copyWith(
      status: newHistory.length >= session.maxRounds * 2 
          ? NegotiationStatus.dealEnded 
          : NegotiationStatus.agentCountered,
      history: newHistory,
    );
    notifyListeners();
  }

  void clientWithdraw(String sessionId) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      _sessions[index] = _sessions[index].copyWith(status: NegotiationStatus.withdrawn);
      notifyListeners();
    }
  }

  void seedMockNegotiations(List<Property> properties) {
    if (_sessions.isNotEmpty) return;
    if (properties.isEmpty) return;

    final prop1 = properties[0];
    final prop2 = properties.length > 1 ? properties[1] : properties[0];

    // Session 1: Client made an offer, Agent needs to respond
    final session1Id = _uuid.v4();
    _sessions.add(NegotiationSession(
      id: session1Id,
      bookingId: 'BK-101',
      property: prop1,
      clientName: 'Michael Okafor',
      agentName: prop1.agentName,
      askingPrice: prop1.price,
      status: NegotiationStatus.clientOffer,
      history: [
        NegotiationOffer(
          id: _uuid.v4(),
          side: OfferSide.client,
          amount: prop1.price * 0.9,
          message: 'Can we do a bit less for a 2-year lease?',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ],
    ));

    // Session 2: Agent countered, Client needs to respond
    final session2Id = _uuid.v4();
    _sessions.add(NegotiationSession(
      id: session2Id,
      bookingId: 'BK-102',
      property: prop2,
      clientName: 'Sara Wright',
      agentName: prop2.agentName,
      askingPrice: prop2.price,
      status: NegotiationStatus.agentCountered,
      history: [
        NegotiationOffer(
          id: _uuid.v4(),
          side: OfferSide.client,
          amount: prop2.price * 0.85,
          message: 'Budget is tight.',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
        NegotiationOffer(
          id: _uuid.v4(),
          side: OfferSide.agent,
          amount: prop2.price * 0.95,
          isCounterOffer: true,
          message: 'Best I can do is 5% off.',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      ],
    ));

    notifyListeners();
  }
}
