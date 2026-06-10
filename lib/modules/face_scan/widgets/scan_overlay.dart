import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../face_scan_controller.dart';

/// Animated scan frame — corners pulse green on match, red on error
class ScanOverlay extends StatefulWidget {
  final ScanState state;
  const ScanOverlay({super.key, required this.state});

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scanLine;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _scanLine = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _pulse = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _frameColor {
    switch (widget.state) {
      case ScanState.matched:
      case ScanState.success:
        return AppColors.success;
      case ScanState.error:
        return AppColors.error;
      case ScanState.punching:
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final fSize  = (size.width * 0.72).clamp(280.0, 460.0);
    final color  = _frameColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Dark vignette outside frame
        CustomPaint(
          painter: _VignettePainter(fSize: fSize),
        ),
        // Scan frame + line
        Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Transform.scale(
              scale: widget.state == ScanState.matched ? _pulse.value : 1.0,
              child: SizedBox(
                width: fSize,
                height: fSize,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(fSize, fSize),
                      painter: _CornerPainter(color: color),
                    ),
                    if (widget.state == ScanState.detecting ||
                        widget.state == ScanState.idle)
                      Positioned(
                        top: _scanLine.value * fSize,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              color.withValues(alpha: 0.8),
                              Colors.transparent,
                            ]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VignettePainter extends CustomPainter {
  final double fSize;
  _VignettePainter({required this.fSize});

  @override
  void paint(Canvas canvas, Size size) {
    final cx   = size.width / 2;
    final cy   = size.height / 2;
    final half = fSize / 2;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(cx - half, cy - half, cx + half, cy + half),
          const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
        path, Paint()..color = Colors.black.withValues(alpha: 0.62));
  }

  @override
  bool shouldRepaint(_VignettePainter old) => old.fSize != fSize;
}

class _CornerPainter extends CustomPainter {
  final Color color;
  const _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color      = color
      ..strokeWidth = 4
      ..strokeCap  = StrokeCap.round
      ..style      = PaintingStyle.stroke;

    const len = 36.0;
    const r   = 14.0;

    void corner(double ox, double oy, double dx, double dy) {
      canvas.drawLine(Offset(ox, oy + r * dy.sign.abs()),
          Offset(ox, oy + len * dy.sign), p);
      canvas.drawLine(Offset(ox + r * dx.sign.abs(), oy),
          Offset(ox + len * dx.sign, oy), p);
    }

    corner(0, 0, 1, 1);
    corner(size.width, 0, -1, 1);
    corner(0, size.height, 1, -1);
    corner(size.width, size.height, -1, -1);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}
