import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'app/app.dart';
import 'core/network/dio_client.dart';
import 'core/constants/storage_keys.dart';
import 'core/services/sync_service.dart';
import 'core/utils/app_logger.dart';

// Workmanager background task entry point — must be top-level
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      await Hive.initFlutter();
      await Future.wait([
        Hive.openBox<String>(StorageKeys.employeeBox),
        Hive.openBox<String>(StorageKeys.attendanceBox),
        Hive.openBox<String>(StorageKeys.settingsBox),
        Hive.openBox<String>(StorageKeys.syncQueueBox),
        Hive.openBox<String>(StorageKeys.employeeSyncBox),
        Hive.openBox<String>(StorageKeys.faceSyncBox),
      ]);
      DioClient.instance.init();
      await SyncService.runBackgroundSync();
      return Future.value(true);
    } catch (e) {
      appLogger.e('Background sync error: $e');
      return Future.value(false);
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar over purple AppBar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Init Hive
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox<String>(StorageKeys.employeeBox),
    Hive.openBox<String>(StorageKeys.attendanceBox),
    Hive.openBox<String>(StorageKeys.settingsBox),
    Hive.openBox<String>(StorageKeys.syncQueueBox),
    Hive.openBox<String>(StorageKeys.employeeSyncBox),
    Hive.openBox<String>(StorageKeys.faceSyncBox),
  ]);

  // Init Workmanager for periodic background sync
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    'pulsara_bg_sync',
    'backgroundSync',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
  );

  runApp(const PulsaraKioskApp());
}
