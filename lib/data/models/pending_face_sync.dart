/// Face encoding that failed to upload — queued for retry when online.
class PendingFaceSync {
  final String localId;       // UUID – Hive key
  final int    employeeId;
  final String faceEncoding;  // comma-separated floats
  int          syncAttempts;
  String       syncStatus;    // 'pending' | 'synced' | 'failed'

  PendingFaceSync({
    required this.localId,
    required this.employeeId,
    required this.faceEncoding,
    this.syncAttempts = 0,
    this.syncStatus   = 'pending',
  });

  factory PendingFaceSync.fromJson(Map<String, dynamic> j) => PendingFaceSync(
        localId:      j['local_id'] as String,
        employeeId:   (j['employee_id'] as num).toInt(),
        faceEncoding: j['face_encoding'] as String,
        syncAttempts: (j['sync_attempts'] as num?)?.toInt() ?? 0,
        syncStatus:   j['sync_status'] as String? ?? 'pending',
      );

  Map<String, dynamic> toJson() => {
        'local_id':      localId,
        'employee_id':   employeeId,
        'face_encoding': faceEncoding,
        'sync_attempts': syncAttempts,
        'sync_status':   syncStatus,
      };

  bool get isPending => syncStatus == 'pending';
}
