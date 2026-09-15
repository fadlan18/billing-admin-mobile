import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/admin_user.dart';
import '../services/api_client.dart';
import '../services/push_service.dart';
import '../services/biometric_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final _storage = const FlutterSecureStorage();
  final _biometricService = BiometricService();

  AdminUser? _user;
  bool _isLoading = true;
  bool _needsBiometricUnlock = false;

  AuthProvider(this._apiClient) {
    _tryAutoLogin();
  }

  AdminUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get needsBiometricUnlock => _needsBiometricUnlock;

  Future<void> _tryAutoLogin() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      final biometricEnabled = await _biometricService.isEnabled();
      if (biometricEnabled) {
        _needsBiometricUnlock = true;
        _isLoading = false;
        notifyListeners();
        return;
      }
      await _fetchCurrentUser();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> _fetchCurrentUser() async {
    try {
      final response = await _apiClient.dio.get('/api/auth/me');
      _user = AdminUser.fromJson(response.data['user']);
      return true;
    } catch (e) {
      await _storage.deleteAll();
      return false;
    }
  }

  Future<bool> unlockWithBiometric() async {
    final success = await _biometricService.authenticate();
    if (!success) return false;

    final fetched = await _fetchCurrentUser();
    _needsBiometricUnlock = !fetched;
    notifyListeners();
    return fetched;
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
      _needsBiometricUnlock = false;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Email atau password salah';
    }
  }

  Future<bool> isBiometricAvailable() => _biometricService.isDeviceSupported();
  Future<bool> isBiometricEnabled() => _biometricService.isEnabled();
  Future<void> setBiometricEnabled(bool enabled) => _biometricService.setEnabled(enabled);

  /// Kunci layar (dipakai kalau biometric aktif)  token tetap tersimpan,
  /// tidak revoke ke server, cukup butuh fingerprint untuk kembali masuk.
  Future<void> lock() async {
    _user = null;
    _needsBiometricUnlock = true;
    notifyListeners();
  }

  /// Keluar total dari akun  revoke refresh token, hapus semua data lokal.
  Future<void> logout() async {
    try {
      final pushService = PushService(_apiClient.dio);
      await pushService.unregisterCurrentToken();
    } catch (e) {
      // abaikan, tetap lanjut logout
    }

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
    _needsBiometricUnlock = false;
    notifyListeners();
  }

  /// Dipanggil dari tombol logout di UI  pintar pilih lock() atau logout()
  /// tergantung apakah biometric aktif.
  Future<void> handleLogoutButtonPressed() async {
    final biometricEnabled = await _biometricService.isEnabled();
    if (biometricEnabled) {
      await lock();
    } else {
      await logout();
    }
  }
}
