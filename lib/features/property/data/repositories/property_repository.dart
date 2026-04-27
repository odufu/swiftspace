import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/property.dart';
import '../mock_properties.dart';
import 'package:swiftspace/core/error/app_exception.dart';

class PropertyRepository {
  final SupabaseClient _client;

  PropertyRepository(this._client);

  Future<List<Property>> getProperties({bool includeTest = true}) async {
    try {
      // 1. Fetch live properties from Supabase with a timeout
      final List<dynamic> response = await _client
          .from('properties')
          .select()
          .eq('is_active', true)
          .timeout(const Duration(seconds: 10));

      final liveProperties = response.map((json) => Property.fromMap(json)).toList();

      // 2. Combine with mock data if requested
      if (includeTest) {
        // Mark mock properties as test if not already marked
        final testProperties = mockProperties.map((p) => p.copyWith(isTest: true)).toList();
        return [...liveProperties, ...testProperties];
      }

      return liveProperties;
    } catch (e) {
      // If table doesn't exist yet or other DB error, fallback to mock data for now
      // but log it or handle it gracefully
      if (e is PostgrestException && e.code == 'PGRST204') {
        // Table not found - likely not created yet
        return mockProperties.map((p) => p.copyWith(isTest: true)).toList();
      }
      
      // For other errors, we might want to throw or return mock data as a fallback
      // Since we are in transition, returning mock data is safer for UX
      return mockProperties.map((p) => p.copyWith(isTest: true)).toList();
    }
  }

  Future<Property> getPropertyById(String id) async {
    try {
      // Check mock data first (since IDs are prefixed usually)
      final mock = mockProperties.firstWhere((p) => p.id == id, orElse: () => throw Exception('Not found in mock'));
      return mock.copyWith(isTest: true);
    } catch (_) {
      try {
        final response = await _client
            .from('properties')
            .select()
            .eq('id', id)
            .single();
        return Property.fromMap(response);
      } catch (e) {
        throw AppException.fromSupabase(e);
      }
    }
  }

  Future<void> insertProperty(Property property) async {
    try {
      await _client.from('properties').insert(property.toMap());
    } catch (e) {
      throw AppException.fromSupabase(e);
    }
  }

  Future<void> incrementMetric(String propertyId, String metricColumn, [int amount = 1]) async {
    // Skip if it's a mock property
    if (propertyId.startsWith('prop_') || propertyId.startsWith('mock_')) return;

    try {
      // For a robust, offline-first execution, we fetch current, add, and push
      final response = await _client
          .from('properties')
          .select(metricColumn)
          .eq('id', propertyId)
          .single();
          
      final currentCount = response[metricColumn] as int? ?? 0;
      final newCount = currentCount + amount;
      
      // We don't want favorites going below 0
      if (newCount < 0) return;
      
      await _client
          .from('properties')
          .update({metricColumn: newCount})
          .eq('id', propertyId);
    } catch (e) {
      // Silently fail network metric updates to avoid disrupting the UI
      return;
    }
  }
}
