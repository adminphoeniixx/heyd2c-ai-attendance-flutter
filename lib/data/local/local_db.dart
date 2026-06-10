import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/attendance_log.dart';
import '../models/employee_model.dart';
import '../models/pending_employee.dart';
import '../models/pending_face_sync.dart';
import '../../core/constants/storage_keys.dart';

/// Single access point for all Hive reads/writes.
/// All boxes are opened in main.dart before runApp.
class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  // ── Settings ──────────────────────────────────────────────────────────────

  Box<String> get _settings => Hive.box<String>(StorageKeys.settingsBox);

  Future<void> saveSetting(String key, String value) =>
      _settings.put(key, value);

  String? getSetting(String key) => _settings.get(key);

  Future<void> deleteSetting(String key) => _settings.delete(key);

  // ── Employees ─────────────────────────────────────────────────────────────

  Box<String> get _empBox => Hive.box<String>(StorageKeys.employeeBox);

  Future<void> saveEmployees(List<EmployeeModel> list) async {
    final existing = {
      for (final e in getAllEmployees()) e.id: e,
    };
    final map = <String, String>{};
    for (final e in list) {
      final old = existing[e.id];
      final keepLocalFace = old != null &&
          old.hasFace &&
          old.faceEncoding.isNotEmpty &&
          (!e.hasFace || e.faceEncoding.isEmpty);
      final merged = keepLocalFace
          ? e.copyWith(hasFace: true, faceEncoding: old.faceEncoding)
          : e;
      map[e.id.toString()] = jsonEncode(merged.toJson());
    }
    await _empBox.putAll(map);
  }

  List<EmployeeModel> getAllEmployees() {
    return _empBox.values
        .map((raw) =>
            EmployeeModel.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  EmployeeModel? getEmployee(int id) {
    final raw = _empBox.get(id.toString());
    if (raw == null) return null;
    return EmployeeModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> updateEmployee(EmployeeModel emp) =>
      _empBox.put(emp.id.toString(), jsonEncode(emp.toJson()));

  Future<void> deleteEmployee(int id) => _empBox.delete(id.toString());

  Future<void> clearEmployees() => _empBox.clear();

  /// Returns only employees who have a face encoding (for matching)
  List<EmployeeModel> getFaceRegisteredEmployees() => getAllEmployees()
      .where((e) => e.hasFace && e.faceEncoding.isNotEmpty)
      .toList();

  // ── Attendance Logs ───────────────────────────────────────────────────────

  Box<String> get _attBox => Hive.box<String>(StorageKeys.attendanceBox);

  Future<void> saveLog(AttendanceLog log) =>
      _attBox.put(log.localId, jsonEncode(log.toJson()));

  List<AttendanceLog> getAllLogs() => _attBox.values
      .map((raw) =>
          AttendanceLog.fromJson(jsonDecode(raw) as Map<String, dynamic>))
      .toList();

  List<AttendanceLog> getPendingLogs() =>
      getAllLogs().where((l) => l.isPending).toList();

  Future<void> updateLogStatus(String localId, String status,
      {String? message}) async {
    final raw = _attBox.get(localId);
    if (raw == null) return;
    final log = AttendanceLog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    log.syncStatus = status;
    log.syncAttempts += 1;
    log.serverMessage = message;
    await _attBox.put(localId, jsonEncode(log.toJson()));
  }

  Future<void> clearSyncedLogs() async {
    final toDelete =
        getAllLogs().where((l) => l.isSynced).map((l) => l.localId).toList();
    await _attBox.deleteAll(toDelete);
  }

  // ── Employee Sync Queue ───────────────────────────────────────────────────

  Box<String> get _empSyncBox => Hive.box<String>(StorageKeys.employeeSyncBox);

  Future<void> saveQueuedEmployee(PendingEmployee e) =>
      _empSyncBox.put(e.localId, jsonEncode(e.toJson()));

  List<PendingEmployee> getAllQueuedEmployees() => _empSyncBox.values
      .map((raw) =>
          PendingEmployee.fromJson(jsonDecode(raw) as Map<String, dynamic>))
      .toList();

  List<PendingEmployee> getPendingQueuedEmployees() =>
      getAllQueuedEmployees().where((e) => e.isPending).toList();

  Future<void> updateQueuedEmployee(
    String localId,
    String status, {
    int? serverId,
  }) async {
    final raw = _empSyncBox.get(localId);
    if (raw == null) return;
    final e = PendingEmployee.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    e.syncStatus = status;
    e.syncAttempts += 1;
    if (serverId != null) e.serverId = serverId;
    await _empSyncBox.put(localId, jsonEncode(e.toJson()));
  }

  Future<void> removeQueuedEmployee(String localId) =>
      _empSyncBox.delete(localId);

  int get pendingEmployeeSyncCount => getPendingQueuedEmployees().length;

  // ── Face Sync Queue ───────────────────────────────────────────────────────

  Box<String> get _faceSyncBox => Hive.box<String>(StorageKeys.faceSyncBox);

  Future<void> savePendingFaceSync(PendingFaceSync item) =>
      _faceSyncBox.put(item.localId, jsonEncode(item.toJson()));

  List<PendingFaceSync> getAllPendingFaceSyncs() => _faceSyncBox.values
      .map((raw) =>
          PendingFaceSync.fromJson(jsonDecode(raw) as Map<String, dynamic>))
      .toList();

  List<PendingFaceSync> getPendingFaceSyncs() =>
      getAllPendingFaceSyncs().where((f) => f.isPending).toList();

  Future<void> updateFaceSyncStatus(String localId, String status) async {
    final raw = _faceSyncBox.get(localId);
    if (raw == null) return;
    final item =
        PendingFaceSync.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    item.syncStatus = status;
    item.syncAttempts += 1;
    await _faceSyncBox.put(localId, jsonEncode(item.toJson()));
  }

  Future<void> removeFaceSync(String localId) =>
      _faceSyncBox.delete(localId);

  // ── Quick helpers ─────────────────────────────────────────────────────────

  int get pendingSyncCount => getPendingLogs().length;
  int get pendingFaceSyncCount => getPendingFaceSyncs().length;

  Future<void> nukeAll() async {
    await _empBox.clear();
    await _attBox.clear();
    await _empSyncBox.clear();
    await _faceSyncBox.clear();
    await _settings.clear();
  }
}
