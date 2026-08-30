import 'package:flutter/material.dart';
import '../core/api_client.dart';
import 'reset_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String identifier;
  const VerifyOtpScreen({super.key, required this.identifier});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    setState(() { _loading = true; _errorMessage = null; });

    final result = await ApiClient.post('/auth/verify-otp', {
      'identifier': widget.identifier,
      'otp': _otpController.text,
    });

    setState(() => _loading = false);

    if (result.containsKey('data')) {
      final resetToken = result['data']['reset_token'];
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(resetToken: resetToken),
        ));
      }
    } else {
      setState(() => _errorMessage = result['message'] ?? 'Invalid OTP.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('We sent a code to ${widget.identifier}'),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '6-digit code'),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null) Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _submit, child: const Text('Verify')),
          ],
        ),
      ),
    );
  }
}