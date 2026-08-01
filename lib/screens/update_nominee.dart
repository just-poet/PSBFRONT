import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateNomineeScreen extends StatefulWidget {
  const UpdateNomineeScreen({super.key});

  @override
  State<UpdateNomineeScreen> createState() => _UpdateNomineeScreenState();
}

class _UpdateNomineeScreenState extends State<UpdateNomineeScreen> {
  final _nameController = TextEditingController(text: 'Priya Kapoor');
  final _relationshipController = TextEditingController(text: '');
  final _shareController = TextEditingController(text: '100');
  final _dobController = TextEditingController(text: '');

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _shareController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _showRelationshipPicker() {
    final options = ['Father', 'Mother', 'Spouse', 'Child', 'Sibling', 'Other'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Relationship',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1628),
                  ),
                ),
              ),
              const Divider(height: 1),
              ...options.map((option) => ListTile(
                    title: Text(
                      option,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _relationshipController.text = option;
                      });
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDobPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0B2545),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0A1628),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final String day = picked.day.toString().padLeft(2, '0');
      final String month = picked.month.toString().padLeft(2, '0');
      final String year = picked.year.toString();
      setState(() {
        _dobController.text = '$day / $month / $year';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Status Bar
            const _StatusBar(),

            // 2. Custom App Bar
            _buildAppBar(context),

            // 3. Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Heading: Current nominee
                    Text(
                      'Current nominee',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                        letterSpacing: -0.125,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Current Nominee Card
                    _buildCurrentNomineeCard(),
                    const SizedBox(height: 24),

                    // Section Heading: New nominee details
                    Text(
                      'New nominee details',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                        letterSpacing: -0.125,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Full Name Field (Selected state)
                    _buildInputField(
                      controller: _nameController,
                      label: 'Full name',
                      placeholder: 'Enter full name',
                      isSelected: true,
                    ),
                    const SizedBox(height: 12),

                    // Relationship Field
                    _buildInputField(
                      controller: _relationshipController,
                      label: 'Relationship',
                      placeholder: 'Select relationship',
                      isSelected: false,
                      onTap: _showRelationshipPicker,
                    ),
                    const SizedBox(height: 12),

                    // Share % Field
                    _buildInputField(
                      controller: _shareController,
                      label: 'Share %',
                      placeholder: 'Enter share %',
                      isSelected: false,
                      isMono: true,
                    ),
                    const SizedBox(height: 12),

                    // Date of birth Field
                    _buildInputField(
                      controller: _dobController,
                      label: 'Date of birth',
                      placeholder: 'DD / MM / YYYY',
                      isSelected: false,
                      onTap: _showDobPicker,
                    ),
                    const SizedBox(height: 18),

                    // Two-Person Note Banner
                    _buildTwoPersonBanner(),
                    const SizedBox(height: 18),

                    // Save Nominee Button
                    _buildSaveButton(),
                    const SizedBox(height: 16),
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
  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
      ),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF475569),
                size: 20,
              ),
            ),
          ),

          // Title
          Expanded(
            child: Center(
              child: Text(
                'Update Nominee',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A1628),
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),

          // Ghost width balance
          const SizedBox(width: 34),
        ],
      ),
    );
  }

  // Current Nominee Card Helper
  Widget _buildCurrentNomineeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Block
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFF2E75B6),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Nominee Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harshith Bandla',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1628),
                    letterSpacing: -0.14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Father · 100% share',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),

          // Green Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF16A34A),
                  size: 10,
                ),
                const SizedBox(width: 3),
                Text(
                  'ON RECORD',
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF16A34A),
                    letterSpacing: 0.43,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Input Field Helper
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required bool isSelected,
    bool isMono = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E75B6) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E75B6),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: AbsorbPointer(
                absorbing: onTap != null,
                child: TextField(
                  controller: controller,
                  readOnly: onTap != null,
                  onTap: onTap,
                  cursorColor: const Color(0xFF2E75B6),
                  style: isMono
                      ? GoogleFonts.robotoMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0A1628),
                          letterSpacing: -0.28,
                        )
                      : GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: controller.text.isEmpty ? FontWeight.w400 : FontWeight.w500,
                          color: controller.text.isEmpty ? const Color(0xFF94A3B8) : const Color(0xFF0A1628),
                        ),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Two-Person Note Banner Helper
  Widget _buildTwoPersonBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11.0, vertical: 13.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 1.0),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF2E75B6),
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF475569),
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: 'Two-person rule. ',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A1628),
                    ),
                  ),
                  const TextSpan(
                    text: "Changing a nominee is a protected action — we'll send an email confirmation and apply it after a short verification.",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Save Nominee Button Helper
  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: () {
        // Save action
      },
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF0B2545),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Save nominee',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
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
