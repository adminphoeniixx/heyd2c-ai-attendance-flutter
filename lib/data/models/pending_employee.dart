/// Employee creation record stored in Hive before syncing to the server.
/// Mirrors AttendanceLog's offline-first pattern.
class PendingEmployee {
  final String localId; // UUID — Hive key
  final String name;
  final String employeeId;
  final String designation;
  final String department;
  final String? faceEncoding; // comma-separated floats, may be null
  final String? faceImagePath;
  final int localEmployeeId;
  String syncStatus; // 'pending' | 'synced' | 'failed'
  int syncAttempts;
  int? serverId; // filled after successful server sync
  final String createdAt; // ISO-8601

  PendingEmployee({
    required this.localId,
    required this.name,
    required this.employeeId,
    required this.designation,
    required this.department,
    this.faceEncoding,
    this.faceImagePath,
    int? localEmployeeId,
    this.syncStatus = 'pending',
    this.syncAttempts = 0,
    this.serverId,
    required this.createdAt,
  }) : localEmployeeId = localEmployeeId ?? _stableLocalEmployeeId(localId);

  factory PendingEmployee.fromJson(Map<String, dynamic> j) => PendingEmployee(
        localId: j['local_id'] as String,
        name: j['name'] as String,
        employeeId: j['employee_id'] as String,
        designation: j['designation'] as String,
        department: j['department'] as String,
        faceEncoding: j['face_encoding'] as String?,
        faceImagePath: j['face_image_path'] as String?,
        localEmployeeId: (j['local_employee_id'] as num?)?.toInt(),
        syncStatus: j['sync_status'] as String? ?? 'pending',
        syncAttempts: (j['sync_attempts'] as num?)?.toInt() ?? 0,
        serverId: (j['server_id'] as num?)?.toInt(),
        createdAt: j['created_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'local_id': localId,
        'name': name,
        'employee_id': employeeId,
        'designation': designation,
        'department': department,
        'face_encoding': faceEncoding,
        'face_image_path': faceImagePath,
        'local_employee_id': localEmployeeId,
        'sync_status': syncStatus,
        'sync_attempts': syncAttempts,
        'server_id': serverId,
        'created_at': createdAt,
      };

  bool get isPending => syncStatus == 'pending';
  bool get isSynced => syncStatus == 'synced';
  bool get isFailed => syncStatus == 'failed';

  static int _stableLocalEmployeeId(String localId) {
    var hash = 0;
    for (final code in localId.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return -(hash == 0 ? 1 : hash);
  }
}
