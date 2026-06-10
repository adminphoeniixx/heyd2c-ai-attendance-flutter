import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'splash_controller.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SplashController());

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background grid texture (matches Velo sidebar) ─────────────────
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),

          // ── Top-left ambient glow ──────────────────────────────────────────
          Positioned(
            top: -100, left: -80,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.22),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Bottom-right fuchsia glow ──────────────────────────────────────
          Positioned(
            bottom: -80, right: -60,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.fuchsia.withValues(alpha: 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Center content ─────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo icon
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.fuchsia],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.40),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.face_rounded,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: 20),

                // App name
                Text('Pulsara', style: AppTs.h1()),
                const SizedBox(height: 4),
                Text('KIOSK ATTENDANCE',
                    style: AppTs.tag(color: AppColors.primaryMid)
                        .copyWith(fontSize: 11, letterSpacing: 3)),
                const SizedBox(height: 48),

                // Spinner
                const SpinKitFadingCircle(
                  color: AppColors.primaryMid,
                  size: 32,
                ),
                const SizedBox(height: 16),

                Text('Initialising…',
                    style: AppTs.caption(color: AppColors.textMuted)),
              ],
            ),
          ),

          // ── Version footer ─────────────────────────────────────────────────
          Positioned(
            bottom: 28, left: 0, right: 0,
            child: Center(
              child: Text('v1.0.0',
                  style: AppTs.tag(color: AppColors.textMuted)
                      .copyWith(letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid texture painter (same as Velo sidebar ::before) ─────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = AppColors.border.withValues(alpha: 0.35)
      ..strokeWidth = 0.5;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}
