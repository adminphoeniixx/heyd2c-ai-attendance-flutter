import 'package:get/get.dart';
import '../../core/utils/app_logger.dart';
import '../../data/local/local_db.dart';
import '../../data/models/attendance_log.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/remote/api_service.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/employee_repository.dart';

class TodayController extends GetxController {
  final _api = ApiService.instance;
  final _attRepo = AttendanceRepository();
  final _empRepo = EmployeeRepository();
  final _db = LocalDb.instance;

  final isLoading = false.obs;
  final errorMsg = ''.obs;
  final employees = <TodayEmployeeStatus>[].obs;
  final localLogs = <AttendanceLog>[].obs;
  final showLocalLogs = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadToday();
  }

  Future<void> loadToday() async {
    isLoading.value = true;
    errorMsg.value = '';
    final logs = _attRepo.todaysLogs();
    localLogs.value = logs;

    var serverEmployees = <TodayEmployeeStatus>[];
    try {
      final dash = await _api.getToday();
      serverEmployees = dash.employees;
    } catch (e) {
      errorMsg.value = 'Could not load from server';
      appLogger.e('Today load error: $e');
    }

    employees.value = _mergeLocalPunches(serverEmployees, logs);
    isLoading.value = false;
  }

  @override
  Future<void> refresh() async => loadToday();

  void toggleView() => showLocalLogs.value = !showLocalLogs.value;

  String get viewLabel => showLocalLogs.value ? 'Server View' : 'Local Logs';

  List<TodayEmployeeStatus> _mergeLocalPunches(
    List<TodayEmployeeStatus> serverEmployees,
    List<AttendanceLog> logs,
  ) {
    final groupedLogs = <int, List<AttendanceLog>>{};
    final sortedLogs = logs.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final log in sortedLogs) {
      groupedLogs.putIfAbsent(log.employeeId, () => []).add(log);
    }

    final cachedEmployees = {
      for (final emp in _empRepo.getCached()) emp.id: emp,
    };
    final pendingEmployees = {
      for (final emp in _db.getPendingQueuedEmployees())
        emp.serverId ?? emp.localEmployeeId: emp,
    };

    final merged = <TodayEmployeeStatus>[];
    final seen = <int>{};

    for (final serverEmp in serverEmployees) {
      seen.add(serverEmp.id);
      final local = groupedLogs[serverEmp.id];
      merged.add(local == null || local.isEmpty
          ? serverEmp
          : _statusFromLogs(
              id: serverEmp.id,
              name: serverEmp.name,
              designation: serverEmp.designation,
              department: serverEmp.department,
              logs: local,
              fallback: serverEmp,
            ));
    }

    for (final entry in groupedLogs.entries) {
      if (seen.contains(entry.key)) continue;
      final cached = cachedEmployees[entry.key];
      final pending = pendingEmployees[entry.key];
      merged.add(_statusFromLogs(
        id: entry.key,
        name: cached?.name ?? pending?.name ?? entry.value.last.employeeName,
        designation: cached?.designation ?? pending?.designation ?? '',
        department: cached?.department ?? pending?.department ?? '',
        logs: entry.value,
      ));
    }

    merged.sort((a, b) {
      final aHasPunch = a.punches.isNotEmpty;
      final bHasPunch = b.punches.isNotEmpty;
      if (aHasPunch != bHasPunch) return aHasPunch ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return merged;
  }

  TodayEmployeeStatus _statusFromLogs({
    required int id,
    required String name,
    required String designation,
    required String department,
    required List<AttendanceLog> logs,
    TodayEmployeeStatus? fallback,
  }) {
    final sorted = logs.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final punchIns = sorted.where((log) => log.isPunchIn).toList();
    final punchOuts = sorted.where((log) => log.isPunchOut).toList();
    final last = sorted.last;

    return TodayEmployeeStatus(
      id: id,
      name: name,
      designation: designation,
      department: department,
      status: sorted.isEmpty ? 'not_marked' : 'present',
      currentState: last.isPunchIn ? 'in' : 'out',
      checkIn:
          punchIns.isNotEmpty ? punchIns.first.punchTime : fallback?.checkIn,
      checkOut:
          punchOuts.isNotEmpty ? punchOuts.last.punchTime : fallback?.checkOut,
      isLate: fallback?.isLate ?? false,
      lateMinutes: fallback?.lateMinutes ?? 0,
      workedHours: fallback?.workedHours ?? 0,
      punchCount: sorted.length,
      punches: sorted
          .map((log) => {
                'type': log.type,
                'time': log.punchTime,
                if (log.autoClosed) 'auto_closed': 'true',
              })
          .toList(),
    );
  }
}
