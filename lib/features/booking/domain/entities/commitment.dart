import 'booking.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';

enum CommitmentType { inspection, deal }

class ChecklistItem {
  final String label;
  final bool isDone;
  ChecklistItem({required this.label, this.isDone = false});
}

class UnifiedCommitment {
  final String id;
  final Property property;
  final CommitmentType type;
  final dynamic originalObject; // Custom data object (e.g. Booking)
  final String statusLabel;
  final String nextActionLabel;
  final double progress;
  final DateTime? dueDate;
  final List<ChecklistItem> checklist;

  UnifiedCommitment({
    required this.id,
    required this.property,
    required this.type,
    required this.originalObject,
    required this.statusLabel,
    required this.nextActionLabel,
    this.progress = 0.0,
    this.dueDate,
    this.checklist = const [],
  });

  static UnifiedCommitment fromBooking(InspectionBooking booking) {
    return UnifiedCommitment(
      id: booking.id,
      property: booking.property,
      type: CommitmentType.inspection,
      originalObject: booking,
      statusLabel: _getBookingStatusLabel(booking.status),
      nextActionLabel: _getBookingNextAction(booking.status),
      progress: _getBookingProgress(booking.status),
      dueDate: booking.dateTime,
      checklist: [
        ChecklistItem(label: 'Booking Request Sent', isDone: true),
        ChecklistItem(label: 'Identity Verified', isDone: true),
        ChecklistItem(label: 'Agent Confirmation', isDone: booking.status != BookingStatus.pending),
        ChecklistItem(label: 'Physical Visit', isDone: booking.status == BookingStatus.completed),
      ],
    );
  }

  static String _getBookingStatusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending: return 'Pending Review';
      case BookingStatus.confirmed: return 'Confirmed';
      case BookingStatus.postponed: return 'Rescheduled';
      case BookingStatus.commenced: return 'In Progress';
      case BookingStatus.finalized: return 'Visit Complete';
      case BookingStatus.completed: return 'Success';
      case BookingStatus.declined: return 'Declined';
      case BookingStatus.cancelled: return 'Cancelled';
    }
  }

  static String _getBookingNextAction(BookingStatus status) {
    if (status == BookingStatus.pending || status == BookingStatus.confirmed || status == BookingStatus.postponed) {
      return 'Reschedule or View Map';
    }
    if (status == BookingStatus.finalized) {
      return 'Approve & Close';
    }
    if (status == BookingStatus.completed) {
      return 'Negotiate Offer';
    }
    return 'View Records';
  }

  static double _getBookingProgress(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending: return 0.2;
      case BookingStatus.confirmed: return 0.5;
      case BookingStatus.finalized: return 0.8;
      case BookingStatus.completed: return 0.7; // Negotiation
      default: return 0.1;
    }
  }
}
