import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/time_utils.dart';
import '../../data/models/attendance_log.dart';
import 'sync_controller.dart';

class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(SyncController());
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sync Queue', style: AppTs.h3()),
            Text('OFFLINE  →  SERVER', style: AppTs.tag()),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
            onPressed: c.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Sync button + stat row ──────────────────────────────────────
          Container(
            color: AppColors.bg2,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              children: [
                Obx(() => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: c.isSyncing.value ? null : c.syncNow,
                        icon: c.isSyncing.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.cloud_sync_rounded, size: 18),
                        label: Text(
                          c.isSyncing.value ? 'Syncing…' : 'Sync Now',
                          style: AppTs.label(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    )),
                Obx(() => c.statusMsg.value.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(c.statusMsg.value,
                            textAlign: TextAlign.center,
                            style: AppTs.bodySmall()),
                      )
                    : const SizedBox.shrink()),
                const SizedBox(height: 12),
                // Stat chips row
                Obx(() => Row( 
                      children: [
                        _StatChip(
                            label: '${c.pendingLogs.length} pending',
                            color: AppColors.amber),
                        const SizedBox(width: 8),
                        _StatChip(
                            label: '${c.syncedLogs.length} synced',
                            color: AppColors.emerald),
                        const SizedBox(width: 8),
                        _StatChip(
                            label: '${c.allLogs.length} total',
                            color: AppColors.primaryMid),
                      ],
                    )),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // ── Tabs ─────────────────────────────────────────────────────────
          Expanded(
            child: Obx(() => DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      // Tab bar
                      Container(
                        color: AppColors.bg2,
                        child: TabBar(
                          tabs: [
                            Tab(text: 'Pending (${c.pendingLogs.length})'),
                            Tab(text: 'Synced (${c.syncedLogs.length})'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            c.pendingLogs.isEmpty
                                ? const _Empty(
                                    icon: Icons.cloud_done_rounded,
                                    msg: 'All records synced ✓',
                                    color: AppColors.emerald)
                                : _LogList(logs: c.pendingLogs),
                            c.syncedLogs.isEmpty
                                ? const _Empty(
                                    icon: Icons.inbox_rounded,
                                    msg: 'No synced records yet',
                                    color: AppColors.textMuted)
                                : _LogList(logs: c.syncedLogs),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ),
        ],
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Text(label,
            style: AppTs.tag(color: color)
                .copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

// ── Log list ──────────────────────────────────────────────────────────────────

class _LogList extends StatelessWidget {
  final List<AttendanceLog> logs;
  const _LogList({required this.logs});

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _LogTile(log: logs[i]),
      );
}

class _LogTile extends StatelessWidget {
  final AttendanceLog log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final isIn = log.isPunchIn;
    final accent = isIn ? AppColors.cyan : AppColors.fuchsia;
    final synced = log.isSynced;
    final stColor = synced ? AppColors.emerald : AppColors.amber;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stColor.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isIn ? Icons.login_rounded : Icons.logout_rounded,
                color: accent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.employeeName, style: AppTs.label()),
                Text(
                  '${isIn ? "IN" : "OUT"}  ·  ${TimeUtils.fmtTime(log.punchTime)}',
                  style: AppTs.bodySmall(),
                ),
                if (log.syncAttempts > 0 && !synced)
                  Text('${log.syncAttempts} attempt(s)',
                      style: AppTs.caption(color: AppColors.rose)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: stColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: stColor.withValues(alpha: 0.28)),
            ),
            child: Text(
              synced ? 'Synced' : 'Pending',
              style: AppTs.tag(color: stColor)
                  .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _Empty extends StatelessWidget {
  final IconData icon;
  final String msg;
  final Color color;
  const _Empty(
      {required this.icon,
      required this.msg,
      this.color = AppColors.textMuted});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 52),
            const SizedBox(height: 12),
            Text(msg, style: AppTs.bodySmall()),
          ],
        ),
      );
}
