import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/datetime_utils.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await ApiClient.fetch('/users/me/attendance-history', auth: true);
    setState(() {
      _items = result['data'] ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_items.isEmpty) {
      return const Center(child: Text('No attendance history yet.'));
    }

    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final item = _items[i];
        return ListTile(
          title: Text(item['event_name'] ?? ''),
          subtitle: Text(formatWib(item['checked_in_at'])),
          trailing: const Icon(Icons.check_circle, color: Colors.green),
        );
      },
    );
  }
}