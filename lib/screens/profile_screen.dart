import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/secure_storage.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;

  bool _loading = true;
  bool _uploadingPhoto = false;
  bool _loggingOut = false;

  int _photoCacheBuster = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

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
        _user = null;
        _loading = false;
      });
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(
      'https://admin.absensi-paksu.online/privacy',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_uploadingPhoto) return;

    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    if (!mounted) return;

    setState(() {
      _uploadingPhoto = true;
    });

    try {
      await ApiClient.uploadFile(
        '/users/me/photo',
        picked.path,
        auth: true,
      );

      if (!mounted) return;

      setState(() {
        _photoCacheBuster =
            DateTime.now().millisecondsSinceEpoch;
      });

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to update profile photo. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _editProfile() async {
    if (_user == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          user: _user!,
        ),
      ),
    );

    if (mounted) {
      await _load();
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    setState(() {
      _loggingOut = true;
    });

    try {
      final refreshToken =
          await SecureStorage.getRefreshToken();

      if (refreshToken != null) {
        await ApiClient.post(
          '/auth/logout',
          {
            'refresh_token': refreshToken,
          },
        );
      }
    } catch (_) {
      // Even if the server logout fails,
      // clear local credentials below.
    }

    await SecureStorage.clearTokens();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _logoutAllDevices() async {
    if (_loggingOut) return;

    final confirmed = await _showLogoutAllConfirmation();

    if (!confirmed || !mounted) return;

    setState(() {
      _loggingOut = true;
    });

    try {
      await ApiClient.post(
        '/users/me/logout-all',
        {},
        auth: true,
      );
    } catch (_) {
      // Still clear local credentials.
    }

    await SecureStorage.clearTokens();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<bool> _showLogoutAllConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Log out from all devices?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'This will sign you out from every device where '
            'your account is currently logged in.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFFDC2626),
              ),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_user == null) {
      return _buildErrorState();
    }

    final completion =
        (_user!['profile_completion'] ?? 0) as num;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          24,
          20,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            const SizedBox(height: 24),

            _buildProfileHeader(),

            const SizedBox(height: 20),

            _buildCompletionCard(completion),

            const SizedBox(height: 20),

            _buildAccountCard(),

            const SizedBox(height: 20),

            _buildActionsCard(),

            const SizedBox(height: 20),

            _buildPrivacyCard(),

            const SizedBox(height: 24),

            _buildLogoutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Profile',
      style: TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    );
  }

  Widget _buildProfileHeader() {
    final photoUrl = _user!['profile_photo_url'];
    final fullName = _user!['full_name'] ?? '';
    final username = _user!['username'] ?? '';

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _uploadingPhoto
                ? null
                : _pickAndUploadPhoto,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: const Color(0xFFE2E8F0),
                  backgroundImage: photoUrl != null
                      ? NetworkImage(
                          '$photoUrl?v=$_photoCacheBuster',
                        )
                      : null,
                  child: photoUrl == null
                      ? const Icon(
                          Icons.person_outline,
                          size: 48,
                          color: Color(0xFF64748B),
                        )
                      : null,
                ),

                Positioned(
                  right: 0,
                  bottom: 2,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: _uploadingPhoto
                        ? const Padding(
                            padding: EdgeInsets.all(7),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_outlined,
                            size: 15,
                            color: Colors.white,
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Text(
            fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            '@$username',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 8),

          GestureDetector(
            onTap: _uploadingPhoto
                ? null
                : _pickAndUploadPhoto,
            child: const Text(
              'Tap photo to change',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCard(num completion) {
    final percentage = completion.toInt().clamp(0, 100);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile Completion',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(
                Color(0xFF2563EB),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            percentage >= 100
                ? 'Your profile is complete.'
                : 'Complete your profile to provide more information.',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard() {
    return _sectionCard(
      title: 'Account Information',
      icon: Icons.person_outline,
      children: [
        _infoRow(
          icon: Icons.alternate_email,
          label: 'Username',
          value: _user!['username'],
        ),
        _infoRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: _user!['email'],
        ),
        _infoRow(
          icon: Icons.phone_outlined,
          label: 'Phone Number',
          value: _user!['phone'],
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildActionsCard() {
    return _sectionCard(
      title: 'Profile',
      icon: Icons.manage_accounts_outlined,
      children: [
        _actionTile(
          icon: Icons.edit_outlined,
          title: 'Complete / Edit Profile',
          subtitle: 'Update your personal information',
          onTap: _loggingOut ? null : _editProfile,
        ),
      ],
    );
  }

  Widget _buildPrivacyCard() {
    return _sectionCard(
      title: 'Privacy & Security',
      icon: Icons.shield_outlined,
      children: [
        _actionTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          subtitle: 'Learn how your personal data is handled',
          onTap: _loggingOut ? null : _openPrivacyPolicy,
        ),
      ],
    );
  }

  Widget _buildLogoutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(
            left: 4,
            bottom: 10,
          ),
          child: Text(
            'Account Actions',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        _card(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _logoutTile(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out from this device',
                onTap: _loggingOut ? null : _logout,
              ),

              const Divider(
                height: 1,
                indent: 56,
                color: Color(0xFFE2E8F0),
              ),

              _logoutTile(
                icon: Icons.logout_outlined,
                title: 'Logout from All Devices',
                subtitle: 'Sign out everywhere',
                destructive: true,
                onTap:
                    _loggingOut ? null : _logoutAllDevices,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required dynamic value,
    bool isLast = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 13,
      ),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
            ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 17,
              color: const Color(0xFF64748B),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value?.toString().isNotEmpty == true
                      ? value.toString()
                      : '-',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 4,
        ),
        child: Row(
          children: [
            _iconBox(icon),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoutTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool destructive = false,
  }) {
    final textColor = destructive
        ? const Color(0xFFDC2626)
        : const Color(0xFF334155);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: textColor,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            if (_loggingOut)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(
        icon,
        size: 19,
        color: const Color(0xFF2563EB),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(icon),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ...children,
        ],
      ),
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_outlined,
              size: 42,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            const Text(
              'Failed to load profile.',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _load,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}