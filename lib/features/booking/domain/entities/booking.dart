import 'package:swiftspace/features/property/domain/entities/property.dart';

enum BookingStatus { 
  pending,       // Client requested
  confirmed,     // Agent accepted
  declined,      // Agent declined
  postponed,     // Agent requested new time
  commenced,     // Agent started inspection
  finalized,     // Agent ended inspection
  completed,     // Client marked as success
  cancelled      // Client cancelled
}

class InspectionBooking {
  final String id;
  final Property property;
  final DateTime dateTime;
  final BookingStatus status;
  final DateTime createdAt;
  
  // New tracking fields
  final int? clientRating;
  final String? clientReview;
  final bool isClientApproved;
  final String? agentNotes;
  final String? clientNotes;
  final String? postponementReason;
  final DateTime? originalDateTime;
  /// ID of the linked EscrowTransaction for the inspection commitment fee
  final String? escrowTransactionId;

  InspectionBooking({
    required this.id,
    required this.property,
    required this.dateTime,
    this.status = BookingStatus.pending,
    DateTime? createdAt,
    this.clientRating,
    this.clientReview,
    this.isClientApproved = false,
    this.agentNotes,
    this.clientNotes,
    this.postponementReason,
    this.originalDateTime,
    this.escrowTransactionId,
  }) : createdAt = createdAt ?? DateTime.now();
  
  String get formattedDate => '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  String get formattedTime => '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

  InspectionBooking copyWith({
    BookingStatus? status,
    DateTime? dateTime,
    int? clientRating,
    String? clientReview,
    bool? isClientApproved,
    String? agentNotes,
    String? clientNotes,
    String? postponementReason,
    DateTime? originalDateTime,
    String? escrowTransactionId,
  }) {
    return InspectionBooking(
      id: id,
      property: property,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      createdAt: createdAt,
      clientRating: clientRating ?? this.clientRating,
      clientReview: clientReview ?? this.clientReview,
      isClientApproved: isClientApproved ?? this.isClientApproved,
      agentNotes: agentNotes ?? this.agentNotes,
      clientNotes: clientNotes ?? this.clientNotes,
      postponementReason: postponementReason ?? this.postponementReason,
      originalDateTime: originalDateTime ?? this.originalDateTime,
      escrowTransactionId: escrowTransactionId ?? this.escrowTransactionId,
    );
  }
}
