import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../services/api_client.dart';
import '../services/invoice_service.dart';

const _primaryColor = Color(0xFF1E3A8A);

class InvoiceDetailScreen extends StatefulWidget {
  final Invoice invoice;
  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late final InvoiceService _service;
  bool _isSubmitting = false;

  static const Map<String, List<String>> _transitions = {
    'unpaid': ['paid', 'cancelled', 'pending_confirmation'],
    'pending_confirmation': ['paid', 'unpaid', 'cancelled'],
    'paid': [],
    'cancelled': ['unpaid'],
  };

  static const Map<String, String> _statusLabel = {
    'paid': 'Tandai Lunas',
    'cancelled': 'Batalkan',
    'unpaid': 'Tandai Belum Bayar',
    'pending_confirmation': 'Tunda Konfirmasi',
  };

  @override
  void initState() {
    super.initState();
    _service = InvoiceService(context.read<ApiClient>().dio);
  }

  Future<void> _updateStatus(String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi'),
        content: Text('Ubah status invoice ${widget.invoice.invoiceNumber} menjadi "$newStatus"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, lanjutkan')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      await _service.updateStatus(widget.invoice.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status berhasil diubah')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ubah status: $e')),
      );
    }
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

  String _statusText(String status) {
    switch (status) {
      case 'paid':
        return 'Lunas';
      case 'unpaid':
        return 'Belum Bayar';
      case 'pending_confirmation':
        return 'Menunggu Konfirmasi';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String _formatCurrency(num amount, String currency) {
    return '$currency ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827))),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final allowedTransitions = _transitions[inv.status] ?? [];
    final statusColor = _statusColor(inv.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: Text(inv.invoiceNumber),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: statusColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_statusText(inv.status), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  _formatCurrency(inv.total, inv.currency),
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          _sectionCard(
            title: 'Informasi Invoice',
            child: Column(
              children: [
                _infoRow('Produk', inv.productType),
                _infoRow('Client', inv.clientName ?? '-'),
                _infoRow('Email', inv.clientEmail ?? '-'),
                _infoRow('Dibuat', inv.createdAt.toString().split('.').first),
                if (inv.notes != null && inv.notes!.isNotEmpty) _infoRow('Catatan', inv.notes!),
              ],
            ),
          ),
          if (inv.items.isNotEmpty)
            _sectionCard(
              title: 'Rincian Item',
              child: Column(
                children: inv.items.map((item) {
                  final m = item as Map<String, dynamic>;
                  final qty = m['quantity'] as num? ?? 1;
                  final unitPrice = m['unit_price'] as num? ?? 0;
                  final itemTotal = m['total'] as num? ?? (qty * unitPrice);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m['description']?.toString() ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              Text('$qty x ${_formatCurrency(unitPrice, inv.currency)}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        Text(_formatCurrency(itemTotal, inv.currency), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          if (inv.payments.isNotEmpty)
            _sectionCard(
              title: 'Riwayat Pembayaran',
              child: Column(
                children: inv.payments.map((p) {
                  final m = p as Map<String, dynamic>;
                  final amount = m['amount'] as num? ?? 0;
                  final method = m['method']?.toString() ?? '-';
                  final pStatus = m['status']?.toString() ?? '-';
                  final paidAt = m['paid_at']?.toString();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(Icons.payments_rounded, size: 18, color: _primaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(method, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              Text(
                                paidAt != null ? paidAt.split('T').first : pStatus,
                                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                        Text(_formatCurrency(amount, inv.currency), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          if (allowedTransitions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Invoice ini sudah final, tidak ada aksi tersedia',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ...allowedTransitions.map((status) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : () => _updateStatus(status),
                      style: FilledButton.styleFrom(
                        backgroundColor: status == 'cancelled' ? const Color(0xFFDC2626) : _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_statusLabel[status] ?? status),
                    ),
                  ),
                )),
          if (inv.statusHistory.isNotEmpty)
            _sectionCard(
              title: 'Riwayat Status',
              child: Column(
                children: inv.statusHistory.map((h) {
                  final m = h as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.history_rounded, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${m['status_from'] ?? '-'}  ${m['status_to']}',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                        Text(
                          m['changed_at']?.toString().split('T').first ?? '',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
