import 'package:get/get.dart';
import '../../core/utils/app_logger.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/employee_repository.dart';
import '../../routes/app_routes.dart';

class AuthController extends GetxController {
  final _auth    = AuthRepository();
  final _empRepo = EmployeeRepository();

  final isLoading   = false.obs;
  final errorMsg    = ''.obs;
  final phone       = ''.obs;
  final companyName = ''.obs;
  final adminName   = ''.obs;

  // ── Send OTP ──────────────────────────────────────────────────────────────

  Future<void> sendOtp(String phoneNum) async {
    if (isLoading.value) return;
    final trimmed = phoneNum.trim();
    if (trimmed.length < 10) {
      errorMsg.value = 'Enter a valid phone number';
      return;
    }
    isLoading.value = true;
    errorMsg.value  = '';
    try {
      final data = await _auth.sendOtp(trimmed);
      phone.value       = trimmed;
      companyName.value = data['company_name']?.toString() ?? '';
      adminName.value   = data['admin_name']?.toString() ?? '';
      Get.toNamed(AppRoutes.otp);
    } catch (e) {
      errorMsg.value = _parseError(e);
      appLogger.e('sendOtp error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────

  Future<void> verifyOtp(String otp) async {
    if (isLoading.value) return;
    if (otp.trim().length != 6) {
      errorMsg.value = 'Enter the 6-digit OTP';
      return;
    }
    isLoading.value = true;
    errorMsg.value  = '';
    try {
      await _auth.verifyOtp(phone.value, otp.trim(),
          adminName: adminName.value);
      // Sync employees immediately after login
      try { await _empRepo.syncEmployees(); } catch (_) {}
      Get.offAllNamed(AppRoutes.faceScan);
    } catch (e) {
      errorMsg.value = _parseError(e);
      appLogger.e('verifyOtp error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String _parseError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('401')) return 'Invalid OTP. Please try again.';
    if (msg.contains('404')) return 'Phone number not registered.';
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please retry.';
  }
}
