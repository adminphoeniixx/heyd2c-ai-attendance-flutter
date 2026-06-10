import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/time_utils.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/pending_employee.dart';
import '../../routes/app_routes.dart';
import 'employee_controller.dart';

class EmployeeListScreen extends StatelessWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(EmployeeController());

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Employees', style: AppTs.h3()),
                Text(
                  '${c.registeredCount} registered  ·  ${c.employees.length} total'
                  '${c.pendingCount > 0 ? '  ·  ${c.pendingCount} syncing' : ''}',
                  style: AppTs.tag(),
                ),
              ],
            )),
        actions: [
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
                  icon: const Icon(Icons.sync_rounded,
                      color: AppColors.textMuted),
                  onPressed: c.refresh,
                )),
        ],
      ),
      body: Column(
        children: [
          // ── Search + filter bar ──────────────────────────────────────────
          Container(
            color: AppColors.bg2,
            padding: const EdgeInsets.fromLTRB(
                AppSpace.screen, 0, AppSpace.screen, AppSpace.lg),
            child: Column(
              children: [
                // Search field
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bg3,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: AppSpace.md),
                        child: Icon(Icons.search_rounded,
                            color: AppColors.textMuted, size: AppIconSize.sm),
                      ),
                      Expanded(
                        child: TextField(
                          onChanged: c.search,
                          style: AppTs.body(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search by name, ID or department…',
                            hintStyle: AppTs.body(color: AppColors.textMuted),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.md, vertical: AppSpace.md),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                // Status chips
                Obx(() => Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.sm,
                      children: [
                        _StatusChip(
                            label: '${c.registeredCount} with face',
                            color: AppColors.emerald,
                            icon: Icons.face_rounded),
                        _StatusChip(
                            label:
                                '${c.employees.length - c.registeredCount} without',
                            color: AppColors.amber,
                            icon: Icons.no_photography_rounded),
                        if (c.pendingCount > 0)
                          _StatusChip(
                              label: '${c.pendingCount} pending sync',
                              color: AppColors.cyan,
                              icon: Icons.cloud_upload_rounded),
                      ],
                    )),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              final synced = c.filtered;
              final pending = c.filteredPending;

              if (synced.isEmpty && pending.isEmpty && c.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (synced.isEmpty && pending.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group_off_rounded,
                          color: AppColors.textMuted, size: AppIconSize.empty),
                      const SizedBox(height: AppSpace.md),
                      Text('No employees found', style: AppTs.bodySmall()),
                    ],
                  ),
                );
              }

              return ListView(
                padding: AppSpace.listPadding,
                children: [
                  // ── Pending (locally created, awaiting server sync) ───────
                  if (pending.isNotEmpty) ...[
                    _SectionLabel(
                      label: 'PENDING SYNC',
                      color: AppColors.cyan,
                      count: pending.length,
                    ),
                    ...pending.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.sm),
                          child: _PendingTile(
                            emp: p,
                            attendance: c.attendanceStatusFor(
                                p.serverId ?? p.localEmployeeId),
                          ),
                        )),
                    const SizedBox(height: AppSpace.sm),
                  ],

                  // ── Synced from server ────────────────────────────────────
                  if (synced.isNotEmpty) ...[
                    if (pending.isNotEmpty)
                      _SectionLabel(
                        label: 'SYNCED EMPLOYEES',
                        color: AppColors.emerald,
                        count: synced.length,
                      ),
                    ...synced.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.sm),
                          child: _EmployeeTile(
                            emp: e,
                            attendance: c.attendanceStatusFor(e.id),
                          ),
                        )),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  const _SectionLabel(
      {required this.label, required this.color, required this.count});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.sm),
        child: Row(
          children: [
            Container(
                width: 4,
                height: 4,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: AppSpace.sm),
            Text('$label ($count)',
                style: AppTs.tag(color: color)
                    .copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusChip(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md, vertical: AppSpace.xs),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIconSize.xs, color: color),
            const SizedBox(width: AppSpace.xs),
            Text(label,
                style: AppTs.tag(color: color)
                    .copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

// ── Pending employee tile (locally saved, syncing) ────────────────────────────

class _PendingTile extends StatelessWidget {
  final PendingEmployee emp;
  final EmployeeAttendanceStatus attendance;
  const _PendingTile({
    required this.emp,
    required this.attendance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpace.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
            ),
            child: Center(
              child: Text(
                emp.name
                    .trim()
                    .split(' ')
                    .take(2)
                    .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                    .join(),
                style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.cyan),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.lg),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emp.name,
                  style: AppTs.label(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpace.xxs),
                if (emp.designation.isNotEmpty)
                  Text(
                    emp.designation,
                    style: AppTs.bodySmall(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (emp.employeeId.isNotEmpty)
                  Text(
                    '#${emp.employeeId}',
                    style: AppTs.mono(size: 10, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: AppSpace.sm),
                _AttendanceDetails(status: attendance),
              ],
            ),
          ),

          // Sync status badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm, vertical: AppSpace.xs),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border:
                      Border.all(color: AppColors.cyan.withValues(alpha: 0.30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 9,
                      height: 9,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.cyan.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text('Syncing',
                        style: AppTs.tag(color: AppColors.cyan).copyWith(
                            fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                emp.faceEncoding != null
                    ? (emp.faceImagePath != null
                        ? 'Face + image saved'
                        : 'Face captured')
                    : 'No face yet',
                style: AppTs.caption(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Synced employee tile ──────────────────────────────────────────────────────

class _EmployeeTile extends StatelessWidget {
  final EmployeeModel emp;
  final EmployeeAttendanceStatus attendance;
  const _EmployeeTile({
    required this.emp,
    required this.attendance,
  });

  @override
  Widget build(BuildContext context) {
    final regColor = emp.hasFace ? AppColors.emerald : AppColors.amber;

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.faceReg, arguments: {'employee': emp}),
      child: Container(
        padding: AppSpace.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: emp.hasFace
                ? AppColors.emerald.withValues(alpha: 0.22)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.fuchsia]),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  emp.name
                      .trim()
                      .split(' ')
                      .take(2)
                      .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                      .join(),
                  style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.lg),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp.name,
                    style: AppTs.label(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  if (emp.designation.isNotEmpty)
                    Text(
                      emp.designation,
                      style: AppTs.bodySmall(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (emp.employeeId.isNotEmpty)
                    Text(
                      '#${emp.employeeId}',
                      style: AppTs.mono(size: 10, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: AppSpace.sm),
                  _AttendanceDetails(status: attendance),
                ],
              ),
            ),

            // Badge + caret
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm, vertical: AppSpace.xs),
                  decoration: BoxDecoration(
                    color: regColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: regColor.withValues(alpha: 0.30)),
                  ),
                  child: Text(
                    emp.hasFace ? 'Registered' : 'No Face',
                    style: AppTs.tag(color: regColor)
                        .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  emp.hasFace ? 'Tap to update' : 'Tap to register',
                  style: AppTs.caption(),
                ),
              ],
            ),
            const SizedBox(width: AppSpace.xs),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted.withValues(alpha: 0.5),
                size: AppIconSize.md),
          ],
        ),
      ),
    );
  }
}

