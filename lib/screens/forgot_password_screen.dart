import 'package:flutter/material.dart';
import '../core/api_client.dart';
import 'verify_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    setState(() { _loading = true; _errorMessage = null; });

    final result = await ApiClient.post('/auth/forgot-password', {
      'identifier': _identifierController.text,
    });

    setState(() => _loading = false);

    if (result.containsKey('data')) {
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => VerifyOtpScreen(identifier: _identifierController.text),
        ));
      }
    } else {
      setState(() => _errorMessage = result['message'] ?? 'Something went wrong.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _identifierController,
              decoration: const InputDecoration(labelText: 'Your Email'),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null) Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _submit, child: const Text('Send OTP')),
          ],
        ),
      ),
    );
  }
}