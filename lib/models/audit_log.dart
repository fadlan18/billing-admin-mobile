class AuditLog {
  final String id;
  final String tableName;
  final String recordId;
  final String action;
  final String? performedBy;
  final DateTime performedAt;
  final String? notes;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;

  AuditLog({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.action,
    this.performedBy,
    required this.performedAt,
    this.notes,
    this.oldData,
    this.newData,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      tableName: json['table_name'] as String,
      recordId: json['record_id'] as String,
      action: json['action'] as String,
      performedBy: json['performed_by'] as String?,
      performedAt: DateTime.parse(json['performed_at'] as String),
      notes: json['notes'] as String?,
      oldData: json['old_data'] as Map<String, dynamic>?,
      newData: json['new_data'] as Map<String, dynamic>?,
    );
  }
}
