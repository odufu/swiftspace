import 'package:swiftspace/features/property/domain/entities/property.dart';
import '../entities/recommendation_result.dart';

abstract class IAiRecommendationService {
  /// Sends a natural language query to the AI engine and returns a list of ranked properties
  /// along with contextual metadata.
  Future<RecommendationResult> getRecommendations(String query);
}
