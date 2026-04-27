class PropertyScore {
  final String propertyId;
  final String intentId;
  final double totalScore; // 0 to 100
  final double affordabilityScore;
  final double locationScore;
  final double investmentPotentialScore;
  final String aiRationale; // The reasoning behind the score

  PropertyScore({
    required this.propertyId,
    required this.intentId,
    required this.totalScore,
    required this.affordabilityScore,
    required this.locationScore,
    required this.investmentPotentialScore,
    required this.aiRationale,
  });

  Map<String, dynamic> toJson() {
    return {
      'property_id': propertyId,
      'intent_id': intentId,
      'total_score': totalScore,
      'affordability_score': affordabilityScore,
      'location_score': locationScore,
      'investment_potential_score': investmentPotentialScore,
      'ai_rationale': aiRationale,
    };
  }

  factory PropertyScore.fromJson(Map<String, dynamic> json) {
    return PropertyScore(
      propertyId: json['property_id'] ?? '',
      intentId: json['intent_id'] ?? '',
      totalScore: (json['total_score'] as num?)?.toDouble() ?? 0,
      affordabilityScore:
          (json['affordability_score'] as num?)?.toDouble() ?? 0,
      locationScore: (json['location_score'] as num?)?.toDouble() ?? 0,
      investmentPotentialScore:
          (json['investment_potential_score'] as num?)?.toDouble() ?? 0,
      aiRationale: json['ai_rationale'] ?? '',
    );
  }
}
