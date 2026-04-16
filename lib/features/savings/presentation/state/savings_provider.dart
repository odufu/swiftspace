import 'dart:async';
import 'package:flutter/material.dart';
import 'package:swiftspace/features/savings/domain/entities/savings_plan.dart';
import 'package:uuid/uuid.dart';
import 'package:swiftspace/core/services/audio_manager.dart';

class SavingsProvider with ChangeNotifier {
  final List<SavingsPlan> _activePlans = [];
  Timer? _ticker;
  DateTime _simulatedTime = DateTime.now();

  SavingsProvider() {
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  List<SavingsPlan> get activePlans => [..._activePlans];

  SavingsPlan? get activePlan => _activePlans.isNotEmpty ? _activePlans.first : null;

  DateTime get simulatedTime => _simulatedTime;

  static const List<PartnerBank> partnerBanks = [
    PartnerBank(
      id: 'GTB',
      name: 'Guarantee Trust Bank',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/GTBank_logo.svg/1200px-GTBank_logo.svg.png',
      interestRate: 6.5,
      tagLine: 'Official SwiftSpace Savings Partner',
    ),
    PartnerBank(
      id: 'STB',
      name: 'Stanbic IBTC',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/e/ec/Stanbic_IBTC_Holdings_logo.jpg',
      interestRate: 7.0,
      tagLine: 'Your Premium Real Estate Custodian',
    ),
    PartnerBank(
      id: 'KDA',
      name: 'Kuda Microfinance',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Kuda_logo.png/1024px-Kuda_logo.png',
      interestRate: 8.5,
      tagLine: 'Fast, Free, Flexible Savings',
    )
  ];

  DateTime _lastInteractionTime = DateTime.fromMillisecondsSinceEpoch(0);

  void _startTicker() {
    // We no longer call notifyListeners here every second.
    // Individual widgets that need real-time updates (like the countdown)
    // should use their own local timers.
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _simulatedTime = DateTime.now();
    });
  }
  void createPlan({
    required String goalName,
    String? propertyId,
    required PartnerBank bank,
    required SavingsFrequency frequency,
    required double targetAmount,
    int durationMonths = 12,
  }) {
    // Determine how many cycles total based on duration
    final years = durationMonths / 12;
    int totalCycles;
    switch (frequency) {
      case SavingsFrequency.daily: totalCycles = (365 * years).round(); break;
      case SavingsFrequency.weekly: totalCycles = (52 * years).round(); break;
      case SavingsFrequency.monthly: totalCycles = durationMonths; break;
      case SavingsFrequency.quarterly: totalCycles = (4 * years).round(); break;
    }
    
    final plan = SavingsPlan(
      id: const Uuid().v4(),
      goalName: goalName,
      targetPropertyId: propertyId,
      bank: bank,
      frequency: frequency,
      durationMonths: durationMonths,
      targetAmount: targetAmount,
      amountPerCycle: targetAmount / totalCycles,
      startDate: DateTime.now().add(const Duration(minutes: 1)), // Starts very soon for demo
      history: [
        // Mock a few past payments for immediate gamification satisfaction
        SavingsRecord(
          date: DateTime.now().subtract(const Duration(days: 30)),
          amount: targetAmount / totalCycles,
        ),
        SavingsRecord(
          date: DateTime.now().subtract(const Duration(days: 15)),
          amount: targetAmount / totalCycles,
        ),
        SavingsRecord(
          date: DateTime.now().subtract(const Duration(days: 1)),
          amount: targetAmount / totalCycles,
        ),
      ],
    );

    _activePlans.insert(0, plan);
    notifyListeners();
  }


  void simulateFastForward() {
    // Cooldown check: 500ms to prevent UI thread flooding
    final now = DateTime.now();
    if (now.difference(_lastInteractionTime).inMilliseconds < 500) return;
    _lastInteractionTime = now;

    if (_activePlans.isEmpty) return;
    
    final plan = _activePlans.first;
    plan.history.add(
      SavingsRecord(
        date: plan.nextPaymentDate,
        amount: plan.amountPerCycle,
      ),
    );
    notifyListeners();
  }
}

