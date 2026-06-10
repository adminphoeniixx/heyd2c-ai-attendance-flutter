class PunchResponse {
  final bool   success;
  final String type;          // 'punch_in' | 'punch_out'
  final String message;
  final String name;
  final String time;
  final bool   isFirst;
  final bool   isLate;
  final int    lateMinutes;
  final double workedHours;
  final String status;        // 'present' | 'half_day' | ''
  final int    punchCount;

  const PunchResponse({
    required this.success,
    required this.type,
    required this.message,
    required this.name,
    required this.time,
    this.isFirst     = false,
    this.isLate      = false,
    this.lateMinutes = 0,
    this.workedHours = 0,
    this.status      = '',
    this.punchCount  = 0,
  });

  factory PunchResponse.fromJson(Map<String, dynamic> j) => PunchResponse(
        success:     j['success'] as bool? ?? false,
        type:        j['type']?.toString() ?? '',
        message:     j['message']?.toString() ?? '',
        name:        j['name']?.toString() ?? '',
        time:        j['time']?.toString() ?? '',
        isFirst:     j['is_first'] as bool? ?? false,
        isLate:      j['is_late'] as bool? ?? false,
        lateMinutes: (j['late_minutes'] as num?)?.toInt() ?? 0,
        workedHours: (j['worked_hours'] as num?)?.toDouble() ?? 0,
        status:      j['status']?.toString() ?? '',
        punchCount:  (j['punch_count'] as num?)?.toInt() ?? 0,
      );

  bool get isPunchIn  => type == 'punch_in';
  bool get isPunchOut => type == 'punch_out';
}
