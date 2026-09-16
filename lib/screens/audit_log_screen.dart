import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/audit_log.dart';
import '../services/api_client.dart';
import '../services/audit_log_service.dart';
import '../widgets/state_views.dart';

const _primaryColor = Color(0xFF1E3A8A);

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  late final AuditLogService _service;
  final List<AuditLog> _logs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _offset = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _service = AuditLogService(context.read<ApiClient>().dio);
    _loadLogs();
  }

  Future<void> _loadLogs({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _offset = 0;
      });
    }

    try {
      final data = await _service.getLogs(offset: loadMore ? _offset : 0, limit: _pageSize);
      final newLogs = (data['logs'] as List<dynamic>)
          .map((e) => AuditLog.fromJson(e as Map<String, dynamic>))
          .toList();
      final pagination = data['pagination'] as Map<String, dynamic>;

      setState(() {
        if (loadMore) {
          _logs.addAll(newLogs);
        } else {
          _logs
            ..clear()
            ..addAll(newLogs);
        }
        _offset += newLogs.length;
        _hasMore = pagination['has_more'] as bool? ?? false;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat audit log';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'update':
        return const Color(0xFF2563EB);
      case 'delete':
        return const Color(0xFFDC2626);
      case 'create':
        return const Color(0xFF059669);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: const Text('Audit Log'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? ErrorStateView(message: _errorMessage!, onRetry: () => _loadLogs())
              : _logs.isEmpty
                  ? const EmptyStateView(icon: Icons.history_rounded, message: 'Belum ada aktivitas')
                  : RefreshIndicator(
                      onRefresh: () => _loadLogs(),
                      color: _primaryColor,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (scrollInfo) {
                          if (!_isLoadingMore &&
                              _hasMore &&
                              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                            _loadLogs(loadMore: true);
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _logs.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _logs.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final log = _logs[index];
                            final color = _actionColor(log.action);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.history_rounded, color: color, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${log.action.toUpperCase()} - ${log.tableName}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Oleh: ${log.performedBy ?? '-'}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                        Text(
                                          _formatDate(log.performedAt),
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
    );
  }
}
