import 'dart:ui';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'report_fraud.dart';

class FileClaimScreen extends StatefulWidget {
  const FileClaimScreen({super.key});

  @override
  State<FileClaimScreen> createState() => _FileClaimScreenState();
}

class _FileClaimScreenState extends State<FileClaimScreen> {
  String _selectedClaimType = 'Hospitalisation';
  final TextEditingController _amountController = TextEditingController(text: '42,500');

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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
                    // Note Banner
                    _buildNoteBanner(),
                    const SizedBox(height: 18),

                    // Section Heading: Which policy
                    Text(
                      'Which policy',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                        letterSpacing: -0.125,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Policy Selector Display
                    _buildPolicyCard(),
                    const SizedBox(height: 18),

                    // Section Heading: Claim type
                    Text(
                      'Claim type',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                        letterSpacing: -0.125,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Claim Type Chips
                    _buildClaimTypeChips(),
                    const SizedBox(height: 18),

                    // Section Heading: Claim amount
                    Text(
                      'Claim amount',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                        letterSpacing: -0.125,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Claim Amount Field
                    _buildAmountField(),
                    const SizedBox(height: 18),

                    // Section Heading: Documents
                    Text(
                      'Documents',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                        letterSpacing: -0.125,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Dashed Document Upload Area
                    _buildUploadArea(),
                    const SizedBox(height: 18),

                    // Submit Button
                    _buildSubmitButton(),
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
                'File a Claim',
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

  // Note Banner Helper
  Widget _buildNoteBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11.0),
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
              Icons.info_outline_rounded,
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
                    text: 'Quick claim. ',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A1628),
                    ),
                  ),
                  const TextSpan(
                    text: "Most claims need a policy, a reason, and proof. We'll guide the insurer hand-off for you.",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Policy Box Helper
  Widget _buildPolicyCard() {
    return Container(
      width: double.infinity,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2E75B6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Policy',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E75B6),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Health · Star Health ····2208',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A1628),
            ),
          ),
        ],
      ),
    );
  }

  // Claim Type Chips Helper
  Widget _buildClaimTypeChips() {
    final types = ['Hospitalisation', 'Day-care', 'Pharmacy', 'Report fraud'];
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: types.map((type) {
        final isSelected = _selectedClaimType == type;
        return GestureDetector(
          onTap: () {
            if (type == 'Report fraud') {
              Navigator.push(
                context,
                SmoothPageRoute(
                  settings: const RouteSettings(name: '/report_fraud'),
                  builder: (context) => const ReportFraudScreen(),
                ),
              );
            } else {
              setState(() {
                _selectedClaimType = type;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEEF4FA) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? const Color(0xFF2E75B6) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              type,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF2E75B6) : const Color(0xFF475569),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Amount Field Helper
  Widget _buildAmountField() {
    return Container(
      width: double.infinity,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Amount (₹)',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E75B6),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              cursorColor: const Color(0xFF2E75B6),
              style: GoogleFonts.robotoMono(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0A1628),
                letterSpacing: -0.28,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Upload Area Helper (Dashed Border Card)
  Widget _buildUploadArea() {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: const Color(0xFFE2E8F0),
        strokeWidth: 1.0,
        gap: 4.0,
        dash: 6.0,
        borderRadius: 12.0,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              color: Color(0xFF475569),
              size: 22,
            ),
            const SizedBox(height: 9),
            Text(
              'Upload bills & discharge summary',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A1628),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'PDF or image · up to 10 MB',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Submit Button Helper
  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: () {
        // Submit action
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
            'Submit claim',
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

// ---------------------------------------------------------------------
// Custom Dashed Border Painter
// ---------------------------------------------------------------------
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.dash,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashPath = Path();
    double distance = 0;
    bool draw = true;

    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        final length = draw ? dash : gap;
        dashPath.addPath(
          measurePath.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += length;
        draw = !draw;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
