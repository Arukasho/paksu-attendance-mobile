import 'package:flutter/material.dart';

import '../core/api_client.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String resetToken;

  const ResetPasswordScreen({
    super.key,
    required this.resetToken,
  });

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController =
      TextEditingController();

  bool _loading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String? _errorMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
    });

    final newPassword =
        _newPasswordController.text;
    final confirmPassword =
        _confirmPasswordController.text;

    if (newPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a new password.';
      });
      return;
    }

    if (newPassword.length < 8) {
      setState(() {
        _errorMessage =
            'Password must be at least 8 characters.';
      });
      return;
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        _errorMessage =
            'Please confirm your new password.';
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage =
            'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final result = await ApiClient.post(
        '/auth/reset-password',
        {
          'reset_token': widget.resetToken,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );

      if (!mounted) return;

      if (result.containsKey('data')) {
        setState(() {
          _loading = false;
        });

        await _showSuccessDialog();

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
          (route) => false,
        );
      } else {
        setState(() {
          _loading = false;
          _errorMessage =
              result['message'] ??
                  'Unable to reset your password.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage =
            'Unable to reset your password. '
            'Please try again.';
      });
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Password Reset Successful',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Your password has been changed successfully. '
            'You can now log in with your new password.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor:
                    const Color(0xFF2563EB),
              ),
              child: const Text(
                'Continue to Login',
              ),
            ),
          ],
        );
      },
    );
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
                        _buildResetPasswordCard(),
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

  Widget _buildResetPasswordCard() {
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
            color: Colors.black.withOpacity(0.04),
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
            const Text(
              'Create a new password',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Choose a strong password that you '
              'haven\'t used before.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'New Password',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 7),

            TextField(
              controller: _newPasswordController,
              enabled: !_loading,
              obscureText: _obscureNewPassword,
              textInputAction:
                  TextInputAction.next,
              decoration: _passwordDecoration(
                hint: 'Enter your new password',
                obscure: _obscureNewPassword,
                onToggle: () {
                  setState(() {
                    _obscureNewPassword =
                        !_obscureNewPassword;
                  });
                },
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Use at least 8 characters.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Confirm Password',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 7),

            TextField(
              controller:
                  _confirmPasswordController,
              enabled: !_loading,
              obscureText:
                  _obscureConfirmPassword,
              textInputAction:
                  TextInputAction.done,
              onSubmitted: (_) {
                if (!_loading) {
                  _submit();
                }
              },
              decoration: _passwordDecoration(
                hint: 'Confirm your new password',
                obscure:
                    _obscureConfirmPassword,
                onToggle: () {
                  setState(() {
                    _obscureConfirmPassword =
                        !_obscureConfirmPassword;
                  });
                },
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorMessage(),
            ],

            const SizedBox(height: 20),

            _buildResetButton(),
          ],
        ),
      ),
    );
  }

  InputDecoration _passwordDecoration({
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 13,
      ),
      prefixIcon: const Icon(
        Icons.lock_outline,
        size: 19,
        color: Color(0xFF94A3B8),
      ),
      suffixIcon: IconButton(
        onPressed: _loading ? null : onToggle,
        icon: Icon(
          obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          size: 19,
          color: const Color(0xFF94A3B8),
        ),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(
          color: Color(0xFF3B82F6),
          width: 1.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
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

  Widget _buildResetButton() {
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
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                    Colors.white,
                  ),
                ),
              )
            : const Text(
                'Reset Password',
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