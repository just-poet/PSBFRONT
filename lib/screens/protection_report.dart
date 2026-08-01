import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'coverage_analysis.dart';
import 'smooth_route.dart';

class ProtectionReportScreen extends StatelessWidget {
  const ProtectionReportScreen({super.key});

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
                    // Hero Card
                    _buildHeroCard(),
                    const SizedBox(height: 24),

                    // Section Header: By area
                    Text(
                      'By area',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                        letterSpacing: -0.125,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Health Card (Strong)
                    _buildAreaCard(
                      icon: Icons.favorite_border_rounded,
                      iconColor: const Color(0xFF16A34A),
                      iconBgColor: const Color(0x1A16A34A),
                      title: 'Health',
                      subtitle: 'Family floater · ₹10L',
                      badgeText: 'Strong',
                      badgeColor: const Color(0xFF16A34A),
                      badgeBgColor: const Color(0x1A16A34A),
                    ),
                    const SizedBox(height: 12),

                    // Life Card (Gap) -> Navigate to Coverage Analysis
                    _buildAreaCard(
                      icon: Icons.person_outline_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      iconBgColor: const Color(0x1AF59E0B),
                      title: 'Life',
                      subtitle: 'Below suggested cover',
                      badgeText: 'Gap',
                      badgeColor: const Color(0xFFF59E0B),
                      badgeBgColor: const Color(0x1AF59E0B),
                      onTap: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(
                            builder: (context) => const CoverageAnalysisScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Income Protection Card (Gap)
                    _buildAreaCard(
                      icon: Icons.trending_down_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      iconBgColor: const Color(0x1AF59E0B),
                      title: 'Income protection',
                      subtitle: 'No disability cover found',
                      badgeText: 'Gap',
                      badgeColor: const Color(0xFFF59E0B),
                      badgeBgColor: const Color(0x1AF59E0B),
                    ),
                    const SizedBox(height: 12),

                    // Assets Card (Strong)
                    _buildAreaCard(
                      icon: Icons.directions_car_outlined,
                      iconColor: const Color(0xFF16A34A),
                      iconBgColor: const Color(0x1A16A34A),
                      title: 'Assets',
                      subtitle: 'Motor cover active',
                      badgeText: 'Strong',
                      badgeColor: const Color(0xFF16A34A),
                      badgeBgColor: const Color(0x1A16A34A),
                    ),
                    const SizedBox(height: 16),

                    // FINIX Insight Card with solid dark border
                    _buildInsightCard(),
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
            'Protection Report',
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
          // Share/Action button (Right)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.ios_share_rounded,
                color: Color(0xFF475569),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hero Card with Score
  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B2545), Color(0xFF13315C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Radial overlay mockup
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2E75B6).withOpacity(0.5),
                    const Color(0xFF2E75B6).withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FINIX PROTECTION SCORE',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.75),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '68',
                    style: GoogleFonts.fraunces(
                      fontSize: 40,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      letterSpacing: -1.2,
                    ),
                  ),
                  Text(
                    '/100',
                    style: GoogleFonts.fraunces(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x294ADE80), // spring-green 16% opacity
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Good · 2 areas to strengthen',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF86EFAC),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Area Card Helper
  Widget _buildAreaCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBgColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A1628),
                      letterSpacing: -0.14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),

            // Badge
            Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    badgeText,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FINIX Insight Card (Black/Navy outline border)
  Widget _buildInsightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0A1628), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lightbulb Icon Container
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Color(0xFF2E75B6),
              size: 16,
            ),
          ),
          const SizedBox(width: 11),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FA),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'FINIX INSIGHT',
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E75B6),
                      letterSpacing: 0.51,
                    ),
                  ),
                ),
                const SizedBox(height: 5),

                // Text
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF0A1628),
                      height: 1.45,
                    ),
                    children: [
                      const TextSpan(text: 'Closing your '),
                      TextSpan(
                        text: 'life cover gap',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0B2545),
                        ),
                      ),
                      const TextSpan(text: ' would lift your protection score to an estimated '),
                      TextSpan(
                        text: '84/100',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0B2545),
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
