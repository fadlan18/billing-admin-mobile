import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/push_service.dart';
import 'invoice_list_screen.dart';
import 'audit_log_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pushService = PushService(context.read<ApiClient>().dio);
      pushService.initAndRegister();
    });
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final auth = context.read<AuthProvider>();
    final available = await auth.isBiometricAvailable();
    final enabled = await auth.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    await context.read<AuthProvider>().setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value ? 'Fingerprint diaktifkan' : 'Fingerprint dinonaktifkan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().handleLogoutButtonPressed(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Selamat datang, ${user?.name ?? ''}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(user?.role ?? ''),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: const Text('Lihat Daftar Invoice'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InvoiceListScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Audit Log'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuditLogScreen()),
                );
              },
            ),
            if (_biometricAvailable) ...[
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Login dengan Fingerprint'),
                subtitle: const Text('Lewati password di kunjungan berikutnya'),
                value: _biometricEnabled,
                onChanged: _toggleBiometric,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
