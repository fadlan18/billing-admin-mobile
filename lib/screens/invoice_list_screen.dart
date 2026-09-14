import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../services/api_client.dart';
import '../services/invoice_service.dart';
import 'invoice_detail_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  late final InvoiceService _service;
  List<Invoice> _invoices = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'all';

  final List<Map<String, String>> _statusOptions = [
    {'value': 'all', 'label': 'Semua'},
    {'value': 'unpaid', 'label': 'Unpaid'},
    {'value': 'pending_confirmation', 'label': 'Pending'},
    {'value': 'paid', 'label': 'Paid'},
    {'value': 'cancelled', 'label': 'Cancelled'},
  ];

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
      final data = await _service.getInvoices(status: _selectedStatus);
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

  String _formatCurrency(num amount, String currency) {
    return '$currency ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.orange;
      case 'pending_confirmation':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Invoice')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _statusOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = _statusOptions[index];
                final selected = _selectedStatus == option['value'];
                return ChoiceChip(
                  label: Text(option['label']!),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedStatus = option['value']!);
                    _loadInvoices();
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _invoices.isEmpty
                        ? const Center(child: Text('Tidak ada invoice'))
                        : RefreshIndicator(
                            onRefresh: _loadInvoices,
                            child: ListView.builder(
                              itemCount: _invoices.length,
                              itemBuilder: (context, index) {
                                final inv = _invoices[index];
                                return ListTile(
                                  title: Text(inv.invoiceNumber),
                                  subtitle: Text(inv.clientName ?? inv.clientEmail ?? '-'),
                                  trailing: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(_formatCurrency(inv.total, inv.currency)),
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _statusColor(inv.status).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          inv.status,
                                          style: TextStyle(color: _statusColor(inv.status), fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    final changed = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: inv)),
                                    );
                                    if (changed == true) _loadInvoices();
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
