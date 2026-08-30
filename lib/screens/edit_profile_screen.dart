import 'package:flutter/material.dart';
import '../core/api_client.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _universityController;
  late final TextEditingController _stambukController;
  late final TextEditingController _addressController;
  late final TextEditingController _birthPlaceController;
  late final TextEditingController _birthDateController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _universityController = TextEditingController(text: widget.user['university'] ?? '');
    _stambukController = TextEditingController(text: widget.user['stambuk'] ?? '');
    _addressController = TextEditingController(text: widget.user['domicile_address'] ?? '');
    _birthPlaceController = TextEditingController(text: widget.user['birth_place'] ?? '');
    _birthDateController = TextEditingController(text: widget.user['birth_date'] ?? '');
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    await ApiClient.patch('/users/me', {
      'university': _universityController.text,
      'stambuk': _stambukController.text,
      'domicile_address': _addressController.text,
      'birth_place': _birthPlaceController.text,
      'birth_date': _birthDateController.text,
    }, auth: true);

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickBirthDate() async {
    final initial = DateTime.tryParse(_birthDateController.text) ?? DateTime(2000, 1, 1);

    final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(1950),
        lastDate: DateTime.now(),
    );

    if (picked != null) {
        // Format as YYYY-MM-DD to match what the backend's DATE column expects.
        setState(() {
        _birthDateController.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        });
    }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(controller: _universityController, decoration: const InputDecoration(labelText: 'Universitas')),
            const SizedBox(height: 12),
            TextField(controller: _stambukController, decoration: const InputDecoration(labelText: 'Stambuk')),
            const SizedBox(height: 12),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Alamat Domisili')),
            const SizedBox(height: 12),
            TextField(controller: _birthPlaceController, decoration: const InputDecoration(labelText: 'Tempat Lahir')),
            const SizedBox(height: 12),
            TextField(
                controller: _birthDateController,
                readOnly: true,
                onTap: _pickBirthDate,
                decoration: const InputDecoration(labelText: 'Tanggal Lahir', suffixIcon: Icon(Icons.calendar_today)),
                ),
            const SizedBox(height: 24),
            _saving
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}