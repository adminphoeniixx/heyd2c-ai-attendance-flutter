import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/time_utils.dart';
import '../../../data/models/employee_model.dart';
import '../face_scan_controller.dart';

class EmployeeMatchCard extends StatelessWidget {
  final EmployeeModel employee;
  final double similarity;
  final ScanState state;
  final String punchType;
  final String punchTime;
  final VoidCallback onManualConfirm;

  const EmployeeMatchCard({
    super.key,
    required this.employee,
    required this.similarity,
    required this.state,
    required this.punchType,
    required this.punchTime,
    required this.onManualConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = state == ScanState.success;
    final isPunching = state == ScanState.punching;
    final isIn = punchType == 'punch_in';

    final accent = isSuccess
        ? (isIn ? AppColors.punchIn : AppColors.punchOut)
        : AppColors.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      margin:
          const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
            color: accent.withValues(alpha: isSuccess ? 0.5 : 0.35),
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: AppSpace.cardPadding,
            child: Row(
              children: [
                _Avatar(name: employee.name),
                const SizedBox(width: AppSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(employee.name,
                          style: AppTs.h3(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (employee.designation.isNotEmpty)
                        Text(employee.designation, style: AppTs.bodySmall()),
                      if (employee.department.isNotEmpty)
                        Text(employee.department, style: AppTs.caption()),
                    ],
                  ),
                ),
                _ConfidenceBadge(similarity: similarity),
              ],
            ),
          ),

          // ── Divider ─────────────────────────────────────────────────────────
          const Divider(height: 1, color: AppColors.border),

          // ── Footer action ────────────────────────────────────────────────────
          Padding(
            padding: AppSpace.cardPadding,
            child: isSuccess
                ? _SuccessBanner(isIn: isIn, accent: accent, time: punchTime)
                : isPunching
                    ? _PunchingLoader()
                    : _ConfirmButton(
                        punchType: punchType,
                        onTap: onManualConfirm,
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        gradient:
            LinearGradient(colors: [AppColors.primary, AppColors.fuchsia]),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initials,
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double similarity;
  const _ConfidenceBadge({required this.similarity});

  @override
  Widget build(BuildContext context) {
    final pct = (similarity * 100).clamp(0, 100).round();
    final color = pct >= 80
        ? AppColors.emerald
        : pct >= 65
            ? AppColors.amber
            : AppColors.rose;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md, vertical: AppSpace.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text('$pct%',
          style: AppTs.tag(color: color)
              .copyWith(fontSize: 13, fontWeight: FontWeight.w800)),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final bool isIn;
  final Color accent;
  final String time;
  const _SuccessBanner(
      {required this.isIn, required this.accent, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AppSpace.lg, horizontal: AppSpace.xl),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isIn ? Icons.login_rounded : Icons.logout_rounded,
              color: accent, size: AppIconSize.lg),
          const SizedBox(width: AppSpace.md),
          Flexible(
            child: Text(
              isIn
                  ? 'Checked in at ${TimeUtils.fmtTime(time)}'
                  : 'Checked out at ${TimeUtils.fmtTime(time)}',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 15, fontWeight: FontWeight.w700, color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _PunchingLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 48,
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2.5),
        ),
      );
}

class _ConfirmButton extends StatelessWidget {
  final String punchType;
  final VoidCallback onTap;
  const _ConfirmButton({required this.punchType, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIn = punchType != 'punch_out';
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(isIn ? Icons.login_rounded : Icons.logout_rounded, size: 18),
        label: Text(isIn ? 'Confirm Punch In' : 'Confirm Punch Out',
            style:
                GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
    );
  }
}
