import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/secure_storage.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'package:image_picker/image_picker.dart';

int _photoCacheBuster = DateTime.now().millisecondsSinceEpoch;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiClient.fetch('/users/me', auth: true);
    setState(() {
      _user = result['data'];
      _loading = false;
    });
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    await ApiClient.uploadFile('/users/me/photo', picked.path, auth: true);
    setState(() => _photoCacheBuster = DateTime.now().millisecondsSinceEpoch);
    final result = await ApiClient.uploadFile('/users/me/photo', picked.path, auth: true); //debug print line
    print('Upload result: $result'); //debug print line
    _load(); // refresh to show new photo
    }

  Future<void> _logout() async {
    final refreshToken = await SecureStorage.getRefreshToken();
    if (refreshToken != null) {
        await ApiClient.post('/auth/logout', {'refresh_token': refreshToken});
    }
    await SecureStorage.clearTokens();
    if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
        );
    }
    }

    Future<void> _logoutAllDevices() async {
      await ApiClient.post('/users/me/logout-all', {}, auth: true);
      await SecureStorage.clearTokens();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_user == null) return const Center(child: Text('Failed to load profile.'));

    final completion = _user!['profile_completion'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
            onTap: _pickAndUploadPhoto,
                child: CircleAvatar(
                radius: 48,
                backgroundImage: _user!['profile_photo_url'] != null
                    ? NetworkImage('${_user!['profile_photo_url']}?v=$_photoCacheBuster')
                    : null,
                child: _user!['profile_photo_url'] == null ? const Icon(Icons.person, size: 48) : null,
                ),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text(_user!['full_name'] ?? '', style: Theme.of(context).textTheme.titleLarge)),
          Center(child: Text('@${_user!['username'] ?? ''}', style: const TextStyle(color: Colors.grey))),
          const SizedBox(height: 24),
          const Text('Account Information', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _infoRow('Username', _user!['username']),
          _infoRow('Email', _user!['email']),
          _infoRow('Phone Number', _user!['phone']),
          const SizedBox(height: 24),
          Text('Profile Completion: $completion%'),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: completion / 100),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user!)),
              );
              _load(); // refresh after returning, in case it was edited
            },
            child: const Text('Complete / Edit Profile'),
          ),
          const SizedBox(height: 12),
            OutlinedButton(onPressed: _logout, child: const Text('Logout')),
          const SizedBox(height: 8),
            OutlinedButton(onPressed: _logoutAllDevices, child: const Text('Logout from All Devices')),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value ?? '-')],
      ),
    );
  }
}