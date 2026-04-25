enum InspectionType { physical, virtual }

class InspectionPlan {
  final String id;
  final String propertyId;
  final String userId;
  final String agentId; // Assigned agent
  final InspectionType type;
  final DateTime scheduledTime;
  final String status; // pending, confirmed, completed, cancelled
  final String
  aiNotes; // e.g. "Agent advised to show the newly renovated kitchen first."

  InspectionPlan({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.agentId,
    required this.type,
    required this.scheduledTime,
    this.status = 'pending',
    this.aiNotes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'user_id': userId,
      'agent_id': agentId,
      'type': type.name,
      'scheduled_time': scheduledTime.toIso8601String(),
      'status': status,
      'ai_notes': aiNotes,
    };
  }

  factory InspectionPlan.fromJson(Map<String, dynamic> json) {
    return InspectionPlan(
      id: json['id'] ?? '',
      propertyId: json['property_id'] ?? '',
      userId: json['user_id'] ?? '',
      agentId: json['agent_id'] ?? '',
      type: InspectionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InspectionType.physical,
      ),
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.parse(json['scheduled_time'])
          : DateTime.now(),
      status: json['status'] ?? 'pending',
      aiNotes: json['ai_notes'] ?? '',
    );
  }
}
