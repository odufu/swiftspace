import 'package:swiftspace/features/property/domain/entities/property.dart';

class RecommendationResult {
  final List<Property> properties;
  final String contextSummary;
  final Map<String, dynamic>? filters;

  RecommendationResult({
    required this.properties,
    required this.contextSummary,
    this.filters,
  });
}
