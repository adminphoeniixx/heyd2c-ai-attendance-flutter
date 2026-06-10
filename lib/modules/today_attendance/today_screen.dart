import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/time_utils.dart';
import '../../data/models/attendance_log.dart';
import '../../data/models/dashboard_model.dart';
import 'today_controller.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(TodayController());

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
            Text("Today's Attendance", style: AppTs.h3()),
            Text(TimeUtils.displayDate(), style: AppTs.tag()),
          ],
        ),
        actions: [
          Obx(() => TextButton(
                onPressed: c.toggleView,
                child: Text(c.viewLabel,
                    style: AppTs.bodySmall(color: AppColors.primaryLight)
                        .copyWith(fontWeight: FontWeight.w600)),
              )),
          Obx(() => c.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primaryLight),
                  ))
              : IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppColors.textMuted),
                  onPressed: c.refresh,
                )),
        ],
      ),
      body: Obx(() {
        if (c.isLoading.value && c.employees.isEmpty && c.localLogs.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        return RefreshIndicator(
          onRefresh: c.refresh,
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: c.showLocalLogs.value
              ? _LocalList(logs: c.localLogs)
              : _ServerList(employees: c.employees, errorMsg: c.errorMsg.value),
        );
      }),
    );
  }
}

// ── Server list ───────────────────────────────────────────────────────────────

class _ServerList extends StatelessWidget {
  final List<TodayEmployeeStatus> employees;
  final String errorMsg;
  const _ServerList({required this.employees, required this.errorMsg});

  @override
  Widget build(BuildContext context) {
    if (employees.isEmpty) {
      return _Empty(
        icon: Icons.today_rounded,
        msg: errorMsg.isNotEmpty ? errorMsg : 'No attendance data for today',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: employees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _ServerTile(emp: employees[i]),
    );
  }
}

class _ServerTile extends StatelessWidget {
  final TodayEmployeeStatus emp;
  const _ServerTile({required this.emp});

  @override
  Widget build(BuildContext context) {
    final isIn = emp.currentState == 'in';
    final hasPunches = emp.punches.isNotEmpty;
    final stColor = hasPunches
        ? (isIn ? AppColors.emerald : AppColors.cyan)
        : AppColors.amber;
    final checkIn = emp.checkIn?.isNotEmpty == true
        ? TimeUtils.fmtTime(emp.checkIn!)
        : '--';
    final checkOut = emp.checkOut?.isNotEmpty == true
        ? TimeUtils.fmtTime(emp.checkOut!)
        : '--';
    final stateLabel = !hasPunches
        ? 'NOT MARKED'
        : isIn
            ? 'IN'
            : 'OUT';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              _Avatar(name: emp.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emp.name,
                        style: AppTs.label(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      'In: $checkIn  ·  Out: $checkOut  ·  ${emp.punchCount} punch${emp.punchCount == 1 ? '' : 'es'}',
                      style: AppTs.caption(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // State badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: stColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: stColor.withValues(alpha: 0.30)),
                ),
                child: Text(
                  stateLabel,
                  style: AppTs.tag(color: stColor)
                      .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          // Punch chips
          if (emp.punches.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: emp.punches.map((p) => _PunchChip(punch: p)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});
  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          gradient:
              LinearGradient(colors: [AppColors.primary, AppColors.fuchsia]),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            name
                .trim()
                .split(' ')
                .take(2)
                .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                .join(),
            style: AppTs.tag(color: Colors.white)
                .copyWith(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      );
}

class _PunchChip extends StatelessWidget {
  final Map<String, dynamic> punch;
  const _PunchChip({required this.punch});

  @override
  Widget build(BuildContext context) {
    final type = punch['type']?.toString() ?? '';
    final time = punch['time']?.toString() ?? '';
    final autoClosed = punch['auto_closed'] == 'true';
    final isIn = type == 'punch_in';
    final col = isIn ? AppColors.cyan : AppColors.fuchsia;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: col.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isIn ? Icons.login_rounded : Icons.logout_rounded,
              color: col, size: 11),
          const SizedBox(width: 4),
          Text(TimeUtils.fmtTime(time),
              style: AppTs.tag(color: col)
                  .copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
          if (autoClosed) ...[
            const SizedBox(width: 4),
            Text('AUTO',
                style: AppTs.tag(color: AppColors.rose)
                    .copyWith(fontSize: 9, fontWeight: FontWeight.w800)),
          ],
        ],
      ),
    );
  }
}

// ── Local logs list ───────────────────────────────────────────────────────────

class _LocalList extends StatelessWidget {
  final List<AttendanceLog> logs;
  const _LocalList({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const _Empty(
        icon: Icons.receipt_long_rounded,
        msg: 'No local records for today',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _LogTile(log: logs[i]),
    );
  }
}

class _LogTile extends StatelessWidget {
  final AttendanceLog log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final isIn = log.isPunchIn;
    final accent = isIn ? AppColors.cyan : AppColors.fuchsia;
    final synced = log.isSynced;
    final (sbg, sfg) = synced
        ? (AppColors.emerald.withValues(alpha: 0.12), AppColors.emerald)
        : (AppColors.amber.withValues(alpha: 0.12), AppColors.amber);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
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
                  '${isIn ? "Punch In" : "Punch Out"}  ·  ${TimeUtils.fmtTime(log.punchTime)}',
                  style: AppTs.bodySmall(),
                ),
                if (log.autoClosed && log.flagTag != null) ...[
                  const SizedBox(height: 4),
                  _FlagTag(
                    label: '${log.flagTag} · ${log.flagDate ?? ''}',
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: sbg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(synced ? 'Synced' : 'Pending',
                style: AppTs.tag(color: sfg)
                    .copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _FlagTag extends StatelessWidget {
  final String label;
  const _FlagTag({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.rose.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.rose.withValues(alpha: 0.28)),
        ),
        child: Text(
          label.trim(),
          style: AppTs.tag(color: AppColors.rose)
              .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  final IconData icon;
  final String msg;
  const _Empty({required this.icon, required this.msg});

  @override
  Widget build(BuildContext context) => ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.textMuted, size: 52),
                const SizedBox(height: 12),
                Text(msg, style: AppTs.bodySmall()),
              ],
            ),
          ),
        ],
      );
}
