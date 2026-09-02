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
  final MobileScannerController _controller =
      MobileScannerController();

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
          content: const Text(
            'Gagal memuat profil kamu.',
          ),
          action: SnackBarAction(
            label: 'Coba Lagi',
            onPressed: _load,
          ),
        ),
      );
    }
  }

  Future<void> _onDetect(
    BarcodeCapture capture,
  ) async {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final code =
        capture.barcodes.first.rawValue;

    if (code == null || code.isEmpty) return;

    await _performCheckin(code);
  }

  Future<void> _performCheckin(
    String qrPayload,
  ) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    await _controller.stop();

    try {
      final result = await ApiClient.post(
        '/checkin',
        {
          'qr_payload': qrPayload,
        },
        auth: true,
      );

      final Map<String, dynamic> data =
          result['code'] == 'network_error'
              ? {
                  'status': 'network_error',
                  'message': result['message'],
                }
              : result.containsKey('data')
                  ? result['data']
                      as Map<String, dynamic>
                  : result;

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CheckinResultScreen(
            result: data,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Check-in gagal. Silakan coba lagi.',
          ),
          action: SnackBarAction(
            label: 'Coba Lagi',
            onPressed: _load,
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      await _controller.start();
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
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final fullName =
        _user?['full_name'] ?? 'User';

    final firstName = fullName
        .toString()
        .trim()
        .split(' ')
        .first;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _buildScanner(),

            _buildTopBar(firstName),

            _buildScannerOverlay(),

            _buildBottomPanel(),

            if (_isProcessing)
              _buildProcessingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return Positioned.fill(
      child: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
        errorBuilder: (
          context,
          error,
        ) {
          return _buildCameraError(error);
        },
      ),
    );
  }

  Widget _buildTopBar(String firstName) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          18,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.65),
              Colors.black.withOpacity(0.0),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color:
                      Colors.white.withOpacity(0.15),
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/splash_icon.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PAKSU Attendance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hello, $firstName',
                    style: TextStyle(
                      color:
                          Colors.white.withOpacity(0.75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            if (!kIsWeb)
              _cameraButton(
                icon: Icons.flash_on_outlined,
                onPressed: () {
                  _controller.toggleTorch();
                },
              ),

            if (!kIsWeb)
            _cameraButton(
              icon: Icons.flip_camera_ios_outlined,
              onPressed: () async {
                try {
                  await _controller.switchCamera();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kamera depan tidak didukung oleh browser ini.')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.14),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: _isProcessing
            ? null
            : onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: Colors.white,
            size: 19,
          ),
        ),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ScannerOverlayPainter(),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          24,
          26,
          24,
          28,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.72),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius:
                    BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Scan Event QR Code',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'Posisikan QR code di dalam frame '
              'untuk check in.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 17,
                  color: Colors.white.withOpacity(0.75),
                ),
                const SizedBox(width: 7),
                Text(
                  'Scanning secara otomatis',
                  style: TextStyle(
                    color:
                        Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.72),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 32,
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFEFF6FF),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<
                              Color>(
                        Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Checking you in...',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Silakan tunggu sementara kami memverifikasi kehadiran kamu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraError(
    MobileScannerException error,
  ) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Kamera tidak tersedia',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              error.errorDetails?.message ??
                  'Tidak dapat mengakses kamera.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: () {
                _controller.start();
              },
              icon: const Icon(
                Icons.refresh,
                size: 17,
              ),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color:
                      Colors.white.withOpacity(0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.43;

    const frameSize = 250.0;
    const cornerLength = 30.0;
    const strokeWidth = 4.0;

    final left =
        centerX - frameSize / 2;
    final top =
        centerY - frameSize / 2;
    final right =
        centerX + frameSize / 2;
    final bottom =
        centerY + frameSize / 2;

    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final frameRect = Rect.fromLTRB(
      left,
      top,
      right,
      bottom,
    );

    final fullPath = Path()
      ..addRect(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      );

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          frameRect,
          const Radius.circular(18),
        ),
      );

    final combinedPath = Path.combine(
      PathOperation.difference,
      fullPath,
      cutoutPath,
    );

    canvas.drawPath(
      combinedPath,
      overlayPaint,
    );

    final framePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Top-left
    path.moveTo(left, top + cornerLength);
    path.lineTo(left, top);
    path.lineTo(left + cornerLength, top);

    // Top-right
    path.moveTo(right - cornerLength, top);
    path.lineTo(right, top);
    path.lineTo(right, top + cornerLength);

    // Bottom-right
    path.moveTo(right, bottom - cornerLength);
    path.lineTo(right, bottom);
    path.lineTo(right - cornerLength, bottom);

    // Bottom-left
    path.moveTo(left + cornerLength, bottom);
    path.lineTo(left, bottom);
    path.lineTo(left, bottom - cornerLength);

    canvas.drawPath(
      path,
      framePaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}