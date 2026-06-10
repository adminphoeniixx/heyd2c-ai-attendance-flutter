import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/time_utils.dart';
import '../../routes/app_routes.dart';
import 'face_scan_controller.dart';
import 'widgets/employee_match_card.dart';
import 'widgets/scan_overlay.dart';

class FaceScanScreen extends StatelessWidget {
  const FaceScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(FaceScanController());

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera preview ─────────────────────────────────────────────────
          Obx(() {
            if (c.isCameraReady.value && c.cameraCtrl != null) {
              return CameraPreview(c.cameraCtrl!);
            }
            if (c.cameraError.isNotEmpty) {
              return _CameraError(msg: c.cameraError.value);
            }
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            );
          }),

          // ── Scan overlay ────────────────────────────────────────────────────
          Obx(() => ScanOverlay(state: c.scanState.value)),

          // ── Top bar ─────────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _TopBar(c: c)),
          ),

          // ── Status banner ───────────────────────────────────────────────────
          Obx(() {
            final isCard = c.scanState.value == ScanState.matched ||
                c.scanState.value == ScanState.punching ||
                c.scanState.value == ScanState.success;
            if (isCard) return const SizedBox.shrink();
            return Positioned(
              bottom: 130,
              left: 0,
              right: 0,
              child: _StatusBanner(
                  msg: c.statusMsg.value, state: c.scanState.value),
            );
          }),

          // ── Employee match card ─────────────────────────────────────────────
          Obx(() {
            final emp = c.matchedEmp.value;
            if (emp == null) return const SizedBox.shrink();
            return Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: EmployeeMatchCard(
                employee: emp,
                similarity: c.matchSimilarity.value,
                state: c.scanState.value,
                punchType: c.lastPunchType.value,
                punchTime: c.lastPunchTime.value,
                onManualConfirm: c.manualPunch,
              ),
            );
          }),

          // ── Bottom nav ──────────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Obx(() {
              if (c.matchedEmp.value != null) return const SizedBox.shrink();
              return _BottomNav(c: c);
            }),
          ),

          // ── Attendance confirmation overlay ─────────────────────────────────
          Obx(() => _AttendanceConfirmOverlay(
                state: c.scanState.value,
                emp: c.matchedEmp.value,
                punchType: c.lastPunchType.value,
                punchTime: c.lastPunchTime.value,
              )),
        ],
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final FaceScanController c;
  const _TopBar({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.80),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Clock + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(TimeUtils.displayDate(),
                    style: AppTs.tag(color: Colors.white60)),
                StreamBuilder<DateTime>(
                  stream: Stream.periodic(
                      const Duration(seconds: 1), (_) => DateTime.now()),
                  builder: (_, snap) {
                    final t = snap.data ?? DateTime.now();
                    return Text(
                      '${t.hour.toString().padLeft(2, '0')}:'
                      '${t.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                          color: Colors.white),
                    );
                  },
                ),
              ],
            ),
          ),
          // Online badge
          Obx(() => _Pill(
                label: c.isOnline.value ? 'Online' : 'Offline',
                icon: c.isOnline.value
                    ? Icons.wifi_rounded
                    : Icons.wifi_off_rounded,
                color: c.isOnline.value ? AppColors.emerald : AppColors.rose,
              )),
          const SizedBox(width: AppSpace.sm),
          // Pending badge
          Obx(() => c.pendingCount.value > 0
              ? Padding(
                  padding: const EdgeInsets.only(right: AppSpace.sm),
                  child: _Pill(
                    label: '${c.pendingCount.value} pending',
                    icon: Icons.cloud_off_rounded,
                    color: AppColors.amber,
                  ),
                )
              : const SizedBox.shrink()),
          // Dashboard button
          _GlassBtn(
            icon: Icons.grid_view_rounded,
            onTap: () => _openRoute(AppRoutes.dashboard),
          ),
        ],
      ),
    );
  }

  Future<void> _openRoute(String route) async {
    await c.pauseScanning(releaseCamera: true);
    await Get.toNamed(route);
    await c.resumeScanning();
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Pill({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md, vertical: AppSpace.xs),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: AppIconSize.xs),
            const SizedBox(width: AppSpace.xs),
            Text(label,
                style: AppTs.tag(color: color)
                    .copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, color: Colors.white, size: AppIconSize.md),
        ),
      );
}

