import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'https://paymen.mitranz.com';
  static final _storage = FlutterSecureStorage();

  late final Dio dio;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'x-client': 'mobile'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final opts = error.requestOptions;
            final newToken = await _storage.read(key: 'access_token');
            opts.headers['Authorization'] = 'Bearer $newToken';
            try {
              final retryResponse = await dio.fetch(opts);
              return handler.resolve(retryResponse);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) return false;

    try {
      final response = await Dio().post(
        '$baseUrl/api/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final newAccessToken = response.data['access_token'] as String;
      await _storage.write(key: 'access_token', value: newAccessToken);
      return true;
    } catch (e) {
      await _storage.deleteAll();
      return false;
    }
  }
}
