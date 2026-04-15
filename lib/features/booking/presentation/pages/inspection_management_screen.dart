import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/features/property/domain/entities/property.dart';
import 'package:swiftspace/features/booking/domain/entities/booking.dart';
import 'package:swiftspace/features/booking/presentation/state/booking_provider.dart';
import 'package:swiftspace/features/booking/domain/entities/commitment.dart';
import 'package:swiftspace/features/booking/presentation/pages/property_management_screen.dart';

class InspectionManagementScreen extends StatefulWidget {
  final Property property;

  const InspectionManagementScreen({super.key, required this.property});

  @override
  State<InspectionManagementScreen> createState() => _InspectionManagementScreenState();
}

class _InspectionManagementScreenState extends State<InspectionManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Seed some mock bookings so the agent has something to manage!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false)
          .seedMockBookingsForProperty(widget.property);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Inspections'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, child) {
          final bookings = provider.getBookingsForProperty(widget.property.id);

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.calendarCheck, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No inspection requests found.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('Share your property to get leads.', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _buildBookingActionCard(booking, provider, theme, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingActionCard(InspectionBooking booking, BookingProvider provider, ThemeData theme, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: InkWell(
        onTap: () {
          // Normal detail view fallback
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyManagementScreen(
                commitment: UnifiedCommitment.fromBooking(booking),
                isAgent: true,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Icon(LucideIcons.user, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Prospective Lead', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Awaiting Agent Reply', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  _buildStatusBadge(booking.status, theme),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Requested for: ${_formatDate(booking.dateTime)}',
                      style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (booking.clientNotes != null && booking.clientNotes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('"${booking.clientNotes!}"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              ],
              const SizedBox(height: 16),
              
              // Agent Triage Actions
              if (booking.status == BookingStatus.pending)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTriageButton(
                      icon: LucideIcons.check,
                      label: 'Accept',
                      color: Colors.green,
                      onTap: () {
                        provider.updateBookingStatus(booking.id, BookingStatus.confirmed);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inspection confirmed!')));
                      },
                    ),
                    _buildTriageButton(
                      icon: LucideIcons.calendarClock,
                      label: 'Reschedule',
                      color: Colors.orange,
                      onTap: () async {
                        final newDate = await showDatePicker(
                          context: context,
                          initialDate: booking.dateTime,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (newDate != null && mounted) {
                           final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(booking.dateTime));
                           if (time != null && mounted) {
                              final fullDateTime = DateTime(newDate.year, newDate.month, newDate.day, time.hour, time.minute);
                              provider.postponeBooking(booking.id, fullDateTime, 'Agent proposed new time.');
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rescheduled and sent to client.')));
                           }
                        }
                      },
                    ),
                    _buildTriageButton(
                      icon: LucideIcons.x,
                      label: 'Decline',
                      color: Colors.red,
                      onTap: () {
                        provider.updateBookingStatus(booking.id, BookingStatus.declined);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking declined.')));
                      },
                    ),
                  ],
                ),
              
              if (booking.status != BookingStatus.pending)
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PropertyManagementScreen(
                            commitment: UnifiedCommitment.fromBooking(booking),
                            isAgent: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.arrowRight),
                    label: const Text('Manage Deal Circle'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status, ThemeData theme) {
    Color color;
    String label;
    switch (status) {
      case BookingStatus.pending: label = 'Pending'; color = Colors.orange; break;
      case BookingStatus.confirmed: label = 'Confirmed'; color = Colors.green; break;
      case BookingStatus.commenced: label = 'Ongoing'; color = Colors.blue; break;
      case BookingStatus.finalized: label = 'Finalized'; color = Colors.teal; break;
      case BookingStatus.completed: label = 'Completed'; color = theme.colorScheme.primary; break;
      case BookingStatus.declined: label = 'Declined'; color = Colors.red; break;
      case BookingStatus.cancelled: label = 'Cancelled'; color = Colors.grey; break;
      case BookingStatus.postponed: label = 'Rescheduled'; color = Colors.purple; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTriageButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
