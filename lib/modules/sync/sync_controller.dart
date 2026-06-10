import 'package:get/get.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/attendance_log.dart';
import '../../data/repositories/attendance_repository.dart';

class SyncController extends GetxController {
  final _repo = AttendanceRepository();

  final isSyncing = false.obs;
  final statusMsg = ''.obs;
  final allLogs = <AttendanceLog>[].obs;

  List<AttendanceLog> get pendingLogs =>
      allLogs.where((l) => l.isPending).toList();
  List<AttendanceLog> get syncedLogs =>
      allLogs.where((l) => l.isSynced).toList();

  @override
  void onInit() {
    super.onInit();
    _loadLogs();
  }

  void _loadLogs() {
    final logs = _repo.getAll();
    logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    allLogs.value = logs;
  }

  Future<void> syncNow() async {
    if (isSyncing.value) return;
    isSyncing.value = true;
    statusMsg.value = 'Syncing…';
    try {
      await SyncService.runBackgroundSync();
      _loadLogs();
      statusMsg.value = 'Sync complete';
    } catch (e) {
      statusMsg.value = 'Sync failed: $e';
      appLogger.e('SyncController sync error: $e');
    } finally {
      isSyncing.value = false;
      Future.delayed(const Duration(seconds: 3), () => statusMsg.value = '');
    }
  }

  @override
  Future<void> refresh() async {
    _loadLogs();
  }
}
