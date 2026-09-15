import 'package:dio/dio.dart';

class AuditLogService {
  final Dio _dio;
  AuditLogService(this._dio);

  Future<Map<String, dynamic>> getLogs({int limit = 20, int offset = 0}) async {
    final response = await _dio.get('/api/admin/audit-logs', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
    return response.data as Map<String, dynamic>;
  }
}
