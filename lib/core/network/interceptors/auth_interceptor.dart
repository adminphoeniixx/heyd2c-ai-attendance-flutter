import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../constants/storage_keys.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final box = Hive.box<String>(StorageKeys.settingsBox);
    final token = box.get(StorageKeys.kioskToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept']       = 'application/json';
    options.headers['Content-Type'] = 'application/json';
    handler.next(options);
  }
}