class _AttendanceDetails extends StatelessWidget {
  final EmployeeAttendanceStatus status;
  const _AttendanceDetails({required this.status});

  @override
  Widget build(BuildContext context) {
    final statusColor = status.hasPunch
        ? (status.isIn ? AppColors.emerald : AppColors.cyan)
        : AppColors.amber;
    final statusIcon = status.hasPunch
        ? (status.isIn ? Icons.login_rounded : Icons.logout_rounded)
        : Icons.pending_actions_rounded;
    final flagText = status.autoClosed ? ' • Auto' : '';
    final inTime = status.firstPunchIn.isEmpty
        ? '--'
        : TimeUtils.fmtTime(status.firstPunchIn);
    final outTime = status.lastPunchOut.isEmpty
        ? '--'
        : TimeUtils.fmtTime(status.lastPunchOut);

    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm, vertical: AppSpace.xs),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: AppIconSize.xs),
                    const SizedBox(width: AppSpace.xs),
                    Flexible(
                      child: Text(
                        '${status.label}$flagText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTs.tag(color: statusColor).copyWith(
                            fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.xs,
                children: [
                  _PunchTimeText(
                      icon: Icons.login_rounded,
                      label: 'In',
                      value: inTime,
                      color: AppColors.emerald),
                  _PunchTimeText(
                      icon: Icons.logout_rounded,
                      label: 'Out',
                      value: outTime,
                      color: AppColors.cyan),
                  if (status.punchCount > 1)
                    Text(
                      '${status.punchCount} punches',
                      style: AppTs.caption(color: AppColors.textMuted)
                          .copyWith(fontSize: 10),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PunchTimeText extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _PunchTimeText({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: AppIconSize.xs),
          const SizedBox(width: AppSpace.xxs),
          Text(
            '$label: $value',
            style: AppTs.caption(color: AppColors.textSecondary)
                .copyWith(fontSize: 10),
          ),
        ],
      );
}

