import 'package:latlong2/latlong.dart';
import 'booking.dart';
import 'package:swiftspace/features/payment/presentation/pages/escrow_payment_screen.dart';
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
  final dynamic originalObject; // InspectionBooking or EscrowTransaction
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

  static UnifiedCommitment fromEscrow(EscrowTransaction tx) {
    final property = Property(
      id: tx.id,
      title: tx.propertyTitle,
      location: const LatLng(9.1538, 7.3220), // Abuja center mock
      locationName: tx.location,
      price: tx.amount,
      priceTerm: 'buy',
      formattedPrice: '${tx.currency}${tx.amount.toStringAsFixed(0)}',
      imageUrl: tx.propertyImage,
      listerName: tx.agentName,
      listerType: ListerType.agent,
      description: 'Secured via Swift Space Escrow.',
      imagesGallery: [tx.propertyImage],
      type: PropertyType.detachedDuplex,
      beds: 4,
      baths: 4,
      has360View: true,
      hasVideo: true,
      amenities: ['Escrow Protected', 'Verified'],
      agentPhone: '+234 000 000 000',
      isVerified: true,
      proximityToRoadMeters: 50,
      electricitySupplyHours: 24,
      hasRunningWater: true,
      proximityToHospitalKm: 2.0,
      videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    );

    // Mock due date for rentals or installment payments
    final DateTime? mockDueDate = tx.state == EscrowState.overdue 
        ? DateTime.now().subtract(const Duration(days: 2)) 
        : DateTime.now().add(const Duration(days: 15));

    return UnifiedCommitment(
      id: tx.id,
      property: property,
      type: CommitmentType.deal,
      originalObject: tx,
      statusLabel: _getEscrowStatusLabel(tx.state),
      nextActionLabel: _getEscrowNextAction(tx.state),
      progress: tx.state == EscrowState.released ? 1.0 : 0.6,
      dueDate: mockDueDate,
      checklist: [
        ChecklistItem(label: 'Price Agreement', isDone: true),
        ChecklistItem(label: 'Escrow Account Setup', isDone: true),
        ChecklistItem(label: 'Initial Deposit Received', isDone: tx.state != EscrowState.awaitingPayment),
        ChecklistItem(label: 'Legal Document Verification', isDone: tx.state == EscrowState.released || tx.state == EscrowState.inspectionPassed),
        ChecklistItem(label: 'Final Balance Settle', isDone: tx.state == EscrowState.released),
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

  static String _getEscrowStatusLabel(EscrowState state) {
    switch (state) {
      case EscrowState.awaitingPayment: return 'Payment Pending';
      case EscrowState.held: return 'Funds Secured';
      case EscrowState.inspectionPassed: return 'Ready for Finalize';
      case EscrowState.released: return 'Deal Closed';
      case EscrowState.refunded: return 'Refunded';
      case EscrowState.overdue: return 'Action Required!';
    }
  }

  static String _getEscrowNextAction(EscrowState state) {
    switch (state) {
      case EscrowState.overdue: return 'Settle Payment';
      case EscrowState.inspectionPassed: return 'Proceed with Final Step';
      case EscrowState.released: return 'Transfer Ownership';
      default: return 'Track Milestones';
    }
  }
}
