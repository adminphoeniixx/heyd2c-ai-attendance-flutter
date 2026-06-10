import 'package:uuid/uuid.dart';
import '../../core/utils/app_logger.dart';
import '../local/local_db.dart';
import '../models/employee_model.dart';
import '../models/pending_face_sync.dart';
import '../remote/api_service.dart';

class EmployeeRepository {
  final _api  = ApiService.instance;
  final _db   = LocalDb.instance;
  final _uuid = const Uuid();

  /// Create a new employee on the server, then save locally
  Future<EmployeeModel> createEmployee({
    required String name,
    required String employeeId,
    required String designation,
    required String department,
    String? faceEncoding,
  }) async {
    final emp = await _api.createEmployee(
      name: name,
      employeeId: employeeId,
      designation: designation,
      department: department,
      faceEncoding: faceEncoding,
    );
    await _db.updateEmployee(emp);
    appLogger.i('Employee created: ${emp.name} (id=${emp.id})');
    return emp;
  }

  /// Fetch from server, save locally, return list
  Future<List<EmployeeModel>> syncEmployees() async {
    final list = await _api.getEmployees();
    await _db.saveEmployees(list);
    appLogger.i('Employees synced: ${list.length}');
    return list;
  }

  /// Return cached list — no network call
  List<EmployeeModel> getCached() => _db.getAllEmployees();

  /// Employees that have a face registered (for matching)
  List<EmployeeModel> getFaceRegistered() {
    final synced = _db.getFaceRegisteredEmployees();
    final pending = _db
        .getAllQueuedEmployees()
        .where((e) => e.faceEncoding != null && e.faceEncoding!.isNotEmpty)
        .map(
          (e) => EmployeeModel(
            id: e.serverId ?? e.localEmployeeId,
            employeeId: e.employeeId,
            name: e.name,
            designation: e.designation,
            department: e.department,
            hasFace: true,
            faceEncoding: e.faceEncoding!,
          ),
        );
    final byId = <int, EmployeeModel>{};
    for (final emp in [...synced, ...pending]) {
      byId[emp.id] = emp;
    }
    final list = byId.values.toList();
    appLogger.i(
      'Local face registered employees: ${list.length} '
      '(${list.map((e) => '${e.name}:${e.embeddingVector.length}').join(', ')})',
    );
    return list;
  }

  Future<void> deleteEmployee(int employeeId) async {
    await _api.deleteEmployee(employeeId);
    await _db.deleteEmployee(employeeId);
    appLogger.i('Employee deleted: id=$employeeId');
  }

  Future<void> saveFace(int employeeId, String encoding) async {
    // 1. Always save locally first — instant, never fails
    final emp = _db.getEmployee(employeeId);
    if (emp != null) {
      await _db
          .updateEmployee(emp.copyWith(hasFace: true, faceEncoding: encoding));
    }
    appLogger.i('Face saved locally for employee $employeeId');

    // 2. Try uploading to server immediately
    try {
      await _api.saveFace(employeeId, encoding);
      appLogger.i('Face synced to server for employee $employeeId');
      // Remove any stale pending queue entry for this employee
      final stale = _db
          .getAllPendingFaceSyncs()
          .where((f) => f.employeeId == employeeId);
      for (final f in stale) {
        await _db.removeFaceSync(f.localId);
      }
    } catch (e) {
      // 3. Offline / error — add to retry queue
      appLogger.w('Face upload failed, queued for retry: $e');
      final pending = PendingFaceSync(
        localId:      _uuid.v4(),
        employeeId:   employeeId,
        faceEncoding: encoding,
      );
      await _db.savePendingFaceSync(pending);
    }
  }

  Future<void> deleteFace(int employeeId) async {
    await _api.deleteFace(employeeId);
    final emp = _db.getEmployee(employeeId);
    if (emp != null) {
      await _db.updateEmployee(emp.copyWith(hasFace: false, faceEncoding: ''));
    }
  }
}
