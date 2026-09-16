import 'package:dio/dio.dart';

class InvoiceService {
  final Dio _dio;
  InvoiceService(this._dio);

  Future<Map<String, dynamic>> getInvoices({String? status, String? search, int limit = 20, int offset = 0}) async {
    final response = await _dio.get('/api/admin/invoices', queryParameters: {
      if (status != null && status != 'all') 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
      'limit': limit,
      'offset': offset,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Cari satu invoice by ID. Backend belum punya endpoint GET detail terpisah,
  /// jadi ambil dari list (limit besar) dan filter di sisi client.
  Future<Map<String, dynamic>?> getInvoiceById(String id) async {
    final response = await _dio.get('/api/admin/invoices', queryParameters: {
      'limit': 100,
    });
    final invoices = response.data['invoices'] as List<dynamic>;
    for (final inv in invoices) {
      if (inv['id'] == id) return inv as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>> updateStatus(String id, String status, {String? reason}) async {
    final response = await _dio.patch('/api/admin/invoices/$id', data: {
      'status': status,
      if (reason != null) 'reason': reason,
    });
    return response.data['invoice'] as Map<String, dynamic>;
  }
}
