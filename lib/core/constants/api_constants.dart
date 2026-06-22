abstract class ApiConstants {
  static const baseUrl = 'https://heyd2c.ai/api/v1/kiosk';

  // Auth
  static const sendOtp = '/send-otp';
  static const verifyOtp = '/verify-otp';

  // Account — lives one level up from the kiosk-scoped base URL, so this is
  // an absolute URL (Dio uses it as-is and skips baseUrl when path has a scheme).
  static const deleteAccount = 'https://heyd2c.ai/api/v1/account';

  // Employees
  static const employees = '/employees';
  static const createEmployee = '/employees';
  static String deleteEmployee(int id) => '/employees/$id';
  static String saveFace(int id) => '/employees/$id/face';
  static String deleteFace(int id) => '/employees/$id/face';

  // Attendance
  static const punchIn = '/punch-in';
  static const punchOut = '/punch-out';
  static const today = '/today';

  // Timeouts (ms)
  static const connectTimeout = 15000;
  static const receiveTimeout = 15000;
}
