import 'package:flutter/material.dart';
import '../core/datetime_utils.dart';
import '../core/api_client.dart';

class CheckinResultScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  final bool forceShowForm;

  const CheckinResultScreen({
    super.key,
    required this.result,
    this.forceShowForm = false,
  });

  @override
  State<CheckinResultScreen> createState() =>
      _CheckinResultScreenState();
}

class _CheckinResultScreenState extends State<CheckinResultScreen> {

  bool get _isFirstCheckin =>
    widget.result['already_fill_form'] != true || widget.forceShowForm;

  bool _confirmedLatest = false;
  bool _loadingProfile = true;
  bool _saving = false;
  String? _profileError;
  bool? _ktbHas;
  bool? _wantJoinKtb;
  final Set<String> _serveAs = {};
  late final TextEditingController _serveAsOtherController;
  String? _marriageStatus;

  late final TextEditingController _universityController;
  late final TextEditingController _stambukController;
  late final TextEditingController _addressController;
  late final TextEditingController _birthPlaceController;
  late final TextEditingController _birthDateController;
  DateTime? _birthDate;

  String? _validateForm() {
    if (_universityController.text.trim().isEmpty) return 'Asal Sekolah/Universitas wajib diisi.';
    if (_stambukController.text.trim().isEmpty) return 'Tahun Angkatan/Stambuk wajib diisi.';
    if (_addressController.text.trim().isEmpty) return 'Domisili wajib diisi.';
    if (_birthPlaceController.text.trim().isEmpty) return 'Tempat Lahir wajib diisi.';
    if (_birthDate == null) return 'Tanggal Lahir wajib diisi.';
    if (_ktbHas == null) return 'Mohon pilih apakah kamu sudah memiliki KTB.';
    if (_wantJoinKtb == null) return 'Mohon pilih apakah kamu ingin bergabung dengan KTB.';
    if (_wantJoinKtb == true && _serveAs.isEmpty) return 'Mohon pilih minimal satu pelayanan.';
    if (_marriageStatus == null) return 'Mohon pilih status pernikahan.';
    return null; // all good
  }

  @override
  void initState() {
    super.initState();
    _universityController = TextEditingController();
    _stambukController = TextEditingController();
    _addressController = TextEditingController();
    _birthPlaceController = TextEditingController();
    _birthDateController = TextEditingController();
    _serveAsOtherController = TextEditingController();
    if (_isFirstCheckin) {
      _fetchProfile();
    } else {
      _loadingProfile = false;
    }
  }

