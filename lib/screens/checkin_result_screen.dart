import 'package:flutter/material.dart';
import '../core/datetime_utils.dart';

class CheckinResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const CheckinResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final status = result['status'] as String? ?? 'error';
    final event = result['event'] as Map<String, dynamic>?;

    final config = _configFor(status);

    return Scaffold(
      body: SafeArea(
        child: Center(
            child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                Icon(config.icon, size: 72, color: config.color),
                const SizedBox(height: 16),

                Text(
                    config.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                ),

                const SizedBox(height: 8),

                Text(
                    config.subtitle,
                    textAlign: TextAlign.center,
                ),

                if (event != null) ...[
                    const SizedBox(height: 24),
                    Text(
                    'Event',
                    style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                    event['name'] ?? '',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                    ),
                ],

                const SizedBox(height: 32),

                ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Scan'),
                ),
                ],
            ),
            ),
        ),
        ),
    );
  }

  _ResultConfig _configFor(String status) {
    switch (status) {
      case 'success':
        return _ResultConfig(Icons.check_circle, Colors.green, 'Attendance Successful!', 'You have been checked in.');
      case 'already_checked_in':
        return _ResultConfig(Icons.check_circle_outline, Colors.blue, "You've already checked in", 'See your check-in details below.');
      case 'too_early':
        final opensAt = result['opens_at'] != null ? formatWib(result['opens_at']) : '';
        return _ResultConfig(Icons.hourglass_top, Colors.orange, 'Check-in not open yet', 'Opens at $opensAt');
      case 'too_late':
        final closedAt = result['closed_at'] != null ? formatWib(result['closed_at']) : '';
        return _ResultConfig(Icons.cancel, Colors.red, 'Check-in closed', 'Closed at $closedAt');
      case 'no_active_event':
        return _ResultConfig(Icons.info_outline, Colors.grey, 'No active event', 'Nothing scheduled right now.');
      default:
        return _ResultConfig(Icons.error_outline, Colors.red, 'Something went wrong', result['message'] ?? '');
    }
  }
}

class _ResultConfig {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  _ResultConfig(this.icon, this.color, this.title, this.subtitle);
}