import 'package:swiftspace/features/property/domain/entities/property.dart';

class RankingResult {
  final List<Property> rankedProperties;
  final Map<String, String> reasonings;

  RankingResult({
    required this.rankedProperties,
    required this.reasonings,
  });
}

class AiRecommendationService {
  /// Ranks properties based on user-defined priorities and provides reasoning.
  /// 
  /// Priorities can be: 'price', 'road', 'utilities', 'hospital'
  static RankingResult rankProperties({
    required List<Property> properties,
    required List<String> priorities,
  }) {
    if (properties.isEmpty) {
      return RankingResult(rankedProperties: [], reasonings: {});
    }

    // Step 1: Normalize properties and calculate scores
    final Map<String, double> scores = {};
    final Map<String, String> reasonings = {};

    // Get price range for normalization (only for the same price term)
    // For simplicity, we'll assume the user is looking at the filtered list
    final double maxPrice = properties.map((p) => p.price).fold(0, (prev, element) => element > prev ? element : prev);
    final double minPrice = properties.map((p) => p.price).fold(maxPrice, (prev, element) => element < prev ? element : prev);

    for (final property in properties) {
      double totalScore = 0.0;
      List<String> topPerformers = [];

      for (int i = 0; i < priorities.length; i++) {
        final priority = priorities[i];
        // Weight decreases by priority index (e.g., 1st: 1.0, 2nd: 0.7, 3rd: 0.5, 4th: 0.3)
        final double weight = 1.0 - (i * 0.2);
        double itemScore = 0.0;

        switch (priority) {
          case 'price':
            // Lower price is better
            itemScore = (maxPrice - property.price + 1) / (maxPrice - minPrice + 1);
            if (itemScore > 0.8) topPerformers.add("great price");
            break;
          case 'road':
            // Closer to road is better (proximityToRoadMeters)
            // 0m = 1.0, 1000m+ = 0.0
            itemScore = (1000 - property.proximityToRoadMeters).clamp(0.0, 1000.0) / 1000.0;
            if (itemScore > 0.8) topPerformers.add("excellent road access");
            break;
          case 'utilities':
            // Electricity + Water
            final electricityScore = (property.electricitySupplyHours / 24.0);
            final waterScore = property.hasRunningWater ? 1.0 : 0.0;
            itemScore = (electricityScore + waterScore) / 2.0;
            if (itemScore > 0.8) topPerformers.add("redundant utilities");
            break;
          case 'hospital':
            // Closer to hospital is better (proximityToHospitalKm)
            // 0km = 1.0, 10km+ = 0.0
            itemScore = (10.0 - property.proximityToHospitalKm).clamp(0.0, 10.0) / 10.0;
            if (itemScore > 0.8) topPerformers.add("near specialist care");
            break;
        }

        totalScore += itemScore * weight;
      }

      scores[property.id] = totalScore;
      
      // Generate reasoning based on top performers and primary priority
      String reason = "";
      if (topPerformers.isNotEmpty) {
        final primaryTop = topPerformers.first;
        final secondaryTop = topPerformers.length > 1 ? " and ${topPerformers[1]}" : "";
        reason = "Provides $primaryTop$secondaryTop, matching your top interest.";
      } else {
        reason = "Optimized balance across your chosen priorities.";
      }
      reasonings[property.id] = reason;
    }

    // Step 2: Sort properties by score
    final sortedProperties = List<Property>.from(properties);
    sortedProperties.sort((a, b) => (scores[b.id] ?? 0.0).compareTo(scores[a.id] ?? 0.0));

    return RankingResult(
      rankedProperties: sortedProperties,
      reasonings: reasonings,
    );
  }
}
