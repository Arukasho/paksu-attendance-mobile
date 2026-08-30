import 'package:flutter/material.dart';
import 'scan_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import '../core/api_client.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [ScanScreen(), HistoryScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
  @override
  void initState() {
    super.initState();
    _checkEmailBackfill();
  }

  Future<void> _checkEmailBackfill() async {
    final result = await ApiClient.fetch('/users/me', auth: true);
    final user = result['data'];
    if (user != null && (user['email'] == null || user['email'] == '')) {
      if (mounted) _showAddEmailDialog();
    }
  }

  void _showAddEmailDialog() {
    final controller = TextEditingController();
    String? error;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Your Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('An email is required for password recovery.'),
              const SizedBox(height: 12),
              TextField(controller: controller, decoration: const InputDecoration(labelText: 'Email')),
              if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final result = await ApiClient.patch('/users/me', {'email': controller.text}, auth: true);
                if (result.containsKey('data')) {
                  if (mounted) Navigator.of(context).pop();
                } else {
                  setDialogState(() => error = result['message'] ?? 'Failed to save email.');
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}