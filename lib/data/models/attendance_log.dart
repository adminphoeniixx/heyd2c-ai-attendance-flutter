/// Local attendance record stored in Hive before / after syncing to server
class AttendanceLog {
  final String localId; // UUID
  final int employeeId;
  final String employeeName;
  final String type; // 'punch_in' | 'punch_out'
  final String punchTime; // HH:mm:ss
  final String createdAt; // ISO-8601
  String syncStatus; // 'pending' | 'synced' | 'failed'
  int syncAttempts;
  String? serverMessage;
  final bool autoClosed;
  final String? flagTag;
  final String? flagDate;

  AttendanceLog({
    required this.localId,
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.punchTime,
    required this.createdAt,
    this.syncStatus = 'pending',
    this.syncAttempts = 0,
    this.serverMessage,
    this.autoClosed = false,
    this.flagTag,
    this.flagDate,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> j) => AttendanceLog(
        localId: j['local_id'] as String,
        employeeId: (j['employee_id'] as num).toInt(),
        employeeName: j['employee_name'] as String,
        type: j['type'] as String,
        punchTime: j['punch_time'] as String,
        createdAt: j['created_at'] as String,
        syncStatus: j['sync_status'] as String? ?? 'pending',
        syncAttempts: (j['sync_attempts'] as num?)?.toInt() ?? 0,
        serverMessage: j['server_message'] as String?,
        autoClosed: j['auto_closed'] as bool? ?? false,
        flagTag: j['flag_tag'] as String?,
        flagDate: j['flag_date'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'local_id': localId,
        'employee_id': employeeId,
        'employee_name': employeeName,
        'type': type,
        'punch_time': punchTime,
        'created_at': createdAt,
        'sync_status': syncStatus,
        'sync_attempts': syncAttempts,
        'server_message': serverMessage,
        'auto_closed': autoClosed,
        'flag_tag': flagTag,
        'flag_date': flagDate,
      };

  bool get isPending => syncStatus == 'pending';
  bool get isSynced => syncStatus == 'synced';
  bool get isPunchIn => type == 'punch_in';
  bool get isPunchOut => type == 'punch_out';
}
