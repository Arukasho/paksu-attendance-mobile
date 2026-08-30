import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/secure_storage.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final refreshToken = await SecureStorage.getRefreshToken();

    if (refreshToken == null) {
      _goTo(const LoginScreen());
      return;
    }

    final result = await ApiClient.post('/auth/refresh', {'refresh_token': refreshToken});

    if (result['code'] == 'network_error') {
      // Can't verify right now — let them in using what's cached locally.
      // Any real API call they make once inside will surface the same
      // network_error message if they're still offline.
      _goTo(const MainShell());
      return;
    }

    if (result.containsKey('data')) {
      final data = result['data'];
      await SecureStorage.saveTokens(data['access_token'], data['refresh_token']);
      _goTo(const MainShell());
    } else {
      await SecureStorage.clearTokens();
      _goTo(const LoginScreen());
    }

    if (result.containsKey('data')) {
      final data = result['data'];
      await SecureStorage.saveTokens(data['access_token'], data['refresh_token']);
      _goTo(const MainShell());
    } else {
      await SecureStorage.clearTokens();
      _goTo(const LoginScreen());
    }
  }

  void _goTo(Widget screen) {
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}