import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../bindings/initial_binding.dart';
import '../core/theme/app_theme.dart';
import '../routes/app_pages.dart';
import '../routes/app_routes.dart';

class PulsaraKioskApp extends StatelessWidget {
  const PulsaraKioskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title:           'Pulsara Kiosk',
      debugShowCheckedModeBanner: false,
      theme:           AppTheme.dark,
      initialRoute:    AppRoutes.splash,
      getPages:        AppPages.pages,
      initialBinding: InitialBinding(),
      defaultTransition: Transition.fadeIn,
    );
  }
}
