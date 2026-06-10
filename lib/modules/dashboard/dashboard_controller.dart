import 'package:get/get.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/remote/api_service.dart';
class DashboardController extends GetxController {
  final _api = ApiService.instance;

  final isLoading = false.obs;
  final errorMsg  = ''.obs;
  final dashboard = Rxn<DashboardModel>();

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    errorMsg.value  = '';
    try {
      final data = await _api.getToday();
      dashboard.value = data;
    } catch (e) {
      errorMsg.value = 'Failed to load dashboard';
      appLogger.e('Dashboard load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() => loadDashboard();

  String presentPercent() {
    final t = dashboard.value?.summary.total ?? 0;
    final p = dashboard.value?.summary.present ?? 0;
    if (t == 0) return '0%';
    return '${((p / t) * 100).round()}%';
  }
}