// ── Status Banner ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final String msg;
  final ScanState state;
  const _StatusBanner({required this.msg, required this.state});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.xl, vertical: AppSpace.md),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 24,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state == ScanState.detecting)
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.8, color: AppColors.primaryLight),
                ),
              if (state == ScanState.detecting)
                const SizedBox(width: AppSpace.md),
              Flexible(
                child: Text(msg,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      );
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final FaceScanController c;
  const _BottomNav({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.xl, AppSpace.lg, AppSpace.xl, AppSpace.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.88),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavBtn(
              icon: Icons.group_rounded,
              label: 'Employees',
              onTap: () => _openRoute(AppRoutes.employees)),
          _NavBtn(
              icon: Icons.today_rounded,
              label: 'Today',
              onTap: () => _openRoute(AppRoutes.today)),
          _NavBtn(
              icon: Icons.cloud_sync_rounded,
              label: 'Sync',
              onTap: () => _openRoute(AppRoutes.syncQueue)),
          _NavBtn(
              icon: Icons.settings_rounded,
              label: 'Settings',
              onTap: () => _openRoute(AppRoutes.settings)),
        ],
      ),
    );
  }

  Future<void> _openRoute(String route) async {
    await c.pauseScanning(releaseCamera: true);
    await Get.toNamed(route);
    await c.resumeScanning();
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Icon(icon, color: Colors.white, size: AppIconSize.lg),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(label,
                style: AppTs.tag(color: Colors.white60)
                    .copyWith(fontSize: 10, letterSpacing: 0)),
          ],
        ),
      );
}

// ── Attendance Confirmation Overlay ──────────────────────────────────────────
// Shown full-screen for 3 seconds when punch succeeds or fails.

class _AttendanceConfirmOverlay extends StatefulWidget {
  final ScanState state;
  final dynamic emp; // EmployeeModel? — avoid import cycle
  final String punchType; // 'punch_in' | 'punch_out'
  final String punchTime; // HH:mm:ss

  const _AttendanceConfirmOverlay({
    required this.state,
    required this.emp,
    required this.punchType,
    required this.punchTime,
  });

  @override
  State<_AttendanceConfirmOverlay> createState() =>
      _AttendanceConfirmOverlayState();
}

class _AttendanceConfirmOverlayState extends State<_AttendanceConfirmOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(_AttendanceConfirmOverlay old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) _syncAnimation();
  }

  void _syncAnimation() {
    final show =
        widget.state == ScanState.success || widget.state == ScanState.error;
    if (show) {
      _ctrl.forward(from: 0);
    } else {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.state == ScanState.success;
    final isError = widget.state == ScanState.error;
    if (!isSuccess && !isError) return const SizedBox.shrink();

    final isIn = widget.punchType == 'punch_in';
    final accent = isSuccess
        ? (isIn ? AppColors.emerald : AppColors.cyan)
        : AppColors.rose;
    final empName = widget.emp?.name as String? ?? '';
    final time =
        widget.punchTime.isNotEmpty ? TimeUtils.fmtTime(widget.punchTime) : '';

    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        alignment: Alignment.center,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xxl, vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border:
                  Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.22),
                  blurRadius: 48,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon circle ───────────────────────────────────────────────
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: accent.withValues(alpha: 0.40), width: 2),
                  ),
                  child: Icon(
                    isSuccess
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    color: accent,
                    size: 48,
                  ),
                ),
                const SizedBox(height: AppSpace.xl),

                // ── Headline ──────────────────────────────────────────────────
                Text(
                  isSuccess ? 'Attendance Marked!' : 'Attendance Failed',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),

                // ── Employee name ─────────────────────────────────────────────
                if (empName.isNotEmpty)
                  Text(
                    empName,
                    textAlign: TextAlign.center,
                    style: AppTs.h3(color: AppColors.textPrimary),
                  ),
                const SizedBox(height: AppSpace.md),

                // ── Punch detail chip ─────────────────────────────────────────
                if (isSuccess) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.xl, vertical: AppSpace.md),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: accent.withValues(alpha: 0.30)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Icon(
                          isIn ? Icons.login_rounded : Icons.logout_rounded,
                          color: accent,
                          size: AppIconSize.md,
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Flexible(
                          child: Text(
                            isIn
                                ? 'Punched In  •  $time'
                                : 'Punched Out  •  $time',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'Could not record attendance.\nPlease try again.',
                    textAlign: TextAlign.center,
                    style: AppTs.body(color: AppColors.textSecondary),
                  ),
                ],

                const SizedBox(height: AppSpace.xl),

                // ── Auto-dismiss hint ─────────────────────────────────────────
                Text(
                  'Closing automatically…',
                  style: AppTs.caption(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Camera error ──────────────────────────────────────────────────────────────

class _CameraError extends StatelessWidget {
  final String msg;
  const _CameraError({required this.msg});

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.bg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_rounded,
                  color: AppColors.textMuted, size: 56),
              const SizedBox(height: AppSpace.lg),
              Text(msg, textAlign: TextAlign.center, style: AppTs.bodySmall()),
            ],
          ),
        ),
      );
}
