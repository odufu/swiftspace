import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import '../../domain/services/ai_recommendation_service.dart';

class SupabaseAiRecommendationService implements IAiRecommendationService {
  final SupabaseClient _supabase;

  SupabaseAiRecommendationService(this._supabase);

  @override
  Future<List<Property>> getRecommendations(String query) async {
    final response = await _supabase.functions.invoke(
      'smart-explore-agent',
      body: {'query': query},
    );

    if (response.status != 200) {
      log('[AI] Edge function returned status ${response.status}: ${response.data}');
      throw Exception('Search failed (${response.status}). Please try again.');
    }

    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      log('[AI] Edge function returned null data.');
      return [];
    }

    // Surface any server-side errors to the UI
    if (data.containsKey('error')) {
      log('[AI] Edge function error: ${data['error']}');
      throw Exception(data['error'].toString());
    }

    final propertiesList = data['properties'] as List<dynamic>? ?? [];
    log('[AI] Received ${propertiesList.length} properties from edge function. '
        'Filters: ${data['filters']}');

    final results = <Property>[];
    for (int i = 0; i < propertiesList.length; i++) {
      try {
        final map = propertiesList[i] as Map<String, dynamic>;
        results.add(Property.fromMap(map));
      } catch (e, stack) {
        // Log the bad record but don't drop the whole result set
        log('[AI] Failed to parse property at index $i: $e\n$stack');
      }
    }

    log('[AI] Successfully mapped ${results.length}/${propertiesList.length} properties.');
    return results;
  }
}
