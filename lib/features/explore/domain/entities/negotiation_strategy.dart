class NegotiationStrategy {
  final String id;
  final String propertyId;
  final String userId;
  final double targetPrice;
  final double maximumPrice;
  final List<String>
  recommendedLevers; // e.g. "Request paint job", "Offer 6-month upfront"
  final String
  aiAnalysis; // e.g. "Property has been on market for 60 days, seller might accept 10% lower."
  final DateTime generatedAt;

  NegotiationStrategy({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.targetPrice,
    required this.maximumPrice,
    this.recommendedLevers = const [],
    this.aiAnalysis = '',
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'user_id': userId,
      'target_price': targetPrice,
      'maximum_price': maximumPrice,
      'recommended_levers': recommendedLevers,
      'ai_analysis': aiAnalysis,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  factory NegotiationStrategy.fromJson(Map<String, dynamic> json) {
    return NegotiationStrategy(
      id: json['id'] ?? '',
      propertyId: json['property_id'] ?? '',
      userId: json['user_id'] ?? '',
      targetPrice: (json['target_price'] as num?)?.toDouble() ?? 0,
      maximumPrice: (json['maximum_price'] as num?)?.toDouble() ?? 0,
      recommendedLevers: List<String>.from(json['recommended_levers'] ?? []),
      aiAnalysis: json['ai_analysis'] ?? '',
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'])
          : DateTime.now(),
    );
  }
}
