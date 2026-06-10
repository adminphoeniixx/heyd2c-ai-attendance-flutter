import 'package:get/get.dart';
import '../../core/utils/app_logger.dart';
import '../../data/local/local_db.dart';
import '../../data/models/attendance_log.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/pending_employee.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/employee_repository.dart';

class EmployeeController extends GetxController {
  final _repo = EmployeeRepository();
  final _attRepo = AttendanceRepository();
  final _db = LocalDb.instance;

  final isLoading = false.obs;
  final errorMsg = ''.obs;
  final employees = <EmployeeModel>[].obs;
  final pendingEmployees = <PendingEmployee>[].obs;
  final attendanceStatuses = <int, EmployeeAttendanceStatus>{}.obs;
  final searchQuery = ''.obs;

  // ── Derived lists ─────────────────────────────────────────────────────────

  List<EmployeeModel> get filtered {
    final q = searchQuery.value.toLowerCase().trim();
    if (q.isEmpty) return employees;
    return employees
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            e.employeeId.toLowerCase().contains(q) ||
            e.department.toLowerCase().contains(q))
        .toList();
  }

  List<PendingEmployee> get filteredPending {
    final q = searchQuery.value.toLowerCase().trim();
    if (q.isEmpty) return pendingEmployees;
    return pendingEmployees
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            e.employeeId.toLowerCase().contains(q) ||
            e.department.toLowerCase().contains(q))
        .toList();
  }

  int get registeredCount => employees.where((e) => e.hasFace).length;
  int get pendingCount => pendingEmployees.length;

  EmployeeAttendanceStatus attendanceStatusFor(int employeeId) =>
      attendanceStatuses[employeeId] ?? EmployeeAttendanceStatus.notMarked();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    loadEmployees();
  }

  Future<void> loadEmployees() async {
    errorMsg.value = '';

    // 1. Show cached data immediately — instant, no wait
    employees.value        = _repo.getCached();
    pendingEmployees.value = _db.getPendingQueuedEmployees();
    _loadAttendanceStatuses();

    // 2. Sync from server in background and refresh list when done
    isLoading.value = true;
    try {
      await _repo.syncEmployees();
      employees.value        = _repo.getCached();
      pendingEmployees.value = _db.getPendingQueuedEmployees();
      _loadAttendanceStatuses();
    } catch (e) {
      appLogger.e('Employee sync error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async => loadEmployees();

  void search(String q) => searchQuery.value = q;

  void _loadAttendanceStatuses() {
    final logs = _attRepo.todaysLogs()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final grouped = <int, List<AttendanceLog>>{};
    for (final log in logs) {
      grouped.putIfAbsent(log.employeeId, () => []).add(log);
    }

    attendanceStatuses.value = grouped.map((employeeId, employeeLogs) {
      final last = employeeLogs.last;
      final punchIns = employeeLogs.where((log) => log.isPunchIn).toList();
      final punchOuts = employeeLogs.where((log) => log.isPunchOut).toList();
      return MapEntry(
        employeeId,
        EmployeeAttendanceStatus(
          label: last.isPunchIn ? 'Punched In' : 'Punched Out',
          time: last.punchTime,
          isIn: last.isPunchIn,
          firstPunchIn: punchIns.isNotEmpty ? punchIns.first.punchTime : '',
          lastPunchOut: punchOuts.isNotEmpty ? punchOuts.last.punchTime : '',
          punchCount: employeeLogs.length,
          autoClosed: last.autoClosed,
        ),
      );
    });
  }

  Future<void> deleteEmployee(EmployeeModel emp) async {
    isLoading.value = true;
    try {
      await _repo.deleteEmployee(emp.id);
      employees.removeWhere((e) => e.id == emp.id);
    } catch (e) {
      appLogger.e('Employee delete error: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deletePendingEmployee(PendingEmployee emp) async {
    await _db.removeQueuedEmployee(emp.localId);
    pendingEmployees.removeWhere((e) => e.localId == emp.localId);
  }
}

class EmployeeAttendanceStatus {
  final String label;
  final String time;
  final bool isIn;
  final String firstPunchIn;
  final String lastPunchOut;
  final int punchCount;
  final bool autoClosed;

  const EmployeeAttendanceStatus({
    required this.label,
    required this.time,
    required this.isIn,
    this.firstPunchIn = '',
    this.lastPunchOut = '',
    required this.punchCount,
    this.autoClosed = false,
  });

  factory EmployeeAttendanceStatus.notMarked() =>
      const EmployeeAttendanceStatus(
        label: 'Not Marked',
        time: '',
        isIn: false,
        punchCount: 0,
      );

  bool get hasPunch => punchCount > 0;
}
