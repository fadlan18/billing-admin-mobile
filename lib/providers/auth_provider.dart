import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
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

  /// Ambil data user dari server. Mengembalikan null kalau berhasil,
  /// atau pesan error kalau gagal. Storage HANYA dihapus jika sesi benar-benar
  /// tidak valid (401 setelah refresh gagal)  bukan untuk gangguan jaringan biasa.
  Future<String?> _fetchCurrentUser() async {
    try {
      final response = await _apiClient.dio.get('/api/auth/me');
      _user = AdminUser.fromJson(response.data['user']);
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Sesi benar-benar tidak valid (refresh token juga sudah gagal/habis)
        await _storage.deleteAll();
        return 'Sesi berakhir, silakan login ulang';
      }
      // Gangguan jaringan/server sementara  jangan hapus apa pun
      return 'Tidak bisa terhubung ke server, periksa koneksi internet';
    } catch (e) {
      return 'Terjadi kesalahan, coba lagi';
    }
  }

  Future<bool> unlockWithBiometric() async {
    final success = await _biometricService.authenticate();
    if (!success) return false;

    final error = await _fetchCurrentUser();
    if (error != null) {
      // Tetap di layar biometric supaya bisa dicoba lagi, KECUALI sesi
      // benar-benar habis (storage sudah kosong, tidak ada token lagi)
      final stillHasToken = await _storage.read(key: 'access_token') != null;
      _needsBiometricUnlock = stillHasToken;
      notifyListeners();
      return false;
    }
    _needsBiometricUnlock = false;
    notifyListeners();
    return true;
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
