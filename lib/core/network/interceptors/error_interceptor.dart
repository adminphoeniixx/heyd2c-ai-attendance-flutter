import 'package:dio/dio.dart';
import '../../utils/app_logger.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final path = err.requestOptions.path;
    appLogger.e('API error [$path] ${err.message}');
    handler.next(err);
  }
}
