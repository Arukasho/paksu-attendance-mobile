import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/datetime_utils.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  late final TextEditingController _universityController;
  late final TextEditingController _stambukController;
  late final TextEditingController _addressController;
  late final TextEditingController _birthPlaceController;
  late final TextEditingController _birthDateController;
  
  DateTime? _birthDate;
  bool _saving = false;
  String? _errorMessage;
  bool? _ktbHas;
  bool? _wantJoinKtb;

  final Set<String> _serveAs = {};
  late final TextEditingController _serveAsOtherController;

  String? _marriageStatus;

  @override
  void initState() {
    super.initState();

    _universityController =
        TextEditingController(
      text: widget.user['university'] ?? '',
    );

    _stambukController =
        TextEditingController(
      text: widget.user['stambuk'] ?? '',
    );

    _addressController =
        TextEditingController(
      text: widget.user['domicile_address'] ?? '',
    );

    _birthPlaceController =
        TextEditingController(
      text: widget.user['birth_place'] ?? '',
    );

    _birthDate = DateTime.tryParse(widget.user['birth_date'] ?? '');
    _birthDateController = TextEditingController(
      text: _birthDate != null ? formatIndo(_birthDate!.toIso8601String()) : '',
    );

    _ktbHas = widget.user['ktb_has'];
    _wantJoinKtb = widget.user['want_join_ktb'];

    final serveAs = widget.user['serve_as'];

    if (serveAs is List) {
      _serveAs.addAll(
        serveAs.map((item) => item.toString().trim()),
      );
    } else if (serveAs is String && serveAs.isNotEmpty) {
      final cleaned = serveAs
          .replaceAll('{', '')
          .replaceAll('}', '');

      if (cleaned.isNotEmpty) {
        _serveAs.addAll(
          cleaned
              .split(',')
              .map(
                (item) => item
                    .trim()
                    .replaceAll('"', ''),
              ),
        );
      }
    }

    _serveAsOtherController =
        TextEditingController(
      text: widget.user['serve_as_other'] ?? '',
    );

    _marriageStatus =
        widget.user['marriage_status'];

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

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiClient.patch(
        '/users/me',
        {
          'university':
              _universityController.text.trim(),
          'stambuk':
              _stambukController.text.trim(),
          'domicile_address':
              _addressController.text.trim(),
          'birth_place':
              _birthPlaceController.text.trim(),
          'birth_date': _birthDate != null
            ? '${_birthDate!.year.toString().padLeft(4, '0')}-'
              '${_birthDate!.month.toString().padLeft(2, '0')}-'
              '${_birthDate!.day.toString().padLeft(2, '0')}'
            : null,
          'ktb_has':
              _ktbHas,
          'want_join_ktb':
              _wantJoinKtb,
          'serve_as':
              _serveAs.toList(),
          'serve_as_other':
              _serveAs.contains('Lainnya')
                  ? _serveAsOtherController.text.trim()
                  : null,
          'marriage_status':
              _marriageStatus,
        },
        auth: true,
      );

      if (!mounted) return;

      if (result.containsKey('data')) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _saving = false;
          _errorMessage =
              result['message'] ??
                  'Gagal memperbarui profil kamu.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _errorMessage =
            'Gagal menyimpan profil kamu. Silakan coba lagi.';
      });
    }
  }

  Future<void> _pickBirthDate() async {
    final parsedDate =
        DateTime.tryParse(
          _birthDateController.text,
        );

    final now = DateTime.now();

    final initialDate =
        parsedDate ?? DateTime(2000, 1, 1);

    final safeInitialDate = initialDate.isAfter(now)
        ? now
        : initialDate;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: _saving
              ? null
              : () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF0F172A),
          ),
        ),
        title: const Text(
          'Lengkapi Data Kamu',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildHeader(),

                  const SizedBox(height: 24),

                  _buildFormCard(),

                  const SizedBox(height: 20),

                  if (_errorMessage != null)
                    _buildErrorMessage(),

                  if (_errorMessage != null)
                    const SizedBox(height: 16),

                  _buildSaveButton(),
                  
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.person_outline,
            color: Color(0xFF2563EB),
            size: 25,
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Lengkapi Data Kamu',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 23,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Lengkapi data kamu untuk melengkapi'
          ' database PAKSU.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Form Data Diri',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Silakan isi form berikut.',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 20),

          _buildTextField(
            controller: _universityController,
            label: 'Asal Sekolah/Universitas',
            hint: 'Masukkan asal universitas kamu',
            icon: Icons.school_outlined,
            textInputAction:
                TextInputAction.next,
          ),

          const SizedBox(height: 14),

          _buildTextField(
            controller: _stambukController,
            label: 'Tahun Angkatan/Stambuk',
            hint: 'Masukkan tahun angkatan kamu',
            icon: Icons.badge_outlined,
            textInputAction:
                TextInputAction.next,
          ),

          const SizedBox(height: 14),

          _buildTextField(
            controller: _addressController,
            label: 'Domisili Saat Ini (Contoh: Cawang, Jakarta Timur)',
            hint: 'Masukkan alamat domisili kamu',
            icon: Icons.location_on_outlined,
            maxLines: 3,
            textInputAction:
                TextInputAction.next,
          ),

          const SizedBox(height: 14),

          _buildTextField(
            controller: _birthPlaceController,
            label: 'Tempat Lahir',
            hint: 'Masukkan tempat lahir kamu',
            icon: Icons.location_city_outlined,
            textInputAction:
                TextInputAction.next,
          ),

          const SizedBox(height: 14),

          _buildDateField(),

          const SizedBox(height: 20),

          _buildKtbHasField(),

          const SizedBox(height: 20),

          _buildWantJoinKtbField(),

          const SizedBox(height: 20),

          _buildServeAsField(),

          const SizedBox(height: 20),

          _buildMarriageStatusField(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputAction? textInputAction,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 7),

        TextField(
          controller: controller,
          enabled: !_saving,
          maxLines: maxLines,
          textInputAction: textInputAction,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
            prefixIcon: Icon(
              icon,
              size: 19,
              color: const Color(0xFF64748B),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 1.5,
              ),
            ),
            disabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Tanggal Lahir',
          style: TextStyle(
            color: Color(0xFF334155),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 7),

        TextField(
          controller: _birthDateController,
          readOnly: true,
          enabled: !_saving,
          onTap: _pickBirthDate,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: 'Pilih tanggal lahir kamu',
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.calendar_today_outlined,
              size: 19,
              color: Color(0xFF64748B),
            ),
            suffixIcon: const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor:
                const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(9),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFDC2626),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              const Color(0xFF93C5FD),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(9),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 19,
                height: 19,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                    Colors.white,
                  ),
                ),
              )
            : const Text(
                'Simpan Data',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
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
      onChanged: (value) {
        setState(() {
          _ktbHas = value;
        });
      },
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
      onChanged: (value) {
        setState(() {
          _wantJoinKtb = value;
        });
      },
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

        ...options.map(
          (option) {
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity:
                  ListTileControlAffinity.leading,
              title: Text(
                option,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 13,
                ),
              ),
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
          },
        ),

        if (_serveAs.contains('Lainnya')) ...[
          const SizedBox(height: 4),

          _buildTextField(
            controller: _serveAsOtherController,
            label: 'Lainnya',
            hint: 'Tuliskan pelayanan lainnya',
            icon: Icons.edit_outlined,
            textInputAction:
                TextInputAction.next,
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
      onChanged: (value) {
        setState(() {
          _marriageStatus = value;
        });
      },
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
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 6),

        ...options.map(
          (option) {
            final optionValue =
                option['value'] as T;

            return RadioListTile<T>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity:
                  ListTileControlAffinity.leading,
              title: Text(
                option['label'] as String,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 13,
                ),
              ),
              value: optionValue,
              groupValue: value,
              onChanged: _saving
                  ? null
                  : onChanged,
            );
          },
        ),
      ],
    );
  }

}