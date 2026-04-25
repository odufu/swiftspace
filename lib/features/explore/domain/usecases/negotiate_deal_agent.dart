import 'package:swiftspace/features/property/domain/entities/property.dart';
import '../entities/negotiation_strategy.dart';

class NegotiateDealAgent {
  /// Generates a NegotiationStrategy based on property price and basic heuristics.
  NegotiationStrategy execute({
    required Property property,
    required String userId,
    required double userMaxBudget,
  }) {
    // Basic heuristic strategy
    double targetPrice;
    double maximumPrice;
    List<String> levers = [];
    String analysis = "";

    // If property is above user budget
    if (property.price > userMaxBudget) {
      targetPrice = userMaxBudget * 0.95; // Aim 5% lower than max budget
      maximumPrice = userMaxBudget;
      levers.add("Highlight budget constraints but quick readiness to pay.");
      levers.add("Request exclusion of minor furnishings to lower price.");
      analysis =
          "Property is above your stated budget. We recommend an aggressive initial offer of ₦${_formatPrice(targetPrice)} emphasizing immediate payment readiness.";
    } else {
      // If property is within budget
      targetPrice = property.price * 0.90; // Aim for 10% discount
      maximumPrice = property.price;
      levers.add("Offer to pay 6-12 months upfront for a larger discount.");
      levers.add(
        "Ask for minor renovations or repainting to be included in the price.",
      );
      analysis =
          "Property is within budget. AI suggests aiming for a 10% discount due to current market liquidity trends.";
    }

    return NegotiationStrategy(
      id: 'neg_${DateTime.now().millisecondsSinceEpoch}',
      propertyId: property.id,
      userId: userId,
      targetPrice: targetPrice,
      maximumPrice: maximumPrice,
      recommendedLevers: levers,
      aiAnalysis: analysis,
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }
}
