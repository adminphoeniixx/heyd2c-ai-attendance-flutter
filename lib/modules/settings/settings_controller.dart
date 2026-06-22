import 'package:get/get.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/utils/app_logger.dart';
import '../../data/local/local_db.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/employee_repository.dart';
import '../../routes/app_routes.dart';

class SettingsController extends GetxController {
  final _db       = LocalDb.instance;
  final _authRepo = AuthRepository();
  final _empRepo  = EmployeeRepository();

  final companyName = ''.obs;
  final adminName   = ''.obs;
  final adminPhone  = ''.obs;
  final lastSyncAt  = ''.obs;
  final isLoggingOut        = false.obs;
  final isSyncingEmployees  = false.obs;
  final isDeletingAccount   = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  void _loadSettings() {
    companyName.value = _db.getSetting(StorageKeys.companyName)  ?? '';
    adminName.value   = _db.getSetting(StorageKeys.adminName)    ?? '';
    adminPhone.value  = _db.getSetting(StorageKeys.adminPhone)   ?? '';
    lastSyncAt.value  = _db.getSetting(StorageKeys.lastSyncAt)   ?? 'Never';
  }

  Future<void> logout() async {
    isLoggingOut.value = true;
    try {
      await _authRepo.logout();
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      appLogger.e('Logout error: $e');
    } finally {
      isLoggingOut.value = false;
    }
  }

  /// Wipes the local employee cache and re-fetches the full list from the API.
  /// Face encodings saved only locally are preserved via LocalDb.saveEmployees merge logic.
  Future<void> syncEmployeesFromServer() async {
    if (isSyncingEmployees.value) return;
    isSyncingEmployees.value = true;
    try {
      await _db.clearEmployees();
      final list = await _empRepo.syncEmployees();
      appLogger.i('Employee re-sync: ${list.length} employees fetched');
      Get.snackbar(
        'Sync Complete',
        '${list.length} employees loaded from server',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      appLogger.e('Employee re-sync error: $e');
      Get.snackbar(
        'Sync Failed',
        'Could not reach server — check internet connection',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isSyncingEmployees.value = false;
    }
  }

  Future<void> clearSyncedLogs() async {
    try {
      await _db.clearSyncedLogs();
      appLogger.i('Synced attendance logs cleared');
    } catch (e) {
      appLogger.e('Clear data error: $e');
    }
  }

  Future<void> nukeAll() async {
    try {
      await _db.nukeAll();
      appLogger.i('All local data nuked');
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      appLogger.e('Nuke error: $e');
    }
  }

  /// Permanently deletes the account on the server. Irreversible — wipes the
  /// company's data and every employee/attendance record along with it.
  Future<void> deleteAccount() async {
    if (isDeletingAccount.value) return;
    isDeletingAccount.value = true;
    try {
      await _authRepo.deleteAccount();
      appLogger.i('Account deleted permanently');
      Get.offAllNamed(AppRoutes.login);
      Get.snackbar(
        'Account Deleted',
        'Your account and all associated data have been permanently removed.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      appLogger.e('Delete account error: $e');
      Get.snackbar(
        'Delete Failed',
        _parseDeleteError(e),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isDeletingAccount.value = false;
    }
  }

  String _parseDeleteError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('401') || msg.contains('403')) {
      return 'Session expired. Please log in again.';
    }
    if (msg.contains('404')) return 'Account not found.';
    if (msg.contains('SocketException') ||
        msg.contains('connection') ||
        msg.contains('timeout')) {
      return 'No internet connection. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
