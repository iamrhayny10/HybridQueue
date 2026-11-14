// lib/models/ticket_model.dart

enum TicketStatus { waiting, serving, served, skipped, unknown }

class TicketModel {
  final int          ticketId;
  final int          userId;
  final String       ticketNumber;
  final String       serviceType;
  final int?         windowId;
  final String?      windowName;
  final String?      fullName;
  final String?      studentId;
  final DateTime     issuedAt;
  final DateTime?    calledAt;
  final DateTime?    servedAt;
  final TicketStatus status;
  final double?      predictedErt;
  final double?      baseTime;
  final int          skipCount;
  final String?      purpose;
  final bool         isPriority;

  const TicketModel({
    required this.ticketId,
    required this.userId,
    required this.ticketNumber,
    required this.serviceType,
    this.windowId,
    this.windowName,
    this.fullName,
    this.studentId,
    required this.issuedAt,
    this.calledAt,
    this.servedAt,
    required this.status,
    this.predictedErt,
    this.baseTime,
    this.skipCount = 0,
    this.purpose,
    this.isPriority = false,
  });

  factory TicketModel.fromJson(Map<String, dynamic> j) {
    return TicketModel(
      ticketId:     j['ticket_id']     as int,
      userId:       j['user_id']       as int,
      ticketNumber: j['ticket_number'] as String,
      serviceType:  j['service_type']  as String,
      windowId:     j['window_id'] != null
          ? int.tryParse(j['window_id'].toString())
          : null,
      windowName:   j['window_name']   as String?,
      fullName:     j['full_name']     as String?,
      studentId:    j['student_id']    as String?,
      issuedAt:     DateTime.parse(j['issued_at'] as String),
      calledAt:     j['called_at'] != null
          ? DateTime.tryParse(j['called_at'] as String)
          : null,
      servedAt:     j['served_at'] != null
          ? DateTime.tryParse(j['served_at'] as String)
          : null,
      status: switch ((j['status'] as String).toLowerCase()) {
        'waiting' => TicketStatus.waiting,
        'serving' => TicketStatus.serving,
        'served'  => TicketStatus.served,
        'skipped' => TicketStatus.skipped,
        _         => TicketStatus.unknown,
      },
      predictedErt: j['predicted_ert'] != null
          ? double.tryParse(j['predicted_ert'].toString())
          : null,
      baseTime: j['base_time'] != null
          ? double.tryParse(j['base_time'].toString())
          : null,
      skipCount: j['skip_count'] != null
          ? int.tryParse(j['skip_count'].toString()) ?? 0
          : 0,
      purpose: j['purpose'] as String?,
      isPriority: j['is_priority'] != null &&
          j['is_priority'].toString() == '1',
    );
  }

  bool get isActive =>
      status == TicketStatus.waiting || status == TicketStatus.serving;

  String get statusLabel => switch (status) {
    TicketStatus.waiting => 'Waiting',
    TicketStatus.serving => 'Being Served',
    TicketStatus.served  => 'Served',
    TicketStatus.skipped => 'Skipped',
    _                    => 'Unknown',
  };

  String get ertDisplay {
    if (status == TicketStatus.serving) return 'Now!';
    if (status == TicketStatus.served)  return 'Done';
    if (predictedErt != null) {
      return '~${predictedErt!.toStringAsFixed(0)} min';
    }
    return '—';
  }

  String get issuedTimeDisplay {
    final h = issuedAt.hour.toString().padLeft(2, '0');
    final m = issuedAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
