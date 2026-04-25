import 'package:swiftspace/features/property/domain/entities/property.dart';

enum IntentType { investment, residential, commercial, shortLet, unknown }

class SearchIntent {
  final String id;
  final String userId;
  final IntentType type;
  final double minBudget;
  final double maxBudget;
  final List<String> preferredLocations;
  final PropertyType? preferredPropertyType;
  final int? bedrooms;
  final String rawQuery;
  final DateTime createdAt;

  SearchIntent({
    required this.id,
    required this.userId,
    required this.type,
    this.minBudget = 0,
    this.maxBudget = double.infinity,
    this.preferredLocations = const [],
    this.preferredPropertyType,
    this.bedrooms,
    this.rawQuery = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'min_budget': minBudget,
      'max_budget': maxBudget,
      'preferred_locations': preferredLocations,
      'preferred_property_type': preferredPropertyType?.name,
      'bedrooms': bedrooms,
      'raw_query': rawQuery,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SearchIntent.fromJson(Map<String, dynamic> json) {
    return SearchIntent(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: IntentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => IntentType.unknown,
      ),
      minBudget: (json['min_budget'] as num?)?.toDouble() ?? 0,
      maxBudget: (json['max_budget'] as num?)?.toDouble() ?? double.infinity,
      preferredLocations: List<String>.from(json['preferred_locations'] ?? []),
      preferredPropertyType: json['preferred_property_type'] != null
          ? PropertyType.values.firstWhere(
              (e) => e.name == json['preferred_property_type'],
              orElse: () => PropertyType.flatsAndApartments,
            )
          : null,
      bedrooms: json['bedrooms'] as int?,
      rawQuery: json['raw_query'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// Parses a natural language query into a structured SearchIntent using basic heuristics.
  factory SearchIntent.fromHeuristics({
    required String userId,
    required String rawQuery,
    double defaultMinPrice = 0,
    double defaultMaxPrice = double.infinity,
    PropertyType? defaultPropertyType,
  }) {
    final query = rawQuery.toLowerCase();
    
    // 1. Parse Locations
    final knownLocations = ['lugbe', 'maitama', 'wuse', 'gwarinpa', 'asokoro', 'apo', 'jabi', 'garki', 'lifecamp'];
    List<String> locations = [];
    for (var loc in knownLocations) {
      if (query.contains(loc)) {
        locations.add(loc);
      }
    }

    // 2. Parse Property Type & Bedrooms
    PropertyType? type = defaultPropertyType;
    int? bedrooms;

    final bedMatch = RegExp(r'\b(\d+)\s*(bed|bedroom|bhk|beds)\b').firstMatch(query);
    if (bedMatch != null) {
      bedrooms = int.tryParse(bedMatch.group(1)!);
    }

    if (query.contains('self contain') || query.contains('studio')) {
      type = PropertyType.flatsAndApartments;
      bedrooms ??= 1;
    } else if (query.contains('flat') || query.contains('apartment')) {
      type = PropertyType.flatsAndApartments;
    } else if (query.contains('duplex') || query.contains('house') || query.contains('villa')) {
      type = PropertyType.house;
    } else if (query.contains('land') || query.contains('plot')) {
      type = PropertyType.lands;
    } else if (query.contains('commercial') || query.contains('shop') || query.contains('office')) {
      type = PropertyType.commercialProperties;
    }

    // 3. Parse Budget
    double maxBudget = defaultMaxPrice;
    final numMatch = RegExp(r'\b\d{2,3}(,\d{3})*(000|k|m|million)?\b').firstMatch(query);
    if (numMatch != null) {
      String numStr = numMatch.group(0)!.replaceAll(',', '');
      if (numStr.endsWith('k')) {
        maxBudget = double.parse(numStr.replaceAll('k', '')) * 1000;
      } else if (numStr.endsWith('m') || numStr.endsWith('million')) {
        maxBudget = double.parse(numStr.replaceAll('m', '').replaceAll('million', '')) * 1000000;
      } else {
        maxBudget = double.parse(numStr);
        // if user types 30000 for a house, it might mean 30,000,000 or 30k depending on context. 
        // Keep as is for simple heuristic.
      }
    }

    // 4. Parse Intent Type
    IntentType intentType = IntentType.unknown;
    if (query.contains('invest') || query.contains('roi')) {
      intentType = IntentType.investment;
    } else if (query.contains('live') || query.contains('stay') || query.contains('residential')) {
      intentType = IntentType.residential;
    } else if (query.contains('short') || query.contains('airbnb') || query.contains('holiday')) {
      intentType = IntentType.shortLet;
    }

    return SearchIntent(
      id: 'intent_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: intentType,
      minBudget: defaultMinPrice,
      maxBudget: maxBudget,
      preferredLocations: locations,
      preferredPropertyType: type,
      bedrooms: bedrooms,
      rawQuery: rawQuery,
    );
  }
}
