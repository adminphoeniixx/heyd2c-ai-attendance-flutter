abstract class StorageKeys {
  // Hive box names
  static const employeeBox    = 'employees';
  static const attendanceBox  = 'attendance_logs';
  static const syncQueueBox      = 'sync_queue';
  static const employeeSyncBox   = 'employee_sync_queue';
  static const faceSyncBox       = 'face_sync_queue';
  static const settingsBox    = 'settings';

  // Settings keys
  static const kioskToken     = 'kiosk_token';
  static const companyName    = 'company_name';
  static const adminName      = 'admin_name';
  static const adminPhone     = 'admin_phone';
  static const employeeCache  = 'employee_list_json';
  static const lastSyncAt     = 'last_sync_at';
}
