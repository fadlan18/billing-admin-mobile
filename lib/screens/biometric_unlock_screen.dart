import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class BiometricUnlockScreen extends StatefulWidget {
  const BiometricUnlockScreen({super.key});

  @override
  State<BiometricUnlockScreen> createState() => _BiometricUnlockScreenState();
}

class _BiometricUnlockScreenState extends State<BiometricUnlockScreen> {
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryUnlock());
  }

  Future<void> _tryUnlock() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final success = await context.read<AuthProvider>().unlockWithBiometric();

    if (!mounted) return;
    setState(() {
      _isAuthenticating = false;
      if (!success) _errorMessage = 'Verifikasi gagal, coba lagi';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint, size: 96, color: Colors.indigo),
              const SizedBox(height: 24),
              const Text(
                'miTRANZ Billing Admin',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Gunakan fingerprint untuk masuk'),
              const SizedBox(height: 32),
              if (_isAuthenticating) const CircularProgressIndicator(),
              if (_errorMessage != null) ...[
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Coba Lagi'),
                  onPressed: _tryUnlock,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
