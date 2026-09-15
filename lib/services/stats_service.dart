import 'package:dio/dio.dart';

class StatsService {
  final Dio _dio;
  StatsService(this._dio);

  Future<Map<String, dynamic>> getStats() async {
    final response = await _dio.get('/api/admin/stats');
    return response.data['stats'] as Map<String, dynamic>;
  }
}
