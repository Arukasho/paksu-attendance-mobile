import 'package:flutter/material.dart';

import '../core/api_client.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final List<Widget> _screens = const [
    ScanScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkEmailBackfill();
  }

  Future<void> _checkEmailBackfill() async {
    try {
      final result = await ApiClient.fetch(
        '/users/me',
        auth: true,
      );

      final user = result['data'];

      if (!mounted || user == null) return;

      final email = user['email']?.toString().trim() ?? '';

      if (email.isEmpty) {
        _showAddEmailDialog();
      }
    } catch (_) {
      // Silently ignore the check.
      // The user can still use the app normally.
    }
  }

  void _showAddEmailDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _AddEmailDialog(
          controller: controller,
        );
      },
    ).then((_) {
      controller.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: IndexedStack(
        index: _index,
        children: _screens,
      ),

      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget _buildNavigationBar() {
    return NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (index) {
        if (_index == index) return;

        setState(() {
          _index = index;
        });
      },
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      height: 70,
      indicatorColor: const Color(0xFFEFF6FF),
      labelBehavior:
          NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(
            Icons.qr_code_scanner_outlined,
          ),
          selectedIcon: Icon(
            Icons.qr_code_scanner,
          ),
          label: 'Scan',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.history_outlined,
          ),
          selectedIcon: Icon(
            Icons.history,
          ),
          label: 'Riwayat',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.person_outline,
          ),
          selectedIcon: Icon(
            Icons.person,
          ),
          label: 'Profil',
        ),
      ],
    );
  }
}

class _AddEmailDialog extends StatefulWidget {
  final TextEditingController controller;

  const _AddEmailDialog({
    required this.controller,
  });

  @override
  State<_AddEmailDialog> createState() =>
      _AddEmailDialogState();
}

class _AddEmailDialogState
    extends State<_AddEmailDialog> {
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final email =
        widget.controller.text.trim();

    if (email.isEmpty) {
      setState(() {
        _error = 'Please enter your email address.';
      });
      return;
    }

    if (!email.contains('@')) {
      setState(() {
        _error =
            'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final result = await ApiClient.patch(
        '/users/me',
        {
          'email': email,
        },
        auth: true,
      );

      if (!mounted) return;

      if (result.containsKey('data')) {
        Navigator.of(context).pop();
        return;
      }

      setState(() {
        _saving = false;
        _error =
            result['message'] ??
                'Failed to save email.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _error =
            'Unable to save your email. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),

            const SizedBox(height: 18),

            const Text(
              'Add Your Email',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'An email address is required for password recovery and account security.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: widget.controller,
              keyboardType:
                  TextInputType.emailAddress,
              textInputAction:
                  TextInputAction.done,
              onSubmitted: (_) {
                if (!_saving) {
                  _save();
                }
              },
              decoration: InputDecoration(
                labelText: 'Email address',
                hintText: 'you@example.com',
                prefixIcon: const Icon(
                  Icons.email_outlined,
                ),
                errorText: _error,
                filled: true,
                fillColor:
                    const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed:
                    _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFFBFDBFE),
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(9),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Email',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.email_outlined,
        size: 30,
        color: Color(0xFF2563EB),
      ),
    );
  }
}