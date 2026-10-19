class Ticket {
  final int ticketId;
  final String qrCode;
  final DateTime issuedAt;
  final bool isCheckedIn;
  final DateTime? checkedInAt;

  Ticket({
    required this.ticketId,
    required this.qrCode,
    required this.issuedAt,
    this.isCheckedIn = false,
    this.checkedInAt,
  });

  int get id => ticketId;

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      ticketId: json['ticket_id'] as int? ?? 0,
      qrCode: json['qr_code']?.toString() ?? '',
      issuedAt: json['issued_at'] != null
          ? DateTime.tryParse(json['issued_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isCheckedIn: json['is_checked_in'] == true,
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.tryParse(json['checked_in_at'].toString())
          : null,
    );
  }
}