import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'add_employee_controller.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _nameCon      = TextEditingController();
  final _empIdCon     = TextEditingController();
  final _desgCon      = TextEditingController();
  final _deptCon      = TextEditingController();

  late final AddEmployeeController c;

  @override
  void initState() {
    super.initState();
    c = Get.put(AddEmployeeController());
  }

  @override
  void dispose() {
    _nameCon.dispose();
    _empIdCon.dispose();
    _desgCon.dispose();
    _deptCon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => c.step.value == AddEmpStep.form
        ? _FormStep(
            c:        c,
            nameCon:  _nameCon,
            empIdCon: _empIdCon,
            desgCon:  _desgCon,
            deptCon:  _deptCon,
          )
        : _FaceStep(c: c, nameCon: _nameCon, empIdCon: _empIdCon,
            desgCon: _desgCon, deptCon: _deptCon));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Step 1 — Employee Details Form
// ─────────────────────────────────────────────────────────────────────────────

class _FormStep extends StatelessWidget {
  final AddEmployeeController c;
  final TextEditingController nameCon;
  final TextEditingController empIdCon;
  final TextEditingController desgCon;
  final TextEditingController deptCon;

  const _FormStep({
    required this.c,
    required this.nameCon,
    required this.empIdCon,
    required this.desgCon,
    required this.deptCon,
  });

  @override
  Widget build(BuildContext context) {
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
            Text('Add Employee', style: AppTs.h3()),
            Text('Step 1 of 2 — Details', style: AppTs.tag()),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          const LinearProgressIndicator(
            value: 0.5,
            backgroundColor: AppColors.surface,
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 3,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Avatar placeholder
                  Center(
                    child: Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.fuchsia]),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.border2, width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.person_add_rounded,
                            color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Form fields
                  _Field(
                    label:       'Full Name *',
                    hint:        'e.g. Rahul Sharma',
                    controller:  nameCon,
                    icon:        Icons.badge_outlined,
                    errorObs:    c.nameError,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  _Field(
                    label:      'Employee ID *',
                    hint:       'e.g. EMP001',
                    controller: empIdCon,
                    icon:       Icons.tag_rounded,
                    errorObs:   c.empIdError,
                  ),
                  const SizedBox(height: 16),
                  _Field(
                    label:      'Designation *',
                    hint:       'e.g. Software Engineer',
                    controller: desgCon,
                    icon:       Icons.work_outline_rounded,
                    errorObs:   c.designationError,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  _Field(
                    label:      'Department *',
                    hint:       'e.g. Engineering',
                    controller: deptCon,
                    icon:       Icons.business_outlined,
                    errorObs:   c.departmentError,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 32),

                  // Next button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (c.validateForm(
                          name:        nameCon.text,
                          empId:       empIdCon.text,
                          designation: desgCon.text,
                          department:  deptCon.text,
                        )) {
                          FocusScope.of(context).unfocus();
                          c.goToFaceStep();
                        }
                      },
                      icon:  const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text('Next — Capture Face',
                          style: AppTs.label(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Step 2 — Face Capture
// ─────────────────────────────────────────────────────────────────────────────

class _FaceStep extends StatelessWidget {
  final AddEmployeeController c;
  final TextEditingController nameCon;
  final TextEditingController empIdCon;
  final TextEditingController desgCon;
  final TextEditingController deptCon;

  const _FaceStep({
    required this.c,
    required this.nameCon,
    required this.empIdCon,
    required this.desgCon,
    required this.deptCon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
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
                          color: AppColors.textMuted, size: 64),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(c.cameraError.value,
                            textAlign: TextAlign.center,
                            style: AppTs.bodySmall()),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            );
          }),

          // Oval face guide
          CustomPaint(painter: _OvalPainter()),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(child: _FaceTopBar(c: c, name: nameCon.text)),
          ),

          // Progress
          const Positioned(
            top: 0, left: 0, right: 0,
            child: LinearProgressIndicator(
              value: 1.0,
              backgroundColor: AppColors.surface,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 3,
            ),
          ),

