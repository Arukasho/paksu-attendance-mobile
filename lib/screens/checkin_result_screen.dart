import 'package:flutter/material.dart';
import '../core/datetime_utils.dart';

class CheckinResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const CheckinResultScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final status =
        result['status'] as String? ?? 'error';

    final event =
        result['event'] as Map<String, dynamic>?;

    final config = _configFor(status);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 32,
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
                  const SizedBox(height: 50),

                  _buildResultCard(
                    context,
                    config,
                    event,
                  ),

                  const SizedBox(height: 20),

                  _buildBackButton(context),

                  const SizedBox(height: 12),

                  const Text(
                    'Paksu Attendance Management',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    _ResultConfig config,
    Map<String, dynamic>? event,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        24,
        28,
        24,
        26,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatusIcon(config),

          const SizedBox(height: 20),

          Text(
            config.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            config.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.5,
            ),
          ),

          if (event != null) ...[
            const SizedBox(height: 24),
            _buildEventInfo(event),
          ],

          if (_hasAdditionalInfo(config)) ...[
            const SizedBox(height: 18),
            _buildAdditionalInfo(config),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(
    _ResultConfig config,
  ) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: config.backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        config.icon,
        size: 42,
        color: config.color,
      ),
    );
  }

  Widget _buildEventInfo(
    Map<String, dynamic> event,
  ) {
    final eventName =
        event['name']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.event_outlined,
              size: 20,
              color: Color(0xFF475569),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'EVENT',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  eventName.isEmpty
                      ? 'Unknown event'
                      : eventName,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasAdditionalInfo(
    _ResultConfig config,
  ) {
    return config.detail != null &&
        config.detail!.isNotEmpty;
  }

  Widget _buildAdditionalInfo(
    _ResultConfig config,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 17,
            color: config.color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              config.detail!,
              style: TextStyle(
                color: config.color,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(
    BuildContext context,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: const Icon(
          Icons.qr_code_scanner,
          size: 18,
        ),
        label: const Text(
          'Back to Scanner',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(9),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  _ResultConfig _configFor(
    String status,
  ) {
    switch (status) {
      case 'success':
        return _ResultConfig(
          icon: Icons.check_circle,
          color: const Color(0xFF16A34A),
          backgroundColor:
              const Color(0xFFF0FDF4),
          title: 'Attendance Successful!',
          subtitle:
              'You have been successfully checked in.',
        );

      case 'already_checked_in':
        return _ResultConfig(
          icon: Icons.check_circle_outline,
          color: const Color(0xFF2563EB),
          backgroundColor:
              const Color(0xFFEFF6FF),
          title: "You're Already Checked In",
          subtitle:
              'You have already checked in for this event.',
        );

      case 'too_early':
        final opensAt =
            result['opens_at'] != null
                ? formatWib(result['opens_at'])
                : '';

        return _ResultConfig(
          icon: Icons.schedule_outlined,
          color: const Color(0xFFD97706),
          backgroundColor:
              const Color(0xFFFFFBEB),
          title: 'Check-in Not Open Yet',
          subtitle:
              'Please wait until attendance opens.',
          detail: opensAt.isNotEmpty
              ? 'Check-in opens at $opensAt.'
              : null,
        );

      case 'too_late':
        final closedAt =
            result['closed_at'] != null
                ? formatWib(result['closed_at'])
                : '';

        return _ResultConfig(
          icon: Icons.event_busy_outlined,
          color: const Color(0xFFDC2626),
          backgroundColor:
              const Color(0xFFFEF2F2),
          title: 'Check-in Closed',
          subtitle:
              'The attendance period for this event has ended.',
          detail: closedAt.isNotEmpty
              ? 'Check-in closed at $closedAt.'
              : null,
        );

      case 'no_active_event':
        return _ResultConfig(
          icon: Icons.event_available_outlined,
          color: const Color(0xFF64748B),
          backgroundColor:
              const Color(0xFFF1F5F9),
          title: 'No Active Event',
          subtitle:
              'There is no event available for check-in right now.',
        );

      case 'network_error':
        return _ResultConfig(
          icon: Icons.wifi_off_outlined,
          color: const Color(0xFF64748B),
          backgroundColor:
              const Color(0xFFF1F5F9),
          title: 'No Internet Connection',
          subtitle:
              'We could not connect to the server.',
          detail: result['message'] ??
              'Please check your connection and try again.',
        );

      default:
        return _ResultConfig(
          icon: Icons.error_outline,
          color: const Color(0xFFDC2626),
          backgroundColor:
              const Color(0xFFFEF2F2),
          title: 'Something Went Wrong',
          subtitle:
              'We could not complete your check-in.',
          detail: result['message'] ??
              'Please try scanning the QR code again.',
        );
    }
  }
}

class _ResultConfig {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final String? detail;

  const _ResultConfig({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    this.detail,
  });
}