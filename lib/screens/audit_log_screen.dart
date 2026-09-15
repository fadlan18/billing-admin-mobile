import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/audit_log.dart';
import '../services/api_client.dart';
import '../services/audit_log_service.dart';

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
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'create':
        return Colors.green;
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
      appBar: AppBar(title: const Text('Audit Log')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _logs.isEmpty
                  ? const Center(child: Text('Belum ada aktivitas'))
                  : RefreshIndicator(
                      onRefresh: () => _loadLogs(),
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
                          itemCount: _logs.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _logs.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final log = _logs[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _actionColor(log.action).withValues(alpha: 0.15),
                                child: Icon(Icons.history, color: _actionColor(log.action), size: 18),
                              ),
                              title: Text('${log.action.toUpperCase()} - ${log.tableName}'),
                              subtitle: Text('Oleh: ${log.performedBy ?? '-'}\n${_formatDate(log.performedAt)}'),
                              isThreeLine: true,
                            );
                          },
                        ),
                      ),
                    ),
    );
  }
}
