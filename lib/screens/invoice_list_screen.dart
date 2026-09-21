import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../services/api_client.dart';
import '../services/invoice_service.dart';
import '../widgets/state_views.dart';
import 'invoice_detail_screen.dart';

const _primaryColor = Color(0xFF1E3A8A);
const _textDark = Color(0xFF111827);
const _textMedium = Color(0xFF4B5563);
const _textLight = Color(0xFF9CA3AF);

class InvoiceListScreen extends StatefulWidget {
  final String initialStatus;
  final bool autoFocusSearch;

  const InvoiceListScreen({
    super.key,
    this.initialStatus = 'all',
    this.autoFocusSearch = false,
  });

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  late final InvoiceService _service;
  List<Invoice> _invoices = [];
  bool _isLoading = true;
  String? _errorMessage;
  late String _selectedStatus;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;

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
    _selectedStatus = widget.initialStatus;
    _service = InvoiceService(context.read<ApiClient>().dio);
    _loadInvoices();
    if (widget.autoFocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadInvoices();
    });
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _service.getInvoices(
        status: _selectedStatus,
        search: _searchController.text.trim(),
      );
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

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
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

  IconData _productIcon(String productType) {
    switch (productType) {
      case 'ppob':
        return Icons.bolt_rounded;
      case 'service':
        return Icons.miscellaneous_services_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: const Text('Daftar Invoice'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: _primaryColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: _textDark),
                  decoration: InputDecoration(
                    hintText: 'Cari nomor invoice / nama / email...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: _primaryColor),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _loadInvoices();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusOptions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                        backgroundColor: Colors.white,
                        selectedColor: Colors.white,
                        labelStyle: TextStyle(
                          color: _primaryColor,
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                        ),
                        side: BorderSide.none,
                        showCheckmark: false,
                        elevation: selected ? 2 : 0,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? ErrorStateView(message: _errorMessage!, onRetry: _loadInvoices)
                    : _invoices.isEmpty
                        ? const EmptyStateView(message: 'Tidak ada invoice')
                        : RefreshIndicator(
                            onRefresh: _loadInvoices,
                            color: _primaryColor,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                              itemCount: _invoices.length,
                              itemBuilder: (context, index) {
                                final inv = _invoices[index];
                                final statusColor = _statusColor(inv.status);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () async {
                                        final changed = await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: inv)),
                                        );
                                        if (changed == true) _loadInvoices();
                                      },
                                      child: IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Container(
                                              width: 5,
                                              decoration: BoxDecoration(
                                                color: statusColor,
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(14),
                                                  bottomLeft: Radius.circular(14),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 44,
                                                      height: 44,
                                                      decoration: BoxDecoration(
                                                        color: _primaryColor.withValues(alpha: 0.08),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Icon(_productIcon(inv.productType), color: _primaryColor, size: 22),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            inv.invoiceNumber,
                                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: _textDark),
                                                          ),
                                                          const SizedBox(height: 3),
                                                          Text(
                                                            inv.clientName ?? inv.clientEmail ?? '-',
                                                            style: const TextStyle(color: _textMedium, fontSize: 13, fontWeight: FontWeight.w500),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            _formatDate(inv.createdAt),
                                                            style: const TextStyle(color: _textLight, fontSize: 11.5),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          _formatCurrency(inv.total, inv.currency),
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textDark),
                                                        ),
                                                        const SizedBox(height: 7),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                          decoration: BoxDecoration(
                                                            color: statusColor,
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          child: Text(
                                                            _statusLabel(inv.status),
                                                            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
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
