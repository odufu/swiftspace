import 'package:swiftspace/features/property/domain/entities/property.dart';
import '../entities/search_intent.dart';
import '../entities/property_score.dart';

class FindBestPropertiesAgent {
  /// Evaluates a list of properties against a user's SearchIntent and returns
  /// a sorted list of PropertyScores.
  List<PropertyScore> execute(
    SearchIntent intent,
    List<Property> availableProperties,
  ) {
    List<PropertyScore> scores = [];

    for (var property in availableProperties) {
      double affordability = _calculateAffordability(intent, property);
      double locationMatch = _calculateLocationMatch(intent, property);
      double investmentPotential = _calculateInvestmentPotential(
        intent,
        property,
      );

      double totalScore =
          (affordability * 0.4) +
          (locationMatch * 0.4) +
          (investmentPotential * 0.2);

      // Bonus for exact type match
      if (intent.preferredPropertyType != null &&
          property.type == intent.preferredPropertyType) {
        totalScore += 10;
      }

      // Bedroom match scoring
      if (intent.bedrooms != null) {
        if (property.beds == intent.bedrooms) {
          totalScore += 15;
        } else {
          // Penalty for mismatch
          double difference = (property.beds - intent.bedrooms!).abs().toDouble();
          totalScore -= (10 * difference);
        }
      }

      // Ensure score stays within 0-100
      totalScore = totalScore.clamp(0.0, 100.0);

      String rationale = _generateRationale(
        affordability,
        locationMatch,
        investmentPotential,
        totalScore,
      );

      scores.add(
        PropertyScore(
          propertyId: property.id,
          intentId: intent.id,
          totalScore: totalScore,
          affordabilityScore: affordability,
          locationScore: locationMatch,
          investmentPotentialScore: investmentPotential,
          aiRationale: rationale,
        ),
      );
    }

    // Sort by total score descending
    scores.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return scores;
  }

  double _calculateAffordability(SearchIntent intent, Property property) {
    if (intent.maxBudget == double.infinity) {
      return 80.0; // Default good score if no budget set
    }

    if (property.price <= intent.maxBudget &&
        property.price >= intent.minBudget) {
      // Perfect match within range
      return 100.0;
    } else if (property.price > intent.maxBudget) {
      // Over budget
      double overage = property.price - intent.maxBudget;
      double penalty = (overage / intent.maxBudget) * 100;
      return (100 - penalty).clamp(0.0, 100.0);
    } else {
      // Below min budget (might be suspiciously cheap or not what they want)
      return 70.0;
    }
  }

  double _calculateLocationMatch(SearchIntent intent, Property property) {
    if (intent.preferredLocations.isEmpty) {
      return 75.0; // Default if no preference
    }

    bool isMatch = intent.preferredLocations.any(
      (loc) => property.locationName.toLowerCase().contains(loc.toLowerCase()),
    );

    return isMatch ? 100.0 : 30.0; // High penalty for wrong location
  }

  double _calculateInvestmentPotential(SearchIntent intent, Property property) {
    // Basic heuristic: Premium properties or verified properties have higher potential
    double score = 50.0;
    if (property.isVerified) score += 20;
    if (property.isPremium) score += 30;
    return score.clamp(0.0, 100.0);
  }

  String _generateRationale(
    double afford,
    double loc,
    double invest,
    double total,
  ) {
    if (total > 90) {
      return "Excellent match. Fits your budget perfectly and is in a prime location.";
    } else if (total > 75) {
      final affordStr = afford < 80 ? "Slightly over budget but " : "";
      return "Strong candidate. ${affordStr}great investment potential.";
    } else {
      final locStr = loc < 50 ? "Location differs from preference." : "";
      return "Consider this an alternative option. $locStr";
    }
  }
}
