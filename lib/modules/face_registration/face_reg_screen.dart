import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'face_reg_controller.dart';

class FaceRegScreen extends StatelessWidget {
  const FaceRegScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(FaceRegController());

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
              return Container(
                color: AppColors.bg,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_off_rounded,
                          color: AppColors.textMuted, size: 56),
                      const SizedBox(height: AppSpace.md),
                      Text(c.cameraError.value,
                          textAlign: TextAlign.center,
                          style: AppTs.bodySmall()),
                    ],
                  ),
                ),
              );
            }
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            );
          }),

          // ── Oval face guide ────────────────────────────────────────────────
          CustomPaint(painter: _OvalPainter()),

          // ── Top bar ────────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _TopBar(c: c)),
          ),

          // ── Bottom panel ───────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomPanel(c: c),
          ),
        ],
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final FaceRegController c;
  const _TopBar({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.xs, AppSpace.sm, AppSpace.lg, AppSpace.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.80), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Face Registration',
                    style: AppTs.label(color: Colors.white)),
                Text(c.employee.name,
                    style: AppTs.caption(color: Colors.white60)),
              ],
            ),
          ),
          // Remove face button
          if (c.employee.hasFace)
            TextButton.icon(
              onPressed: () => _confirmRemove(c),
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.rose, size: AppIconSize.sm),
              label: Text('Remove',
                  style: AppTs.bodySmall(color: AppColors.rose)
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  void _confirmRemove(FaceRegController c) {
    Get.dialog(AlertDialog(
      title: const Text('Remove Face Data'),
      content: Text('Delete the registered face for ${c.employee.name}?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Get.back();
            c.deleteFace();
          },
          child: const Text('Remove',
              style: TextStyle(
                  color: AppColors.rose, fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }
}

// ── Bottom panel ──────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  final FaceRegController c;
  const _BottomPanel({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.xl, AppSpace.xl, 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.92),
            Colors.transparent,
          ],
        ),
      ),
      child: Obx(() {
        final state = c.regState.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status message
            _StatusRow(state: state, msg: c.statusMsg.value),
            const SizedBox(height: AppSpace.xl),

            // Action area
            if (state == RegState.idle || state == RegState.error)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      c.isCameraReady.value ? c.captureAndRegister : null,
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: Text(
                    c.employee.hasFace ? 'Update Face' : 'Register Face',
                    style: AppTs.label(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
              )
            else if (state == RegState.capturing ||
                state == RegState.processing)
              const SizedBox(
                height: 52,
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryLight, strokeWidth: 2.5),
                ),
              )
            else if (state == RegState.success)
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.40)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.emerald, size: AppIconSize.lg),
                    const SizedBox(width: AppSpace.md),
                    Text('Registered!',
                        style: AppTs.label(color: AppColors.emerald)),
                  ],
                ),
              ),

            // Tips
            if (state == RegState.idle) ...[
              const SizedBox(height: AppSpace.lg),
              Text(
                'Tips: Good lighting  ·  Face camera directly  ·  Remove glasses',
                textAlign: TextAlign.center,
                style: AppTs.caption(color: Colors.white38),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final RegState state;
  final String msg;
  const _StatusRow({required this.state, required this.msg});

  @override
  Widget build(BuildContext context) {
    final isProcessing =
        state == RegState.capturing || state == RegState.processing;
    final msgColor = state == RegState.success
        ? AppColors.emerald
        : state == RegState.error
            ? AppColors.rose
            : Colors.white;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isProcessing) ...[
          const SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
                strokeWidth: 1.8, color: AppColors.primaryLight),
          ),
          const SizedBox(width: AppSpace.md),
        ],
        if (state == RegState.success) ...[
          const Icon(Icons.check_circle_rounded,
              color: AppColors.emerald, size: AppIconSize.sm),
          const SizedBox(width: AppSpace.sm),
        ],
        if (state == RegState.error) ...[
          const Icon(Icons.error_outline_rounded,
              color: AppColors.rose, size: AppIconSize.sm),
          const SizedBox(width: AppSpace.sm),
        ],
        Flexible(
          child: Text(msg,
              textAlign: TextAlign.center,
              style: AppTs.bodySmall(color: msgColor)
                  .copyWith(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

// ── Oval overlay painter ──────────────────────────────────────────────────────

class _OvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 10;
    final rx = size.width * 0.42;
    final ry = size.height * 0.33;

    final oval =
        Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2);

    // Dim outside
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(oval)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
        path, Paint()..color = Colors.black.withValues(alpha: 0.52));

    // Oval border — primary violet
    canvas.drawOval(
      oval,
      Paint()
        ..color = AppColors.primaryMid.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_OvalPainter _) => false;
}
