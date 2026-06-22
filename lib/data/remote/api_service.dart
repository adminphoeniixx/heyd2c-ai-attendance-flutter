import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/dashboard_model.dart';
import '../models/employee_model.dart';
import '../models/punch_response.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();
  final _client = DioClient.instance;

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiConstants.sendOtp,
      data: {'phone': phone},
    );
    return res.data!;
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiConstants.verifyOtp,
      data: {'phone': phone, 'otp': otp},
    );
    return res.data!;
  }

  // ── Account ───────────────────────────────────────────────────────────────

  Future<void> deleteAccount() async {
    await _client.delete<dynamic>(ApiConstants.deleteAccount);
  }

  // ── Employees ─────────────────────────────────────────────────────────────

  Future<EmployeeModel> createEmployee({
    required String name,
    required String employeeId,
    required String designation,
    required String department,
    String? faceEncoding,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiConstants.createEmployee,
      data: {
        'name': name,
        'employee_id': employeeId,
        'designation': designation,
        'department': department,
        if (faceEncoding != null && faceEncoding.isNotEmpty)
          'face_encoding': faceEncoding,
      },
    );
    return EmployeeModel.fromJson(
        res.data!['employee'] as Map<String, dynamic>? ?? res.data!);
  }

  Future<List<EmployeeModel>> getEmployees() async {
    final res = await _client.get<Map<String, dynamic>>(ApiConstants.employees);
    final list =
        (res.data!['employees'] as List? ?? []).cast<Map<String, dynamic>>();
    return list.map(EmployeeModel.fromJson).toList();
  }

  Future<void> deleteEmployee(int employeeId) async {
    await _client.delete<dynamic>(ApiConstants.deleteEmployee(employeeId));
  }

  Future<void> saveFace(int employeeId, String faceEncoding) async {
    await _client.post<dynamic>(
      ApiConstants.saveFace(employeeId),
      data: {'face_encoding': faceEncoding},
    );
  }

  Future<void> deleteFace(int employeeId) async {
    await _client.delete<dynamic>(ApiConstants.deleteFace(employeeId));
  }

  // ── Attendance ────────────────────────────────────────────────────────────

  Future<PunchResponse> punchIn(int employeeId, String time,
      {String? clientLogId}) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiConstants.punchIn,
      data: {
        'employee_id': employeeId,
        'time': time,
        if (clientLogId != null) 'client_log_id': clientLogId,
      },
    );
    return PunchResponse.fromJson(res.data!);
  }

  Future<PunchResponse> punchOut(int employeeId, String time,
      {String? clientLogId}) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiConstants.punchOut,
      data: {
        'employee_id': employeeId,
        'time': time,
        if (clientLogId != null) 'client_log_id': clientLogId,
      },
    );
    return PunchResponse.fromJson(res.data!);
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────

  Future<DashboardModel> getToday() async {
    final res = await _client.get<Map<String, dynamic>>(ApiConstants.today);
    return DashboardModel.fromJson(res.data!);
  }
}
