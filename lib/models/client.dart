class Client {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final bool isActive;
  final DateTime createdAt;
  final String? appName;
  final int invoiceCount;
  final num invoiceTotal;
  final int activeServiceCount;

  Client({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.isActive,
    required this.createdAt,
    this.appName,
    this.invoiceCount = 0,
    this.invoiceTotal = 0,
    this.activeServiceCount = 0,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    final app = json['app'] as Map<String, dynamic>?;
    final invoicesAgg = json['invoices_aggregate']?['aggregate'] as Map<String, dynamic>?;
    final servicesAgg = json['services_aggregate']?['aggregate'] as Map<String, dynamic>?;
    return Client(
      id: json['id'] as String,
      name: json['name'] as String? ?? '-',
      email: json['email'] as String? ?? '-',
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      appName: app?['name'] as String?,
      invoiceCount: invoicesAgg?['count'] as int? ?? 0,
      invoiceTotal: (invoicesAgg?['sum']?['total'] as num?) ?? 0,
      activeServiceCount: servicesAgg?['count'] as int? ?? 0,
    );
  }
}
