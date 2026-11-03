import 'event_model.dart';
import 'ticket_model.dart';

class RsvpItem {
  final int rsvpId;
  final String status;
  final DateTime registeredAt;
  final Event event;
  final Ticket? ticket;

  RsvpItem({
    required this.rsvpId,
    required this.status,
    required this.registeredAt,
    required this.event,
    this.ticket,
  });

  int get id => rsvpId;

  factory RsvpItem.fromJson(Map<String, dynamic> json) {
    return RsvpItem(
      rsvpId: json['rsvp_id'] as int? ?? 0,
      status: json['status']?.toString() ?? 'confirmed',
      registeredAt: json['registered_at'] != null
          ? DateTime.tryParse(json['registered_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      event: Event.fromJson(json['event'] is Map<String, dynamic>
          ? json['event']
          : {}),
      ticket: json['ticket'] != null && json['ticket'] is Map<String, dynamic>
          ? Ticket.fromJson(json['ticket'])
          : null,
    );
  }
}