class DashboardSummary {
  final int total;
  final int present;
  final int notMarked;
  final int currentlyIn;
  final int late;

  const DashboardSummary({
    required this.total,
    required this.present,
    required this.notMarked,
    required this.currentlyIn,
    required this.late,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> j) =>
      DashboardSummary(
        total:       (j['total'] as num?)?.toInt() ?? 0,
        present:     (j['present'] as num?)?.toInt() ?? 0,
        notMarked:   (j['not_marked'] as num?)?.toInt() ?? 0,
        currentlyIn: (j['currently_in'] as num?)?.toInt() ?? 0,
        late:        (j['late'] as num?)?.toInt() ?? 0,
      );
}

class TodayEmployeeStatus {
  final int    id;
  final String name;
  final String designation;
  final String department;
  final String status;        // 'present' | 'not_marked'
  final String currentState;  // 'in' | 'out' | 'not_started'
  final String? checkIn;
  final String? checkOut;
  final bool   isLate;
  final int    lateMinutes;
  final double workedHours;
  final int    punchCount;
  final List<Map<String, String>> punches;

  const TodayEmployeeStatus({
    required this.id,
    required this.name,
    required this.designation,
    required this.department,
    required this.status,
    required this.currentState,
    this.checkIn,
    this.checkOut,
    this.isLate      = false,
    this.lateMinutes = 0,
    this.workedHours = 0,
    this.punchCount  = 0,
    this.punches     = const [],
  });

  factory TodayEmployeeStatus.fromJson(Map<String, dynamic> j) =>
      TodayEmployeeStatus(
        id:           (j['id'] as num).toInt(),
        name:         j['name']?.toString() ?? '',
        designation:  j['designation']?.toString() ?? '',
        department:   j['department']?.toString() ?? '',
        status:       j['status']?.toString() ?? 'not_marked',
        currentState: j['current_state']?.toString() ?? 'not_started',
        checkIn:      j['check_in']?.toString(),
        checkOut:     j['check_out']?.toString(),
        isLate:       j['is_late'] as bool? ?? false,
        lateMinutes:  (j['late_minutes'] as num?)?.toInt() ?? 0,
        workedHours:  (j['worked_hours'] as num?)?.toDouble() ?? 0,
        punchCount:   (j['punch_count'] as num?)?.toInt() ?? 0,
        punches: (j['punches'] as List<dynamic>? ?? [])
            .map((p) => Map<String, String>.from(p as Map))
            .toList(),
      );

  bool get isCurrentlyIn => currentState == 'in';
}

class DashboardModel {
  final String           date;
  final DashboardSummary summary;
  final List<TodayEmployeeStatus> employees;

  const DashboardModel({
    required this.date,
    required this.summary,
    required this.employees,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> j) => DashboardModel(
        date:    j['date']?.toString() ?? '',
        summary: DashboardSummary.fromJson(
            j['summary'] as Map<String, dynamic>? ?? {}),
        employees: (j['employees'] as List<dynamic>? ?? [])
            .map((e) => TodayEmployeeStatus.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Thin wrapper used in face-scan to know punch direction
extension EmployeePunchState on TodayEmployeeStatus {
  /// Returns 'punch_in' or 'punch_out' based on current state
  String get nextPunchType =>
      currentState == 'in' ? 'punch_out' : 'punch_in';
}
