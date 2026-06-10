import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'auth_controller.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _ctrl = TextEditingController();
  final _c    = Get.find<AuthController>();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading
                Text('Verify OTP', style: AppTs.h1()),
                const SizedBox(height: 8),
                Obx(() => Text(
                      'OTP sent to  +91 ${_c.phone.value}',
                      style: AppTs.bodySmall(),
                    )),
                if (_c.companyName.value.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Obx(() => Text(
                        _c.companyName.value,
                        style: AppTs.label(color: AppColors.primaryLight),
                      )),
                ],
                const SizedBox(height: 36),

                // Field label
                Text('6-DIGIT OTP', style: AppTs.tag()),
                const SizedBox(height: 7),

                // OTP input
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bg3,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: AppTs.mono(size: 28, color: AppColors.textPrimary)
                        .copyWith(
                            fontWeight: FontWeight.w800, letterSpacing: 14),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '• • • • • •',
                      hintStyle: AppTs.mono(
                              size: 22, color: AppColors.textMuted)
                          .copyWith(letterSpacing: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 14),
                    ),
                    onChanged: (v) {
                      if (v.length == 6) _c.verifyOtp(v);
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Error
                Obx(() => _c.errorMsg.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.rose, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(_c.errorMsg.value,
                                  style: AppTs.bodySmall(
                                      color: AppColors.rose)),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink()),

                // Verify button
                Obx(() => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _c.isLoading.value
                            ? null
                            : () => _c.verifyOtp(_ctrl.text),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _c.isLoading.value
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text('Verify & Login →',
                                style: AppTs.label(color: Colors.white)),
                      ),
                    )),
                const SizedBox(height: 16),

                // Back link
                Center(
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: Text('← Change Number',
                        style: AppTs.bodySmall(
                            color: AppColors.textSecondary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
