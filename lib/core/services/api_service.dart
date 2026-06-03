import 'package:dio/dio.dart';

class ApiService {
  ApiService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  void Function()? _onUnauthorized;

  Dio get client => _dio;

  void setUnauthorizedCallback(void Function() callback) {
    if (_onUnauthorized != null) return;
    _onUnauthorized = callback;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _onUnauthorized?.call();
          }
          return handler.next(error);
        },
      ),
    );
  }

  void setAuthToken(String? token) {
    if (token == null || token.trim().isEmpty) {
      _dio.options.headers.remove('Authorization');
      return;
    }
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
}
