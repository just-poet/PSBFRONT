import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegimeComparisonScreen extends StatelessWidget {
  const RegimeComparisonScreen({super.key});

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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estimated Saving Header Card
                    _buildEstimatedSavingHeader(),
                    const SizedBox(height: 22),

                    // Comparison Slabs (Old vs New Regime)
                    _buildRegimeComparisonRow(),
                    const SizedBox(height: 22),

                    // Section: How this works
                    Text(
                      'How this works',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                        letterSpacing: -0.125,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Explained Points Card
                    _buildExplanationsCard(),
                    const SizedBox(height: 22),

                    // Note Banner
                    _buildNoteBanner(),
                    const SizedBox(height: 22),

                    // Apply Button
                    _buildApplyButton(context),
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered Title
          Text(
            'Regime Comparison',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
              letterSpacing: -0.15,
            ),
          ),

          // Back Button
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
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
                  Icons.arrow_back_rounded,
                  color: Color(0xFF475569),
                  size: 18,
                ),
              ),
            ),
          ),
          
          // Right ghost spacer to maintain title alignment
          const Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 34,
              height: 34,
            ),
          ),
        ],
      ),
    );
  }

  // Estimated Saving Header
  Widget _buildEstimatedSavingHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'ESTIMATED SAVING',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹18,720',
            style: GoogleFonts.fraunces(
              fontSize: 32,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF16A34A),
              letterSpacing: -0.64,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'New regime looks lower for you this year ·\nestimate',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF475569),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // Regime Comparison Row
  Widget _buildRegimeComparisonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Old Regime
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(15.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OLD REGIME',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹1,12,320',
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF0B2545),
                    letterSpacing: -0.48,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'with deductions\nclaimed',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF475569),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // New Regime
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(15.0),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF16A34A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEW REGIME',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF16A34A),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹93,600',
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF16A34A),
                    letterSpacing: -0.48,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'lower slabs, fewer\nbreaks',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF475569),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Explanations Card
  Widget _buildExplanationsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.04),
            blurRadius: 1.5,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.06),
            blurRadius: 1.0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Item 1: Old Regime
          _buildExplanationItem(
            dotColor: const Color(0xFF2E75B6),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF0A1628),
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: 'Old regime',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B2545),
                    ),
                  ),
                  const TextSpan(text: ' lets you subtract 80C,\n80D, HRA and home-loan interest\nbefore tax'),
                ],
              ),
            ),
          ),
          // Divider
          Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
          // Item 2: New Regime
          _buildExplanationItem(
            dotColor: const Color(0xFF2E75B6),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF0A1628),
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: 'New regime',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B2545),
                    ),
                  ),
                  const TextSpan(text: ' has lower slab rates but\nremoves most deductions'),
                ],
              ),
            ),
          ),
          // Divider
          Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
          // Item 3: Comparing
          _buildExplanationItem(
            dotColor: const Color(0xFF16A34A),
            child: Text(
              'FINIX compares both on your real\nnumbers and shows whichever leaves\nmore in hand',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.normal,
                color: const Color(0xFF0A1628),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationItem({
    required Color dotColor,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(child: child),
        ],
      ),
    );
  }

  // Note Banner
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
          const Padding(
            padding: EdgeInsets.only(top: 1.0),
            child: Icon(
              Icons.info_outline,
              color: Color(0xFF2E75B6),
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Final tax depends on proofs you submit.\nFigures shown are estimates for FY25-26.',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF475569),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Apply Button
  Widget _buildApplyButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Apply regime action
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New regime applied successfully!')),
        );
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
            'Apply new regime →',
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
