import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

class DioClient {
  DioClient._();
  static final DioClient instance = DioClient._();

  Dio? _dio;

  void init() {
    if (_dio != null) return;
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout:
            const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout:
            const Duration(milliseconds: ApiConstants.receiveTimeout),
        responseType: ResponseType.json,
      ),
    );
    dio.interceptors.addAll([
      AuthInterceptor(),
      ErrorInterceptor(),
    ]);
    _dio = dio;
  }

  Dio get dio {
    init();
    return _dio!;
  }

  // ── Convenience wrappers ────────────────────────────────────────────────

  Future<Response<T>> get<T>(String path,
          {Map<String, dynamic>? queryParams}) =>
      dio.get<T>(path, queryParameters: queryParams);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      dio.post<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => dio.delete<T>(path);
}
