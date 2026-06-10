import '../../core/utils/app_logger.dart';
import '../../data/local/local_db.dart';
import '../../data/remote/api_service.dart';
import '../../data/repositories/attendance_repository.dart';

/// Called both from the app (foreground) and from Workmanager (background).
/// Must be static so Workmanager can call it without a GetX context.
class SyncService {
  // ── Attendance sync ───────────────────────────────────────────────────────

  /// Sync up to [AppConstants.syncBatchSize] pending logs.
  /// Safe to call multiple times — skips already-synced logs.
  static Future<int> runBackgroundSync() async {
    await AttendanceRepository().completeMissedPunchOuts();
    final synced = await _syncAttendanceLogs();
    await _syncPendingEmployees();
    await _syncPendingFaces();
    return synced;
  }

  static Future<int> _syncAttendanceLogs() async {
    final db = LocalDb.instance;
    final api = ApiService.instance;
    final pending = db.getPendingLogs();

    if (pending.isEmpty) return 0;

    int synced = 0;
    for (final log in pending) {
      if (log.syncAttempts >= 5) {
        await db.updateLogStatus(log.localId, 'failed');
        continue;
      }
      try {
        if (log.isPunchIn) {
          await api.punchIn(log.employeeId, log.punchTime,
              clientLogId: log.localId);
        } else {
          await api.punchOut(log.employeeId, log.punchTime,
              clientLogId: log.localId);
        }
        await db.updateLogStatus(log.localId, 'synced');
        synced++;
        appLogger.i('Synced: ${log.type} ${log.employeeName}');
      } catch (e) {
        await db.updateLogStatus(log.localId, 'pending');
        appLogger.w('Sync failed for ${log.localId}: $e');
      }
    }
    appLogger.i('Attendance sync: $synced/${pending.length} uploaded');
    return synced;
  }

  // ── Employee sync ─────────────────────────────────────────────────────────

  /// Push locally-created employees to the server.
  /// On success, writes the real server record into the employee box.
  static Future<void> _syncPendingEmployees() async {
    final db = LocalDb.instance;
    final api = ApiService.instance;
    final pending = db.getPendingQueuedEmployees();

    if (pending.isEmpty) {
      // Opportunistically clean up old synced entries
      await _cleanSyncedEmployees(db);
      return;
    }

    for (final emp in pending) {
      if (emp.syncAttempts >= 5) {
        await db.updateQueuedEmployee(emp.localId, 'failed');
        appLogger.w('Employee sync giving up after 5 attempts: ${emp.name}');
        continue;
      }

      try {
        final created = await api.createEmployee(
          name: emp.name,
          employeeId: emp.employeeId,
          designation: emp.designation,
          department: emp.department,
          faceEncoding: emp.faceEncoding,
        );

        await db.deleteEmployee(emp.localEmployeeId);
        await db.updateEmployee(created);
        await db.updateQueuedEmployee(emp.localId, 'synced',
            serverId: created.id);

        appLogger.i('Employee synced: ${emp.name} → server id ${created.id}');
      } catch (e) {
        await db.updateQueuedEmployee(emp.localId, 'pending');
        appLogger.w('Employee sync failed for ${emp.name}: $e');
      }
    }

    await _cleanSyncedEmployees(db);
  }

  /// Remove queue entries that have already been pushed to the server.
  /// Failed entries are kept because they still provide local face matching.
  static Future<void> _cleanSyncedEmployees(LocalDb db) async {
    final all = db.getAllQueuedEmployees();
    for (final e in all) {
      if (e.isSynced) {
        await db.removeQueuedEmployee(e.localId);
      }
    }
  }

  // ── Face encoding sync ────────────────────────────────────────────────────

  /// Upload face encodings that were saved locally while offline.
  static Future<void> _syncPendingFaces() async {
    final db      = LocalDb.instance;
    final api     = ApiService.instance;
    final pending = db.getPendingFaceSyncs();

    if (pending.isEmpty) return;

    for (final face in pending) {
      if (face.syncAttempts >= 5) {
        await db.updateFaceSyncStatus(face.localId, 'failed');
        appLogger.w('Face sync giving up after 5 attempts: emp ${face.employeeId}');
        continue;
      }
      try {
        await api.saveFace(face.employeeId, face.faceEncoding);
        await db.removeFaceSync(face.localId);
        appLogger.i('Face synced to server: emp ${face.employeeId}');
      } catch (e) {
        await db.updateFaceSyncStatus(face.localId, 'pending');
        appLogger.w('Face sync failed for emp ${face.employeeId}: $e');
      }
    }
  }
}