          // Bottom panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _FaceBottomPanel(
              c:       c,
              nameCon: nameCon,
              empIdCon:empIdCon,
              desgCon: desgCon,
              deptCon: deptCon,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceTopBar extends StatelessWidget {
  final AddEmployeeController c;
  final String name;
  const _FaceTopBar({required this.c, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.82), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () {
              c.step.value = AddEmpStep.form;
              final cam = c.cameraCtrl;
              if (cam != null && cam.value.isInitialized) {
                cam.dispose();
                c.cameraCtrl = null;
              }
              c.isCameraReady.value = false;
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Face Capture', style: AppTs.label(color: Colors.white)),
                Text('Step 2 of 2 — ${name.isEmpty ? 'Employee' : name}',
                    style: AppTs.caption(color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceBottomPanel extends StatelessWidget {
  final AddEmployeeController c;
  final TextEditingController nameCon;
  final TextEditingController empIdCon;
  final TextEditingController desgCon;
  final TextEditingController deptCon;

  const _FaceBottomPanel({
    required this.c,
    required this.nameCon,
    required this.empIdCon,
    required this.desgCon,
    required this.deptCon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.94), Colors.transparent],
        ),
      ),
      child: Obx(() {
        final state      = c.captureState.value;
        final submitting = c.isSubmitting.value;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status message
            _StatusRow(state: state, msg: c.faceMsg.value),
            const SizedBox(height: 16),

            // Error from submit
            if (c.submitError.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.rose.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.rose.withValues(alpha: 0.35)),
                ),
                child: Text(c.submitError.value,
                    textAlign: TextAlign.center,
                    style: AppTs.bodySmall(color: AppColors.rose)),
              ),
              const SizedBox(height: 12),
            ],

            // Buttons based on state
            if (state == FaceCaptureState.idle || state == FaceCaptureState.error)
              _ActionBtn(
                icon:    Icons.camera_alt_rounded,
                label:   'Capture Face',
                onTap:   c.isCameraReady.value ? c.captureface : null,
              )
            else if (state == FaceCaptureState.capturing ||
                state == FaceCaptureState.processing)
              const SizedBox(
                height: 52,
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryLight, strokeWidth: 2.5),
                ),
              )
            else if (state == FaceCaptureState.captured) ...[
              // Save with face
              if (submitting)
                const SizedBox(
                  height: 52,
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryLight, strokeWidth: 2.5),
                  ),
                )
              else ...[
                _ActionBtn(
                  icon:  Icons.save_rounded,
                  label: 'Save Employee',
                  color: AppColors.emerald,
                  onTap: () => c.submit(
                    name:        nameCon.text,
                    empId:       empIdCon.text,
                    designation: desgCon.text,
                    department:  deptCon.text,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: c.retakePhoto,
                    child: Text('Retake Photo',
                        style: AppTs.label(color: AppColors.textSecondary)),
                  ),
                ),
              ],
            ],

            if (state == FaceCaptureState.idle) ...[
              const SizedBox(height: 6),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    this.color = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon:  Icon(icon, size: 18),
          label: Text(label, style: AppTs.label(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 52),
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
}

class _StatusRow extends StatelessWidget {
  final FaceCaptureState state;
  final String           msg;
  const _StatusRow({required this.state, required this.msg});

  @override
  Widget build(BuildContext context) {
    final isProcessing = state == FaceCaptureState.capturing ||
        state == FaceCaptureState.processing;
    final msgColor = state == FaceCaptureState.captured
        ? AppColors.emerald
        : state == FaceCaptureState.error
            ? AppColors.rose
            : Colors.white;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isProcessing) ...[
          const SizedBox(
            width: 13, height: 13,
            child: CircularProgressIndicator(
                strokeWidth: 1.8, color: AppColors.primaryLight),
          ),
          const SizedBox(width: 10),
        ],
        if (state == FaceCaptureState.captured) ...[
          const Icon(Icons.check_circle_rounded,
              color: AppColors.emerald, size: 15),
          const SizedBox(width: 8),
        ],
        if (state == FaceCaptureState.error) ...[
          const Icon(Icons.error_outline_rounded,
              color: AppColors.rose, size: 15),
          const SizedBox(width: 8),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Form field widget
// ─────────────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String                  label;
  final String                  hint;
  final TextEditingController   controller;
  final IconData                icon;
  final RxString                errorObs;
  final TextCapitalization      textCapitalization;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    required this.errorObs,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final err = errorObs.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTs.bodySmall(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: err.isNotEmpty ? AppColors.rose : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(icon,
                      color: err.isNotEmpty
                          ? AppColors.rose
                          : AppColors.textMuted,
                      size: 16),
                ),
                Expanded(
                  child: TextField(
                    controller:         controller,
                    textCapitalization: textCapitalization,
                    style: AppTs.body(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText:      hint,
                      hintStyle:     AppTs.body(color: AppColors.textMuted),
                      border:        InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (_) {
                      if (err.isNotEmpty) errorObs.value = '';
                    },
                  ),
                ),
              ],
            ),
          ),
          if (err.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(err, style: AppTs.caption(color: AppColors.rose)),
          ],
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Oval overlay painter (same as face_reg_screen)
// ─────────────────────────────────────────────────────────────────────────────

class _OvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 10;
    final rx = size.width * 0.42;
    final ry = size.height * 0.33;

    final oval = Rect.fromCenter(
        center: Offset(cx, cy), width: rx * 2, height: ry * 2);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(oval)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
        path, Paint()..color = Colors.black.withValues(alpha: 0.52));

    canvas.drawOval(
      oval,
      Paint()
        ..color       = AppColors.primaryMid.withValues(alpha: 0.85)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_OvalPainter _) => false;
}