  @override
  void dispose() {
    _universityController.dispose();
    _stambukController.dispose();
    _addressController.dispose();
    _birthPlaceController.dispose();
    _birthDateController.dispose();
    _serveAsOtherController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });

    try {
      final result = await ApiClient.fetch('/users/me', auth: true);
      final user = result['data'] as Map<String, dynamic>? ?? {};

      _universityController.text = user['university'] ?? '';
      _stambukController.text = user['stambuk'] ?? '';
      _addressController.text = user['domicile_address'] ?? '';
      _birthPlaceController.text = user['birth_place'] ?? '';
      _birthDate = DateTime.tryParse(user['birth_date'] ?? '');
      _birthDateController.text =
          _birthDate != null ? formatIndo(_birthDate!.toIso8601String()) : '';

      _ktbHas = user['ktb_has'];
      _wantJoinKtb = user['want_join_ktb'];

      _serveAs.clear();
      final serveAs = user['serve_as'];
      if (serveAs is List) {
        _serveAs.addAll(serveAs.map((item) => item.toString().trim()));
      } else if (serveAs is String && serveAs.isNotEmpty) {
        final cleaned = serveAs.replaceAll('{', '').replaceAll('}', '');
        if (cleaned.isNotEmpty) {
          _serveAs.addAll(
            cleaned.split(',').map((item) => item.trim().replaceAll('"', '')),
          );
        }
      }
      _serveAsOtherController.text = user['serve_as_other'] ?? '';

      _marriageStatus = user['marriage_status'];

      if (!mounted) return;
      setState(() => _loadingProfile = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
        _profileError = 'Gagal memuat data profil kamu.';
      });
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = _birthDate ?? DateTime(2000, 1, 1);
    final safeInitialDate = initialDate.isAfter(now) ? now : initialDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: DateTime(1950),
      lastDate: now,
      helpText: 'SELECT YOUR BIRTH DATE',
    );

    if (picked == null || !mounted) return;

    setState(() {
      _birthDate = picked;
      _birthDateController.text = formatIndo(picked.toIso8601String());
    });
  }

  Future<void> _confirmAndBack() async {
    final validationError = _validateForm();
    if (validationError != null) {
      setState(() => _profileError = validationError);
      return;
    }

    setState(() {
      _saving = true;
      _profileError = null;
    });

    try {
      final result = await ApiClient.patch(
        '/users/me',
        {
          'university': _universityController.text.trim(),
          'stambuk': _stambukController.text.trim(),
          'domicile_address': _addressController.text.trim(),
          'birth_place': _birthPlaceController.text.trim(),
          'birth_date': _birthDate != null
              ? '${_birthDate!.year.toString().padLeft(4, '0')}-'
                '${_birthDate!.month.toString().padLeft(2, '0')}-'
                '${_birthDate!.day.toString().padLeft(2, '0')}'
              : null,
          'ktb_has': _ktbHas,
          'want_join_ktb': _wantJoinKtb,
          'serve_as': _serveAs.toList(),
          'serve_as_other': _serveAs.contains('Lainnya')
              ? _serveAsOtherController.text.trim()
              : null,
          'marriage_status': _marriageStatus,
        },
        auth: true,
      );

      if (!mounted) return;

      if (result.containsKey('data')) {
        final eventId = widget.result['event']?['id'];
        if (eventId != null) {
          await ApiClient.post('/checkin/$eventId/already-fill-form', {}, auth: true);
        }
        if (!mounted) return;
        Navigator.of(context).pop();
      } else {
        setState(() {
          _saving = false;
          _profileError = result['message'] ?? 'Gagal menyimpan data kamu.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _profileError = 'Gagal menyimpan data kamu. Silakan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

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

                  if (_isFirstCheckin) ...[
                    _buildFormSection(),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 20),

                  _buildBackButton(context),

                  const SizedBox(height: 12),

                  const Text(
                    '©2026 PAKSU Attendance App. All rights reserved.',
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
                  'Event',
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
                      ? 'Event tidak dikenal'
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

  Widget _buildFormSection() {
    if (_loadingProfile) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Form Data Diri',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sebelum lanjut, mohon isi data terbaru kamu di form berikut.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _universityController,
            label: 'Asal Sekolah/Universitas',
            icon: Icons.school_outlined,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _stambukController,
            label: 'Tahun Angkatan/Stambuk',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressController,
            label: 'Domisili Saat Ini (Contoh: Cawang, Jakarta Timur)',
            icon: Icons.location_on_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _birthPlaceController,
            label: 'Tempat Lahir',
            icon: Icons.location_city_outlined,
          ),

          const SizedBox(height: 12),
          _buildDateField(),
          const SizedBox(height: 20),
          _buildKtbHasField(),
          const SizedBox(height: 20),
          _buildWantJoinKtbField(),
          const SizedBox(height: 20),
          _buildServeAsField(),
          const SizedBox(height: 20),
          _buildMarriageStatusField(),

          if (_profileError != null) ...[
            const SizedBox(height: 12),
            Text(
              _profileError!,
              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
            ),
          ],

          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _confirmedLatest,
            onChanged: _saving
                ? null
                : (value) => setState(() => _confirmedLatest = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Saya sudah memastikan data saya adalah yang terbaru.',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          enabled: !_saving,
          maxLines: maxLines,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 19, color: const Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tanggal Lahir', style: TextStyle(
          color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: 7),
        TextField(
          controller: _birthDateController,
          readOnly: true,
          enabled: !_saving,
          onTap: _pickBirthDate,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Pilih tanggal lahir kamu',
            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 19, color: Color(0xFF64748B)),
            suffixIcon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKtbHasField() {
    return _buildRadioGroup(
      label: 'Apakah sudah memiliki KTB?',
      options: const [
        {'label': 'Ya', 'value': true},
        {'label': 'Tidak', 'value': false},
      ],
      value: _ktbHas,
      onChanged: (value) => setState(() => _ktbHas = value),
    );
  }

  Widget _buildWantJoinKtbField() {
    return _buildRadioGroup(
      label:
          'Apakah kamu ingin bergabung dengan KTB dan ingin dihubungi oleh Komisi KTB?',
      options: const [
        {'label': 'Ya', 'value': true},
        {'label': 'Tidak', 'value': false},
      ],
      value: _wantJoinKtb,
      onChanged: (value) => setState(() => _wantJoinKtb = value),
    );
  }

  Widget _buildServeAsField() {
    const options = [
      'Singer',
      'MC',
      'Pemusik',
      'Operator Slide',
      'Penerima Tamu',
      'Lainnya',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jika Ya, kamu ingin melayani sebagai apa?',
          style: TextStyle(
            color: Color(0xFF334155),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        ...options.map((option) {
          return CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(option, style: const TextStyle(
              color: Color(0xFF334155), fontSize: 13,
            )),
            value: _serveAs.contains(option),
            onChanged: _saving
                ? null
                : (checked) {
                    setState(() {
                      if (checked == true) {
                        _serveAs.add(option);
                      } else {
                        _serveAs.remove(option);
                        if (option == 'Lainnya') {
                          _serveAsOtherController.clear();
                        }
                      }
                    });
                  },
          );
        }),
        if (_serveAs.contains('Lainnya')) ...[
          const SizedBox(height: 4),
          _buildTextField(
            controller: _serveAsOtherController,
            label: 'Lainnya',
            icon: Icons.edit_outlined,
          ),
        ],
      ],
    );
  }

  Widget _buildMarriageStatusField() {
    return _buildRadioGroup(
      label: 'Status',
      options: const [
        {'label': 'Single', 'value': 'single'},
        {'label': 'Menikah', 'value': 'married'},
      ],
      value: _marriageStatus,
      onChanged: (value) => setState(() => _marriageStatus = value),
    );
  }

  Widget _buildRadioGroup<T>({
    required String label,
    required List<Map<String, dynamic>> options,
    required T? value,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: 6),
        ...options.map((option) {
          final optionValue = option['value'] as T;
          return RadioListTile<T>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(option['label'] as String, style: const TextStyle(
              color: Color(0xFF334155), fontSize: 13,
            )),
            value: optionValue,
            groupValue: value,
            onChanged: _saving ? null : onChanged,
          );
        }),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    final canProceed =
        !_isFirstCheckin || (_confirmedLatest && !_loadingProfile && !_saving);

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: canProceed
            ? (_isFirstCheckin
                ? _confirmAndBack
                : () => Navigator.of(context).pop())
            : null,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.qr_code_scanner, size: 18),
        label: const Text('Selesai'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          disabledForegroundColor: const Color(0xFF94A3B8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
          title: 'Absen berhasil!',
          subtitle:
              'Kamu sudah berhasil check in. Selamat datang, Tuhan Yesus Memberkati!',
        );

      case 'already_checked_in':
        return _ResultConfig(
          icon: Icons.check_circle_outline,
          color: const Color(0xFF2563EB),
          backgroundColor:
              const Color(0xFFEFF6FF),
          title: "Kamu Sudah Check In",
          subtitle:
              'Kamu sudah check in untuk event ini.',
        );

      case 'too_early':
        final opensAt =
            widget.result['opens_at'] != null
                ? formatWib(widget.result['opens_at'])
                : '';

        return _ResultConfig(
          icon: Icons.schedule_outlined,
          color: const Color(0xFFD97706),
          backgroundColor: const Color(0xFFFFFBEB),
          title: 'Check-in Belum Dibuka',
          subtitle:
              'Silakan tunggu hingga absensi dibuka.',
          detail: opensAt.isNotEmpty
              ? 'Check-in dibuka pada $opensAt.'
              : null,
        );

      case 'too_late':
        final closedAt =
            widget.result['closed_at'] != null
                ? formatWib(widget.result['closed_at'])
                : '';

        return _ResultConfig(
          icon: Icons.event_busy_outlined,
          color: const Color(0xFFDC2626),
          backgroundColor: const Color(0xFFFEF2F2),
          title: 'Check-in sudah ditutup.',
          subtitle:
              'Periode absensi untuk event ini telah berakhir.',
          detail: closedAt.isNotEmpty
              ? 'Check-in ditutup pada $closedAt.'
              : null,
        );

      case 'no_active_event':
        return _ResultConfig(
          icon: Icons.event_available_outlined,
          color: const Color(0xFF64748B),
          backgroundColor:
              const Color(0xFFF1F5F9),
          title: 'Tidak ada event aktif',
          subtitle:
              'Tidak ada event yang tersedia untuk check-in saat ini.',
        );

      case 'network_error':
        return _ResultConfig(
          icon: Icons.wifi_off_outlined,
          color: const Color(0xFF64748B),
          backgroundColor: const Color(0xFFF1F5F9),
          title: 'Tidak ada koneksi internet',
          subtitle:
              'Kami tidak dapat terhubung ke server.',
          detail: widget.result['message'] ??
              'Silakan periksa koneksi kamu dan coba lagi.',
        );

      default:
        return _ResultConfig(
          icon: Icons.error_outline,
          color: const Color(0xFFDC2626),
          backgroundColor:
              const Color(0xFFFEF2F2),
          title: 'Something Went Wrong',
          subtitle:
              'Kami tidak dapat menyelesaikan check-in Anda.',
          detail: widget.result['message'] ??
              'Silakan coba pindai kode QR lagi.',
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