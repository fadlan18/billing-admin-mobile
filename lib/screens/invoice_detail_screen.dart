import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../services/api_client.dart';
import '../services/invoice_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final allowedTransitions = _transitions[inv.status] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(inv.invoiceNumber)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoRow('Status', inv.status.toUpperCase()),
          _buildInfoRow('Total', '${inv.currency} ${inv.total}'),
          _buildInfoRow('Produk', inv.productType),
          _buildInfoRow('Client', inv.clientName ?? '-'),
          _buildInfoRow('Email', inv.clientEmail ?? '-'),
          _buildInfoRow('Dibuat', inv.createdAt.toString()),
          if (inv.notes != null && inv.notes!.isNotEmpty)
            _buildInfoRow('Catatan', inv.notes!),
          const SizedBox(height: 24),
          if (allowedTransitions.isEmpty)
            const Center(
              child: Text(
                'Invoice ini sudah final, tidak ada aksi tersedia',
                style: TextStyle(color: Colors.grey),
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
                        backgroundColor: status == 'cancelled' ? Colors.red : null,
                      ),
                      child: Text(_statusLabel[status] ?? status),
                    ),
                  ),
                )),
          if (inv.statusHistory.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Riwayat Status', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...inv.statusHistory.map((h) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.history, size: 18),
                  title: Text('${h['status_from'] ?? '-'}  ${h['status_to']}'),
                  subtitle: Text(h['changed_at']?.toString() ?? ''),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
