import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../models/invoice.dart';
import '../services/api_client.dart';
import '../services/invoice_service.dart';
import '../widgets/state_views.dart';
import 'invoice_detail_screen.dart';

const _primaryColor = Color(0xFF1E3A8A);

class ClientDetailScreen extends StatefulWidget {
  final Client client;
  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  late final InvoiceService _service;
  List<Invoice> _invoices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = InvoiceService(context.read<ApiClient>().dio);
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _service.getInvoices(search: widget.client.email, limit: 100);
      final list = (data['invoices'] as List<dynamic>)
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _invoices = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat invoice';
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(num amount) {
    return 'IDR ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return const Color(0xFF059669);
      case 'unpaid':
        return const Color(0xFFD97706);
      case 'pending_confirmation':
        return const Color(0xFF2563EB);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Lunas';
      case 'unpaid':
        return 'Belum Bayar';
      case 'pending_confirmation':
        return 'Menunggu';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: Text(client.name),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadInvoices,
        color: _primaryColor,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: _primaryColor,
                        child: Text(
                          client.name.isNotEmpty ? client.name.substring(0, 1).toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 3),
                            Text(client.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                            if (client.phone != null) ...[
                              const SizedBox(height: 2),
                              Text(client.phone!, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MiniStat(label: 'Total Invoice', value: '${client.invoiceCount}'),
                      _MiniStat(label: 'Total Transaksi', value: _formatCurrency(client.invoiceTotal)),
                      _MiniStat(label: 'Layanan Aktif', value: '${client.activeServiceCount}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Riwayat Invoice',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              ErrorStateView(message: _errorMessage!, onRetry: _loadInvoices)
            else if (_invoices.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: EmptyStateView(message: 'Belum ada invoice'),
              )
            else
              ..._invoices.map((inv) {
                final statusColor = _statusColor(inv.status);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: ListTile(
                    title: Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: Text(_formatCurrency(inv.total), style: const TextStyle(fontSize: 12.5)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        _statusLabel(inv.status),
                        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: inv)));
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _primaryColor)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500), textAlign: TextAlign.center),
      ],
    );
  }
}
