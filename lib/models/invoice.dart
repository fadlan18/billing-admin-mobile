class Invoice {
  final String id;
  final String invoiceNumber;
  final String status;
  final String currency;
  final num total;
  final String productType;
  final DateTime createdAt;
  final String? clientName;
  final String? clientEmail;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.currency,
    required this.total,
    required this.productType,
    required this.createdAt,
    this.clientName,
    this.clientEmail,
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
      clientName: client?['name'] as String?,
      clientEmail: client?['email'] as String?,
    );
  }
}
