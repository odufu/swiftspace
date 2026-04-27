import 'package:flutter/material.dart';
import 'package:swiftspace/features/booking/domain/entities/booking.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';

class BookingProvider with ChangeNotifier {
  final List<InspectionBooking> _bookings = [];

  List<InspectionBooking> get bookings => [..._bookings];

  void addBooking(InspectionBooking booking) {
    _bookings.insert(0, booking);
    notifyListeners();
  }

  void updateBookingStatus(String id, BookingStatus status) {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(status: status);
      notifyListeners();
    }
  }

  void postponeBooking(String id, DateTime newDate, String reason) {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      final old = _bookings[index];
      _bookings[index] = old.copyWith(
        status: BookingStatus.postponed,
        dateTime: newDate,
        postponementReason: reason,
        originalDateTime: old.originalDateTime ?? old.dateTime,
      );
      notifyListeners();
    }
  }

  void finalizeInspection(String id, String notes) {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(
        status: BookingStatus.finalized,
        agentNotes: notes,
      );
      notifyListeners();
    }
  }

  /// Step 6 + 7: Client approves → booking becomes completed.
  void rateAgent(String id, int rating, String review) {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(
        status: BookingStatus.completed,
        clientRating: rating,
        clientReview: review,
        isClientApproved: true,
      );
      notifyListeners();
    }
  }

  /// Allows the client to cancel their own booking.
  void cancelBooking(String id) {
    updateBookingStatus(id, BookingStatus.cancelled);
  }

  List<InspectionBooking> getBookingsForProperty(String propertyId) {
    return _bookings.where((b) => b.property.id == propertyId).toList();
  }

  void seedMockBookingsForProperty(Property property) {
    // Only seed if empty for this property to avoid infinite additions
    if (getBookingsForProperty(property.id).isNotEmpty) return;

    // Inject 2 mock pending leads and 1 confirmed lead
    _bookings.addAll([
      InspectionBooking(
        id: 'mock_lead_1_${property.id}',
        property: property,
        dateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        originalDateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        status: BookingStatus.pending,
        clientNotes: 'I am very interested, please confirm if we can do 2 PM.',
      ),
      InspectionBooking(
        id: 'mock_lead_2_${property.id}',
        property: property,
        dateTime: DateTime.now().add(const Duration(days: 3, hours: 5)),
        originalDateTime: DateTime.now().add(const Duration(days: 3, hours: 5)),
        status: BookingStatus.pending,
        clientNotes: 'Can I bring my architect along? Call me.',
      ),
      InspectionBooking(
        id: 'mock_lead_3_${property.id}',
        property: property,
        dateTime: DateTime.now().add(const Duration(days: 2)),
        originalDateTime: DateTime.now().add(const Duration(days: 2)),
        status: BookingStatus.confirmed, // Already accepted
        clientNotes: 'Thanks for confirming!',
      ),
    ]);
    notifyListeners();
  }
}
