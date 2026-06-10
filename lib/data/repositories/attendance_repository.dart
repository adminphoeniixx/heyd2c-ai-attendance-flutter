import 'package:uuid/uuid.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/time_utils.dart';
import '../local/local_db.dart';
import '../models/attendance_log.dart';
import '../models/punch_response.dart';
import '../remote/api_service.dart';

class AttendanceRepository {
  final _api = ApiService.instance;
  final _db = LocalDb.instance;
  final _uuid = const Uuid();

  String nextPunchType(int employeeId, {DateTime? now}) {
    final date = _dateKey(now ?? DateTime.now());
    final logs = _logsForEmployeeOnDate(employeeId, date);
    if (logs.isEmpty) return 'punch_in';
    return logs.last.isPunchIn ? 'punch_out' : 'punch_in';
  }

  /// Save locally first (instant UI), then try to sync in background.
  /// Returns [PunchResponse] from server on success, or null if offline.
  Future<({PunchResponse? response, AttendanceLog log})> punch({
    required int employeeId,
    required String employeeName,
    required String type, // 'punch_in' | 'punch_out'
    required bool isOnline,
  }) async {
    final time = TimeUtils.nowHHmmss();
    final log = AttendanceLog(
      localId: _uuid.v4(),
      employeeId: employeeId,
      employeeName: employeeName,
      type: type,
      punchTime: time,
      createdAt: DateTime.now().toIso8601String(),
      syncStatus: employeeId < 0 ? 'local_only' : 'pending',
    );

    // ── 1. Save locally FIRST ────────────────────────────────────────────
    await _db.saveLog(log);
    appLogger.i('Punch saved locally: $type for $employeeName at $time');

    if (!isOnline || employeeId < 0) {
      return (response: null, log: log);
    }

    // ── 2. Try immediate server sync ─────────────────────────────────────
    try {
      final response = type == 'punch_in'
          ? await _api.punchIn(employeeId, time, clientLogId: log.localId)
          : await _api.punchOut(employeeId, time, clientLogId: log.localId);
      await _db.updateLogStatus(log.localId, 'synced',
          message: response.message);
      appLogger.i('Punch synced: ${response.message}');
      return (response: response, log: log);
    } catch (e) {
      // Server call failed — log stays pending, background sync will retry
      appLogger.w('Punch offline queued: $e');
      return (response: null, log: log);
    }
  }

  List<AttendanceLog> getPending() => _db.getPendingLogs();
  List<AttendanceLog> getAll() => _db.getAllLogs();
  int get pendingCount => _db.pendingSyncCount;

  Future<int> completeMissedPunchOuts({DateTime? now}) async {
    final today = _dateKey(now ?? DateTime.now());
    final logs = _db.getAllLogs()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final grouped = <String, List<AttendanceLog>>{};
    for (final log in logs) {
      final date = _dateFromCreatedAt(log.createdAt);
      if (date == today) continue;
      grouped.putIfAbsent('${log.employeeId}|$date', () => []).add(log);
    }

    var closed = 0;
    for (final entry in grouped.entries) {
      final group = entry.value;
      if (group.isEmpty || !group.last.isPunchIn) continue;

      final date = _dateFromCreatedAt(group.last.createdAt);
      final log = AttendanceLog(
        localId: _uuid.v4(),
        employeeId: group.last.employeeId,
        employeeName: group.last.employeeName,
        type: 'punch_out',
        punchTime: '23:59:59',
        createdAt: '${date}T23:59:59',
        autoClosed: true,
        flagTag: 'Missed punch out',
        flagDate: date,
      );
      await _db.saveLog(log);
      closed++;
      appLogger.w('Auto punch-out added for ${log.employeeName} on $date');
    }

    return closed;
  }

  /// All logs created today (local device date)
  List<AttendanceLog> todaysLogs() {
    final today = TimeUtils.todayKey(); // yyyy-MM-dd
    return _db.getAllLogs().where((l) => l.createdAt.startsWith(today)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<AttendanceLog> _logsForEmployeeOnDate(int employeeId, String date) {
    return _db
        .getAllLogs()
        .where(
            (l) => l.employeeId == employeeId && l.createdAt.startsWith(date))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  String _dateKey(DateTime value) => '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  String _dateFromCreatedAt(String createdAt) =>
      createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;
}
