import 'package:dio/dio.dart';

class InvoiceService {
  final Dio _dio;
  InvoiceService(this._dio);

  Future<Map<String, dynamic>> getInvoices({String? status, int limit = 20, int offset = 0}) async {
    final response = await _dio.get('/api/admin/invoices', queryParameters: {
      if (status != null && status != 'all') 'status': status,
      'limit': limit,
      'offset': offset,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateStatus(String id, String status, {String? reason}) async {
    final response = await _dio.patch('/api/admin/invoices/$id', data: {
      'status': status,
      if (reason != null) 'reason': reason,
    });
    return response.data['invoice'] as Map<String, dynamic>;
  }
}
