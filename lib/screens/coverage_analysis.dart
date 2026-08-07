import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';

class CoverageAnalysisScreen extends StatelessWidget {
  const CoverageAnalysisScreen({super.key});

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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Section title: Why we say this
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        tr('Why we say this'),
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A1628),
                          letterSpacing: -0.125,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Icon Container
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFFF59E0B),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Big Warning text
                    Text(
                      'You may be\nunderinsured',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF0B2545),
                        letterSpacing: -0.44,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Explanation text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Your life cover is below the level usually suggested for your income and dependents.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF475569),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Progress Comparison Card
                    _buildComparisonCard(),
                    const SizedBox(height: 16),

                    // Why Card (Benchmark, Dependents, Health)
                    _buildWhyCard(),
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

  // App Bar
  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Title
          Text(
            tr('Coverage Analysis'),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
              letterSpacing: -0.15,
            ),
          ),
          // Back button
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
          // Ghost spacer
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

  // Comparison Card (Current vs Suggested Cover)
  Widget _buildComparisonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15.0),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Cover
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('Current cover'),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF475569),
                ),
              ),
              Text(
                '₹50,00,000',
                style: GoogleFonts.spaceMono(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A1628),
                  letterSpacing: -0.25,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Current Cover Progress (42% used)
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 7,
              width: double.infinity,
              color: const Color(0xFFE2E8F0),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: 50.0 / 120.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E75B6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Suggested Cover
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('Suggested cover'),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF475569),
                ),
              ),
              Text(
                '₹1,20,00,000',
                style: GoogleFonts.spaceMono(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A1628),
                  letterSpacing: -0.25,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Suggested Cover Progress (100% green)
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 7,
              width: double.infinity,
              color: const Color(0xFFE2E8F0),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Gap text
          Text(
            'Gap of ₹70,00,000',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }

  // Why Card
  Widget _buildWhyCard() {
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
          // Row 1
          _buildWhyRow(
            spans: [
              const TextSpan(text: 'Cover is '),
              TextSpan(
                text: '3.4×',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF0B2545)),
              ),
              const TextSpan(text: ' annual income — a common benchmark is '),
              TextSpan(
                text: '10×',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF0B2545)),
              ),
            ],
            showDivider: true,
          ),

          // Row 2
          _buildWhyRow(
            spans: [
              const TextSpan(text: 'You have '),
              TextSpan(
                text: '2 dependents',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF0B2545)),
              ),
              const TextSpan(text: ' and an active home loan'),
            ],
            showDivider: true,
          ),

          // Row 3
          _buildWhyRow(
            spans: [
              const TextSpan(text: 'Health cover at '),
              TextSpan(
                text: '₹10L',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF0B2545)),
              ),
              const TextSpan(text: ' looks adequate for your family size'),
            ],
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildWhyRow({
    required List<TextSpan> spans,
    required bool showDivider,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
              ),
            )
          : null,
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: const Color(0xFF0A1628),
            height: 1.4,
          ),
          children: spans,
        ),
      ),
    );
  }

  // Button
  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: 268,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B2545),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Searching available high-affinity plans...',
                style: GoogleFonts.inter(),
              ),
            ),
          );
        },
        child: Text(
          tr('See suggested plans →'),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
