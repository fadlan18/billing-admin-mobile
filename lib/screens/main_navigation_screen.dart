import 'package:flutter/material.dart';
import 'home_tab_screen.dart';
import 'account_screen.dart';
import 'clients_list_screen.dart';

const _primaryColor = Color(0xFF1E3A8A);

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeTabScreen(),
    AccountScreen(),
  ];

  void _openClients() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientsListScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      floatingActionButton: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B5FCC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: _primaryColor.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: IconButton(
          onPressed: _openClients,
          icon: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Beranda',
              isActive: _currentIndex == 0,
              onTap: () => setState(() => _currentIndex = 0),
            ),
            const SizedBox(width: 48),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Akun',
              isActive: _currentIndex == 1,
              onTap: () => setState(() => _currentIndex = 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _primaryColor : Colors.grey.shade500;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}
