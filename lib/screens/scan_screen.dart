import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/api_client.dart';
import 'checkin_result_screen.dart';


class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController();

  bool _isProcessing = false;
  bool _loading = true;

  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await ApiClient.fetch(
        '/users/me',
        auth: true,
      );

      if (!mounted) return;

      setState(() {
        _user = result['data'];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load user: $e'),
        ),
      );
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    if (capture.barcodes.isEmpty) return;

    final code = capture.barcodes.first.rawValue;

    if (code == null || code.isEmpty) return;

    await _performCheckin(code);
  }

  Future<void> _performCheckin(String qrPayload) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    await _controller.stop();

    try {
      final result = await ApiClient.post(
        '/checkin',
        {
          'qr_payload': qrPayload,
        },
        auth: true,
      );

      final data = result['code'] == 'network_error'
        ? {'status': 'network_error', 'message': result['message']}
        : (result.containsKey('data') ? result['data'] as Map<String, dynamic> : result);

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CheckinResultScreen(
            result: data,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        await _controller.start();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final fullName = _user?['full_name'] ?? 'User';
    final firstName = fullName.toString().split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hello, $firstName. Scan the QR.',
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Camera error: ${error.errorCode}\n${error.errorDetails?.message ?? ""}'),
                ),
              );
            },
          ),

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}