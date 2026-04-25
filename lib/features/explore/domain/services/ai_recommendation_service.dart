import 'package:swiftspace/features/property/domain/entities/property.dart';

abstract class IAiRecommendationService {
  /// Sends a natural language query to the AI engine and returns a list of ranked properties.
  Future<List<Property>> getRecommendations(String query);
}
