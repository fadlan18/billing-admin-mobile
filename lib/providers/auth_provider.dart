import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/admin_user.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final _storage = const FlutterSecureStorage();

  AdminUser? _user;
  bool _isLoading = true;

  AuthProvider(this._apiClient) {
    _tryAutoLogin();
  }

  AdminUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  Future<void> _tryAutoLogin() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      try {
        final response = await _apiClient.dio.get('/api/auth/me');
        _user = AdminUser.fromJson(response.data['user']);
      } catch (e) {
        await _storage.deleteAll();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data;
      await _storage.write(key: 'access_token', value: data['access_token']);
      await _storage.write(key: 'refresh_token', value: data['refresh_token']);
      _user = AdminUser.fromJson(data['user']);
      notifyListeners();
      return null;
    } catch (e) {
      return 'Email atau password salah';
    }
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    try {
      await _apiClient.dio.post('/api/auth/logout', data: {
        'refresh_token': refreshToken,
      });
    } catch (e) {
      // tetap logout lokal walau request gagal
    }
    await _storage.deleteAll();
    _user = null;
    notifyListeners();
  }
}
