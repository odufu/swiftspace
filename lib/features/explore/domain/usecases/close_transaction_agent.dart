class CloseTransactionAgent {
  /// Generates a final checklist and next steps for closing the deal.
  List<String> execute({
    required String propertyType,
    required bool isMortgage,
  }) {
    List<String> checklist = [
      "Review and sign the final offer letter.",
      "Complete the Know Your Customer (KYC) documentation.",
      "Schedule the final physical walkthrough of the property.",
    ];

    if (isMortgage) {
      checklist.addAll([
        "Finalize mortgage approval with partner bank.",
        "Sign mortgage deed and related covenants.",
      ]);
    } else {
      checklist.add("Transfer funds to the designated escrow account.");
    }

    if (propertyType.toLowerCase() == 'land') {
      checklist.add("Process Certificate of Occupancy (C of O) transfer.");
    } else {
      checklist.add("Receive keys and welcome package from the agent.");
    }

    return checklist;
  }
}
