import 'dart:math';

enum SavingsFrequency { daily, weekly, monthly, quarterly }

class PartnerBank {
  final String id;
  final String name;
  final String logoUrl; // We will use a network image or standard colors as fallback
  final double interestRate; // e.g. 5.5 for 5.5%
  final String tagLine;

  const PartnerBank({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.interestRate,
    required this.tagLine,
  });
}

class SavingsRecord {
  final DateTime date;
  final double amount;
  final bool isCompleted;

  SavingsRecord({
    required this.date,
    required this.amount,
    this.isCompleted = true,
  });
}

class SavingsPlan {
  final String id;
  final String goalName; // E.g., "Dream Duplex in Asokoro" or "Lekki Rent"
  final String? targetPropertyId; // Nullable
  final PartnerBank bank;
  final SavingsFrequency frequency;
  final int durationMonths;
  final double targetAmount;
  final double amountPerCycle;
  final DateTime startDate;
  final List<SavingsRecord> history;
  
  SavingsPlan({
    required this.id,
    required this.goalName,
    this.targetPropertyId,
    required this.bank,
    required this.frequency,
    this.durationMonths = 12,
    required this.targetAmount,
    required this.amountPerCycle,
    required this.startDate,
    required this.history,
  });

  double get savedSoFar {
    return history.where((r) => r.isCompleted).fold(0.0, (sum, item) => sum + item.amount);
  }

  double get accruedInterest {
    // Basic mock logic: interest scales dynamically over time, 
    // calculated via a baseline 10% assumption logic scaled to fractional yields.
    return savedSoFar * (bank.interestRate / 100) * 0.1;
  }
  
  DateTime get nextPaymentDate {
    if (history.isEmpty) return startDate;
    final lastRecordDate = history.last.date;
    switch (frequency) {
      case SavingsFrequency.daily:
        return lastRecordDate.add(const Duration(days: 1));
      case SavingsFrequency.weekly:
        return lastRecordDate.add(const Duration(days: 7));
      case SavingsFrequency.monthly:
        return DateTime(lastRecordDate.year, lastRecordDate.month + 1, lastRecordDate.day);
      case SavingsFrequency.quarterly:
        return DateTime(lastRecordDate.year, lastRecordDate.month + 3, lastRecordDate.day);
    }
  }

  int get maxCycles {
    // How many blocks to show total according to the user's defined duration
    final years = durationMonths / 12;
    switch (frequency) {
      case SavingsFrequency.daily: return (365 * years).round();
      case SavingsFrequency.weekly: return (52 * years).round();
      case SavingsFrequency.monthly: return durationMonths;
      case SavingsFrequency.quarterly: return (4 * years).round();
    }
  }
}
