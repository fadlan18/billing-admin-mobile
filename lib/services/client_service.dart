import 'package:dio/dio.dart';

class ClientService {
  final Dio _dio;
  ClientService(this._dio);

  Future<Map<String, dynamic>> getClients({String? search, int limit = 20, int offset = 0}) async {
    final response = await _dio.get('/api/admin/clients', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'limit': limit,
      'offset': offset,
    });
    return response.data as Map<String, dynamic>;
  }
}
