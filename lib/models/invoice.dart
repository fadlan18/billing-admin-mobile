class Invoice {
  final String id;
  final String invoiceNumber;
  final String status;
  final String currency;
  final num total;
  final String productType;
  final DateTime createdAt;
  final String? notes;
  final String? clientName;
  final String? clientEmail;
  final List<dynamic> statusHistory;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.currency,
    required this.total,
    required this.productType,
    required this.createdAt,
    this.notes,
    this.clientName,
    this.clientEmail,
    this.statusHistory = const [],
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    return Invoice(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String,
      status: json['status'] as String,
      currency: json['currency'] as String? ?? 'IDR',
      total: json['total'] as num,
      productType: json['product_type'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      notes: json['notes'] as String?,
      clientName: client?['name'] as String?,
      clientEmail: client?['email'] as String?,
      statusHistory: json['status_history'] as List<dynamic>? ?? [],
    );
  }
}
