import '../entities/inspection_plan.dart';

class ScheduleInspectionAgent {
  /// Generates a proposed InspectionPlan based on property availability heuristics.
  InspectionPlan execute({
    required String propertyId,
    required String userId,
    required String preferredAgentId,
    required InspectionType type,
  }) {
    // Heuristic: Propose the next available slot (e.g., tomorrow at 10 AM)
    DateTime now = DateTime.now();
    DateTime proposedTime = DateTime(now.year, now.month, now.day + 1, 10, 0);

    // Skip weekends if it's a physical inspection (simple heuristic)
    if (type == InspectionType.physical &&
        (proposedTime.weekday == 6 || proposedTime.weekday == 7)) {
      proposedTime = proposedTime.add(Duration(days: 8 - proposedTime.weekday));
    }

    String aiNotes = type == InspectionType.virtual
        ? "Ensure high-speed internet connection for the virtual tour. Agent will focus on structural integrity."
        : "Agent advised to show the surrounding neighborhood amenities after the property tour.";

    return InspectionPlan(
      id: 'insp_${DateTime.now().millisecondsSinceEpoch}',
      propertyId: propertyId,
      userId: userId,
      agentId: preferredAgentId,
      type: type,
      scheduledTime: proposedTime,
      status: 'pending',
      aiNotes: aiNotes,
    );
  }
}
