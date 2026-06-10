import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/time_utils.dart';
import '../../data/models/dashboard_model.dart';
import '../../routes/app_routes.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(DashboardController());

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
            Text('Dashboard', style: AppTs.h3()),
            Text(TimeUtils.displayDate(), style: AppTs.tag()),
          ],
        ),
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
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppColors.textMuted),
                  onPressed: c.refresh,
                )),
        ],
      ),
      body: Obx(() {
        if (c.isLoading.value && c.dashboard.value == null) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        return RefreshIndicator(
          onRefresh: c.refresh,
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpace.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error strip
                if (c.errorMsg.value.isNotEmpty && c.dashboard.value == null)
                  _ErrorStrip(msg: c.errorMsg.value, onRetry: c.refresh),

                // ── Action Required ──────────────────────────────────────────
                const VeloSectionHeader('ACTION REQUIRED'),
                _ActionGrid(c: c),
                const SizedBox(height: AppSpace.section),

                // ── Live Tracker ─────────────────────────────────────────────
                const VeloSectionHeader('LIVE TRACKER',
                    dotColor: AppColors.emerald, trailing: 'RIGHT NOW'),
                _TrackerGrid(dash: c.dashboard.value),
                const SizedBox(height: AppSpace.section),

                // ── Quick Nav ────────────────────────────────────────────────
                const VeloSectionHeader('QUICK ACCESS'),
                _QuickNav(),
                const SizedBox(height: AppSpace.section),

                // ── Employee Status ──────────────────────────────────────────
                if (c.dashboard.value != null) ...[
                  VeloSectionHeader(
                    'EMPLOYEE STATUS',
                    trailing: '${c.dashboard.value!.employees.length} TOTAL',
                  ),
                  ...c.dashboard.value!.employees
                      .take(12)
                      .map((e) => _EmployeeTile(emp: e)),
                  if (c.dashboard.value!.employees.length > 12)
                    Center(
                      child: TextButton(
                        onPressed: () => Get.toNamed(AppRoutes.today),
                        child: Text(
                          'View all ${c.dashboard.value!.employees.length} employees →',
                          style: AppTs.bodySmall(color: AppColors.primaryLight),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Action Required grid ──────────────────────────────────────────────────────

class _ActionGrid extends StatelessWidget {
  final DashboardController c;
  const _ActionGrid({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dash = c.dashboard.value;
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _StatCard(
            icon: Icons.groups_rounded,
            tag: 'TOTAL EMPLOYEES',
            value: '${dash?.summary.total ?? 0}',
            sub: 'Registered in system',
            color: AppColors.primaryLight,
            onTap: () => Get.toNamed(AppRoutes.employees),
          ),
          _StatCard(
            icon: Icons.how_to_reg_rounded,
            tag: 'PRESENT TODAY',
            value: '${dash?.summary.present ?? 0}',
            sub: 'Marked attendance',
            color: AppColors.emerald,
            onTap: () => Get.toNamed(AppRoutes.today),
          ),
          _StatCard(
            icon: Icons.schedule_rounded,
            tag: 'LATE ARRIVALS',
            value: '${dash?.summary.late ?? 0}',
            sub: 'Came in late today',
            color: AppColors.rose,
            onTap: () => Get.toNamed(AppRoutes.today),
          ),
          _StatCard(
            icon: Icons.person_off_rounded,
            tag: 'NOT MARKED',
            value: '${dash?.summary.notMarked ?? 0}',
            sub: 'Attendance pending',
            color: AppColors.amber,
            onTap: () => Get.toNamed(AppRoutes.today),
          ),
        ],
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final String tag;
  final IconData icon;
  final String value;
  final String sub;
  final Color color;
  final VoidCallback? onTap;
  const _StatCard({
    required this.tag,
    required this.icon,
    required this.value,
    required this.sub,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpace.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, color: color, size: AppIconSize.sm),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTs.stat(color: color)),
                const SizedBox(height: AppSpace.xs),
                Text(tag, style: AppTs.tag()),
                Text(sub,
                    style: AppTs.caption(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Live Tracker ──────────────────────────────────────────────────────────────

class _TrackerGrid extends StatelessWidget {
  final DashboardModel? dash;
  const _TrackerGrid({this.dash});

  @override
  Widget build(BuildContext context) {
    final items = [
      _TrackerItem(
        icon: Icons.login_rounded,
        color: AppColors.emerald,
        value: '${dash?.summary.currentlyIn ?? 0}',
        label: 'Currently In',
      ),
      _TrackerItem(
        icon: Icons.pending_actions_rounded,
        color: AppColors.amber,
        value: '${dash?.summary.notMarked ?? 0}',
        label: 'Not Marked',
      ),
      _TrackerItem(
        icon: Icons.check_circle_rounded,
        color: AppColors.primaryLight,
        value: '${dash?.summary.present ?? 0}',
        label: 'Present',
      ),
      _TrackerItem(
        icon: Icons.warning_amber_rounded,
        color: AppColors.rose,
        value: '${dash?.summary.late ?? 0}',
        label: 'Late Today',
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpace.md,
      mainAxisSpacing: AppSpace.md,
      childAspectRatio: 2.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items.map((item) => _TrackerCard(item: item)).toList(),
    );
  }
}

class _TrackerItem {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _TrackerItem(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});
}

class _TrackerCard extends StatelessWidget {
  final _TrackerItem item;
  const _TrackerCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg, vertical: AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: item.color.withValues(alpha: 0.25)),
            ),
            child: Icon(item.icon, color: item.color, size: AppIconSize.md),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.value, style: AppTs.statMd(color: item.color)),
                Text(item.label,
                    style: AppTs.caption(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Nav ─────────────────────────────────────────────────────────────────

class _QuickNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.face_rounded,
        'Face Scan',
        AppColors.primary,
        () => _openFaceScan(context)
      ),
      (
        Icons.group_rounded,
        'Employees',
        AppColors.emerald,
        () => Get.toNamed(AppRoutes.employees)
      ),
      (
        Icons.today_rounded,
        'Attendance',
        AppColors.cyan,
        () => Get.toNamed(AppRoutes.today)
      ),
      (
        Icons.settings_rounded,
        'Settings',
        AppColors.textMuted,
        () => Get.toNamed(AppRoutes.settings)
      ),
    ];
    return Row(
      children: items
          .map((t) => Expanded(
                  child: Padding(
                padding:
                    EdgeInsets.only(right: t == items.last ? 0 : AppSpace.sm),
                child:
                    _NavCard(icon: t.$1, label: t.$2, color: t.$3, onTap: t.$4),
              )))
          .toList(),
    );
  }

  void _openFaceScan(BuildContext context) {
    if (Get.previousRoute == AppRoutes.faceScan && Navigator.canPop(context)) {
      Get.back();
      return;
    }
    Get.offNamed(AppRoutes.faceScan);
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _NavCard(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: AppIconSize.xl),
              const SizedBox(height: AppSpace.sm),
              Text(label,
                  style: AppTs.caption(color: AppColors.textSecondary)
                      .copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

// ── Employee Status Tile ──────────────────────────────────────────────────────

class _EmployeeTile extends StatelessWidget {
  final TodayEmployeeStatus emp;
  const _EmployeeTile({required this.emp});

  @override
  Widget build(BuildContext context) {
    final isIn = emp.currentState == 'in';
    final stColor = isIn ? AppColors.emerald : AppColors.textMuted;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg, vertical: AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _MiniAvatar(name: emp.name),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emp.name,
                    style: AppTs.label(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (emp.checkIn?.isNotEmpty == true)
                  Text(
                    'In: ${TimeUtils.fmtTime(emp.checkIn ?? '')}  ·  ${emp.punches.length} punch(es)',
                    style: AppTs.caption(),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md, vertical: AppSpace.xs),
            decoration: BoxDecoration(
              color: stColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              emp.currentState.toUpperCase(),
              style: AppTs.tag(color: stColor)
                  .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final String name;
  const _MiniAvatar({required this.name});
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
            style: GoogleFonts.outfit(
                fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
      );
}

// ── Error strip ───────────────────────────────────────────────────────────────

class _ErrorStrip extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorStrip({required this.msg, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: AppSpace.xl),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg, vertical: AppSpace.md),
        decoration: BoxDecoration(
          color: AppColors.rose.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.rose.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.rose, size: AppIconSize.sm),
            const SizedBox(width: AppSpace.md),
            Expanded(
                child:
                    Text(msg, style: AppTs.bodySmall(color: AppColors.rose))),
            TextButton(
              onPressed: onRetry,
              child: Text('Retry',
                  style: AppTs.bodySmall(color: AppColors.primaryLight)),
            ),
          ],
        ),
      );
}
