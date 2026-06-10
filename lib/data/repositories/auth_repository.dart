import '../../core/constants/storage_keys.dart';
import '../../core/utils/app_logger.dart';
import '../local/local_db.dart';
import '../remote/api_service.dart';

class AuthRepository {
  final _api = ApiService.instance;
  final _db  = LocalDb.instance;

  Future<Map<String, dynamic>> sendOtp(String phone) =>
      _api.sendOtp(phone);

  Future<void> verifyOtp(String phone, String otp,
      {String adminName = ''}) async {
    final data = await _api.verifyOtp(phone, otp);
    final token = data['token']?.toString() ?? '';
    if (token.isEmpty) throw Exception('No token received');

    await _db.saveSetting(StorageKeys.kioskToken, token);
    await _db.saveSetting(StorageKeys.companyName,
        data['company_name']?.toString() ?? '');
    await _db.saveSetting(StorageKeys.adminPhone, phone);

    // Persist admin name — prefer verifyOtp response, fall back to sendOtp value
    final name = data['admin_name']?.toString() ?? adminName;
    if (name.isNotEmpty) {
      await _db.saveSetting(StorageKeys.adminName, name);
    }
    appLogger.i('Auth: token saved');
  }

  bool get isLoggedIn {
    final token = _db.getSetting(StorageKeys.kioskToken);
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _db.deleteSetting(StorageKeys.kioskToken);
    appLogger.i('Auth: logged out');
  }

  String get companyName =>
      _db.getSetting(StorageKeys.companyName) ?? '';
}
