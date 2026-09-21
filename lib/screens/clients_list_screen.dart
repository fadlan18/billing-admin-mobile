import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../services/api_client.dart';
import '../services/client_service.dart';
import '../widgets/state_views.dart';
import 'client_detail_screen.dart';

const _primaryColor = Color(0xFF1E3A8A);

class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({super.key});

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  late final ClientService _service;
  List<Client> _clients = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _service = ClientService(context.read<ApiClient>().dio);
    _loadClients();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadClients();
    });
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _service.getClients(search: _searchController.text.trim(), limit: 50);
      final list = (data['clients'] as List<dynamic>)
          .map((e) => Client.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _clients = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat pelanggan';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: const Text('Pelanggan'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: _primaryColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Color(0xFF111827)),
              decoration: InputDecoration(
                hintText: 'Cari nama / email pelanggan...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: _primaryColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _loadClients();
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
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? ErrorStateView(message: _errorMessage!, onRetry: _loadClients)
                    : _clients.isEmpty
                        ? const EmptyStateView(icon: Icons.people_outline_rounded, message: 'Tidak ada pelanggan')
                        : RefreshIndicator(
                            onRefresh: _loadClients,
                            color: _primaryColor,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _clients.length,
                              itemBuilder: (context, index) {
                                final client = _clients[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    leading: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: _primaryColor,
                                      child: Text(
                                        client.name.isNotEmpty ? client.name.substring(0, 1).toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                    subtitle: Text(client.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('${client.invoiceCount} invoice', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 18),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => ClientDetailScreen(client: client)));
                                    },
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
