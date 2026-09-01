import 'package:flutter/material.dart';

import '../core/api_client.dart';
import 'reset_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String identifier;

  const VerifyOtpScreen({
    super.key,
    required this.identifier,
  });

  @override
  State<VerifyOtpScreen> createState() =>
      _VerifyOtpScreenState();
}

class _VerifyOtpScreenState
    extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
    });

    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      setState(() {
        _errorMessage =
            'Please enter the verification code.';
      });
      return;
    }

    if (otp.length != 6) {
      setState(() {
        _errorMessage =
            'Please enter the 6-digit verification code.';
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final result = await ApiClient.post(
        '/auth/verify-otp',
        {
          'identifier': widget.identifier,
          'otp': otp,
        },
      );

      if (!mounted) return;

      if (result.containsKey('data')) {
        final resetToken =
            result['data']['reset_token'];

        setState(() {
          _loading = false;
        });

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              resetToken: resetToken,
            ),
          ),
        );
      } else {
        setState(() {
          _loading = false;
          _errorMessage =
              result['message'] ??
                  'Invalid verification code.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage =
            'Unable to verify the code. '
            'Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.maxHeight - 64,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 420,
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        _buildBrandHeader(),
                        const SizedBox(height: 28),
                        _buildOtpCard(),
                        const SizedBox(height: 20),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        // Brand icon
        Align(
          alignment: Alignment.center,
          child: Image.asset(
            'assets/splash_icon.png',
            width: 108,
            height: 108,
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(height: 14),

        const Text(
          'PAKSU Attendance App',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildIcon(),

            const SizedBox(height: 20),

            const Text(
              'Verify your account',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Enter the 6-digit verification code '
              'we sent to:',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              widget.identifier,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Verification Code',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _otpController,
              enabled: !_loading,
              keyboardType:
                  TextInputType.number,
              textInputAction:
                  TextInputAction.done,
              maxLength: 6,
              autofocus: true,
              textAlign: TextAlign.center,
              onSubmitted: (_) {
                if (!_loading) {
                  _submit();
                }
              },
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 7,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                hintStyle: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 7,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(9),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(9),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(9),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 1.5,
                  ),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorMessage(),
            ],

            const SizedBox(height: 20),

            _buildVerifyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.mark_email_read_outlined,
        color: Color(0xFF2563EB),
        size: 24,
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: 17,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              const Color(0xFF93C5FD),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(9),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 19,
                height: 19,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                    Colors.white,
                  ),
                ),
              )
            : const Text(
                'Verify Code',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Text(
      '©2026 PAKSU Attendance App. All rights reserved.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 11,
      ),
    );
  }
}