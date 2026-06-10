import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AuthController());

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ── Ambient glows ─────────────────────────────────────────────────
          Positioned(
            top: -120, left: -80,
            child: Container(
              width: 380, height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.18),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -80, right: -60,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.fuchsia.withValues(alpha: 0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Card ──────────────────────────────────────────────────────────
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo mark
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.fuchsia],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.face_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pulsara', style: AppTs.h2()),
                            Text('KIOSK ATTENDANCE', style: AppTs.tag()),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 44),

                    Text('Sign In', style: AppTs.h1()),
                    const SizedBox(height: 6),
                    Text(
                      'Enter your admin phone number to continue.',
                      style: AppTs.bodySmall(),
                    ),
                    const SizedBox(height: 32),

                    // Field label
                    Text('PHONE NUMBER', style: AppTs.tag()),
                    const SizedBox(height: 7),

                    // Phone input with prefix
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bg3,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: const BoxDecoration(
                              border: Border(
                                  right: BorderSide(
                                      color: AppColors.border)),
                            ),
                            child: Text('+91',
                                style: AppTs.mono(
                                    size: 14,
                                    color: AppColors.textSecondary)),
                          ),
                          Expanded(
                            child: TextField(
                              onChanged: (v) => c.phone.value = v,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              style: AppTs.body(),
                              decoration: InputDecoration(
                                hintText: '10-digit mobile number',
                                hintStyle:
                                    AppTs.body(color: AppColors.textMuted),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Error row
                    Obx(() => c.errorMsg.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: AppColors.rose, size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(c.errorMsg.value,
                                      style: AppTs.bodySmall(
                                          color: AppColors.rose)),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink()),

                    const SizedBox(height: 4),

                    // Primary button
                    Obx(() => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: c.isLoading.value
                                ? null
                                : () => c.sendOtp(c.phone.value),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                            ),
                            child: c.isLoading.value
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2))
                                : Text('Send OTP →',
                                    style: AppTs.label(
                                        color: Colors.white)),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
