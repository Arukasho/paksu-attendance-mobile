import 'package:flutter/material.dart';
import '../core/api_client.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String resetToken;
  const ResetPasswordScreen({super.key, required this.resetToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    setState(() { _loading = true; _errorMessage = null; });

    final result = await ApiClient.post('/auth/reset-password', {
      'reset_token': widget.resetToken,
      'new_password': _newPasswordController.text,
      'confirm_password': _confirmPasswordController.text,
    });

    setState(() => _loading = false);

    if (result.containsKey('data')) {
        if (mounted) {
            await showDialog(
            context: context,
            builder: (_) => AlertDialog(
                title: const Text('Password Reset Successful'),
                content: const Text('You can now log in with your new password.'),
                actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
                ],
            ),
            );
            if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
            );
            }
        }
    } else {
      setState(() => _errorMessage = result['message'] ?? 'Something went wrong.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _newPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
            const SizedBox(height: 12),
            TextField(controller: _confirmPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
            const SizedBox(height: 16),
            if (_errorMessage != null) Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _submit, child: const Text('Reset Password')),
          ],
        ),
      ),
    );
  }
}