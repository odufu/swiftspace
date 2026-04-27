import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import '../../domain/entities/recommendation_result.dart';
import '../../domain/services/ai_recommendation_service.dart';
import 'package:geolocator/geolocator.dart';

class SupabaseAiRecommendationService implements IAiRecommendationService {
  final SupabaseClient _supabase;

  SupabaseAiRecommendationService(this._supabase);

  @override
  Future<RecommendationResult> getRecommendations(String query) async {
    double? userLat;
    double? userLng;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          userLat = position.latitude;
          userLng = position.longitude;
          log('[AI] Retrieved user location: lat=$userLat, lng=$userLng');
        }
      }
    } catch (e) {
      log('[AI] Failed to get user location: $e');
    }

    final response = await _supabase.functions.invoke(
      'smart-explore-agent',
      body: {
        'query': query,
        if (userLat != null) 'user_lat': userLat,
        if (userLng != null) 'user_lng': userLng,
      },
    );

    if (response.status != 200) {
      log(
        '[AI] Edge function returned status ${response.status}: ${response.data}',
      );
      throw Exception('Search failed (${response.status}). Please try again.');
    }

    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      log('[AI] Edge function returned null data.');
      return RecommendationResult(
        properties: [],
        contextSummary: "I couldn't find anything matching your request.",
      );
    }

    // Surface any server-side errors to the UI
    if (data.containsKey('error')) {
      log('[AI] Edge function error: ${data['error']}');
      throw Exception(data['error'].toString());
    }

    final propertiesList = data['properties'] as List<dynamic>? ?? [];
    final contextSummary =
        data['context_summary'] as String? ??
        "Found ${propertiesList.length} properties that match your criteria.";

    log(
      '[AI] Received ${propertiesList.length} properties from edge function. '
      'Filters: ${data['filters']}',
    );

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

    log(
      '[AI] Successfully mapped ${results.length}/${propertiesList.length} properties.',
    );

    return RecommendationResult(
      properties: results,
      contextSummary: contextSummary,
      filters: data['filters'],
    );
  }
}
