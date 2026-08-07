import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ekyc.dart';
import 'audit_logs.dart';
import '../main.dart';
import '../services/api_service.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  // Identity and contact details come from /v1/kyc/profile and
  // /v1/settings/profile. Every field on this screen used to be a literal —
  // "Venkat Avva", DOB 18/09/2002, a Uttar Pradesh address — so it described
  // one person no matter who signed in.
  Map<String, dynamic> _kyc = const {};
  bool _loading = true;

  String _mobileNumber = '';
  String _emailAddress = '';
  String _addressText = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      ApiService.instance.getKycProfile(),
      ApiService.instance.getProfile(),
    ]);
    if (!mounted) return;
    final kyc = results[0];
    final profile = results[1];
    setState(() {
      _kyc = kyc;
      _mobileNumber = (kyc['mobileNumber'] ?? profile['mobile'] ?? '').toString();
      _emailAddress = (kyc['email'] ?? profile['email'] ?? '').toString();
      final comm = (kyc['communicationAddress'] ?? '').toString();
      _addressText =
          comm.isNotEmpty ? comm : (kyc['permanentAddress'] ?? '').toString();
      _loading = false;
    });
  }

  String _field(String key, {String fallback = 'Not on record'}) {
    final v = (_kyc[key] ?? '').toString();
    return v.isEmpty ? fallback : v;
  }

  /// KYC dates arrive as ISO timestamps; the design shows dd/MM/yyyy.
  static String _asDate(dynamic iso, {String fallback = '--'}) {
    final d = DateTime.tryParse((iso ?? '').toString());
    if (d == null) return fallback;
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  void _showEditDialog({
    required String title,
    required String initialValue,
    required Function(String) onSave,
    bool isMultiline = false,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
            ),
          ),
          content: TextField(
            controller: controller,
            maxLines: isMultiline ? 3 : 1,
            autofocus: true,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0A1628)),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0B2545), width: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                tr('Cancel'),
                style: GoogleFonts.inter(
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                onSave(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title updated successfully!'),
                    backgroundColor: const Color(0xFF16A34A),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B2545),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                tr('Save'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Status Bar
            const _StatusBar(),

            // Custom AppBar
            _buildAppBar(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Card (KYC Status Strip)
                    _buildKycStatusStrip(),
                    const SizedBox(height: 24),

                    // IDENTITY SECTION
                    _buildSectionHeader('IDENTITY · LOCKED TO KYC'),
                    const SizedBox(height: 8),
                    _buildIdentityCard(),
                    const SizedBox(height: 16),

                    // Warning Notice Box 1
                    _buildKycNoticeBox(),
                    const SizedBox(height: 24),

                    // CONTACT SECTION
                    _buildSectionHeader('CONTACT'),
                    const SizedBox(height: 8),
                    _buildContactCard(),
                    const SizedBox(height: 16),

                    // Two-Person Rule Warning Notice Box 2 (Amber)
                    _buildTwoPersonNoticeBox(),
                    const SizedBox(height: 24),

                    // VERIFICATION SECTION
                    _buildSectionHeader('VERIFICATION'),
                    const SizedBox(height: 8),
                    _buildVerificationCard(),
                    const SizedBox(height: 24),

                    // Request Correction Button
                    _buildCorrectionButton(),
                    const SizedBox(height: 16),

                    // Footer text
                    _buildFooter(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom App Bar
  Widget _buildAppBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF475569),
                  size: 14,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                tr('Personal details'),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A1628),
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
          // Spacer
          const SizedBox(width: 34),
        ],
      ),
    );
  }

  // Section Header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475569),
          letterSpacing: 0.99,
        ),
      ),
    );
  }

  // Top Card (KYC Status Strip)
  Widget _buildKycStatusStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.04),
            blurRadius: 1.5,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.06),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF0B2545), Color(0xFF2E75B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                ApiService.instance.userInitials,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.34,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Metadata Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ApiService.instance.userName.value ?? 'Signed out',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1628),
                    letterSpacing: -0.32,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _loading
                      ? 'Loading your KYC…'
                      : '${_field('kycStatus', fallback: 'KYC pending') == 'verified' ? 'Full KYC' : 'KYC ${_field('kycStatus', fallback: 'pending')}'}'
                          ' · ${_asDate(_kyc['kycSubmissionDate'])}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Identity Card (Locked to KYC)
  Widget _buildIdentityCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildReadOnlyRow(
            'Full name',
            _field('fullName',
                fallback: ApiService.instance.userName.value ?? 'Signed out'),
          ),
          _buildDivider(),
          _buildReadOnlyRow(
            'Date of birth',
            _kyc['dateOfBirth'] == null ||
                    _kyc['dateOfBirth'].toString().isEmpty
                ? 'Not on record'
                : _asDate(_kyc['dateOfBirth'],
                    fallback: _kyc['dateOfBirth'].toString()),
            isMono: true,
          ),
          _buildDivider(),
          _buildReadOnlyRow('PAN', _field('panMasked'), isMono: true),
          _buildDivider(),
          _buildReadOnlyRow(
            'Aadhaar',
            _field('aadhaarMaskedOrHash'),
            isMono: true,
            footnote: 'Masked as required by UIDAI. Full number is never stored.',
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value, {bool isMono = false, String? footnote}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                    letterSpacing: 0.55,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: isMono
                      ? GoogleFonts.robotoMono(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0A1628),
                          letterSpacing: 0.29,
                        )
                      : GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0A1628),
                          letterSpacing: -0.14,
                        ),
                ),
                if (footnote != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    footnote,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.lock_outline_rounded,
            color: Color(0xFF94A3B8),
            size: 16,
          ),
        ],
      ),
    );
  }

  // Warning Notice Box 1
  Widget _buildKycNoticeBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FA),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Center(
              child: Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF2E75B6),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF475569),
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: 'These four fields come from your bank\'s KYC record\n',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A1628),
                    ),
                  ),
                  const TextSpan(
                    text: 'To correct a name, date of birth, PAN or Aadhaar, raise a request below. Your branch verifies it — we can\'t edit it here.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Contact Card (Editable)
  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.04),
            blurRadius: 1.5,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.06),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Mobile Row
          _buildEditableRow(
            label: 'Mobile',
            value: _mobileNumber,
            isMono: true,
            footnote: 'Registered with SBI · used for OTP',
            actionText: 'Change',
            onTap: () => _showEditDialog(
              title: 'Mobile number',
              initialValue: _mobileNumber,
              onSave: (val) {
                setState(() {
                  _mobileNumber = val;
                });
              },
            ),
          ),
          _buildDivider(),
          // Email Row
          _buildEditableRow(
            label: 'Email',
            value: _emailAddress,
            actionText: 'Edit',
            onTap: () => _showEditDialog(
              title: 'Email address',
              initialValue: _emailAddress,
              onSave: (val) {
                setState(() {
                  _emailAddress = val;
                });
              },
            ),
          ),
          _buildDivider(),
          // Address Row
          _buildEditableRow(
            label: 'Address',
            value: _addressText,
            isMultiline: true,
            actionText: 'Edit',
            onTap: () => _showEditDialog(
              title: 'Address details',
              initialValue: _addressText,
              isMultiline: true,
              onSave: (val) {
                setState(() {
                  _addressText = val;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow({
    required String label,
    required String value,
    bool isMono = false,
    bool isMultiline = false,
    String? footnote,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                    letterSpacing: 0.55,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: isMono
                      ? GoogleFonts.robotoMono(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0A1628),
                          letterSpacing: 0.29,
                        )
                      : GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0A1628),
                          letterSpacing: -0.14,
                          height: isMultiline ? 1.4 : null,
                        ),
                ),
                if (footnote != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    footnote,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                actionText,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E75B6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Two-Person Rule Warning Notice Box 2 (Amber)
  Widget _buildTwoPersonNoticeBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Center(
              child: Icon(
                Icons.access_time_rounded,
                color: Color(0xFFF59E0B),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: const Color(0xFF475569),
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: 'Changing your mobile takes 24 hours\n',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A1628),
                    ),
                  ),
                  const TextSpan(text: 'A registered-number change is a common step in account takeover. We hold it for '),
                  TextSpan(
                    text: '24 hours',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B2545),
                    ),
                  ),
                  const TextSpan(text: ' and email your old address first, so you can stop it.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Verification Provenance card
  Widget _buildVerificationCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.04),
            blurRadius: 1.5,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.06),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // eKYC completed row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF16A34A),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('eKYC completed'),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A1628),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Aadhaar offline XML · 14/03/2025, 11:26 AM',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildDivider(),
          // Last profile change row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.history_rounded,
                      color: Color(0xFF0B2545),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Last profile change'),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A1628),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Address updated · 02/07/2026, 4:10 PM',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(
                        settings: const RouteSettings(name: '/audit_logs'),
                        builder: (context) => const MobileDeviceFrame(child: AuditLogsScreen()),
                      ),
                    );
                  },
                  child: Text(
                    tr('Log'),
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E75B6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Request Correction Button
  Widget _buildCorrectionButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          SmoothPageRoute(
            settings: const RouteSettings(name: '/ekyc'),
            builder: (context) => const MobileDeviceFrame(
              child: EkycScreen(isFromProfile: true),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF0B2545),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.edit_note_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              tr('Request a correction'),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Footer text
  Widget _buildFooter() {
    return Center(
      child: Text(
        'Handled under DPDP Act 2023 · request ID issued on submit',
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF94A3B8),
          letterSpacing: 0.21,
        ),
      ),
    );
  }

  // Divider Helper
  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFE2E8F0),
      indent: 16,
      endIndent: 16,
    );
  }
}

// ---------------------------------------------------------------------
// Status Bar Widget
// ---------------------------------------------------------------------
class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
