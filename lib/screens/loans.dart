import 'package:flutter/material.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'loan_statement.dart';
import 'simulation.dart';
import '../main.dart';

class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

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
                    // Total Outstanding Hero Card
                    _buildHeroCard(),
                    const SizedBox(height: 24),

                    // Active Loans Heading
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active loans',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0A1628),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              SmoothPageRoute(
                                builder: (context) => const LoanStatementScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Statements →',
                            style: GoogleFonts.inter(
                              fontSize: 12.3,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E75B6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Active Loans List
                    _buildActiveLoansList(context),
                    const SizedBox(height: 24),

                    // FINIX Insight Card
                    _buildInsightCard(context),
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
  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered Title
          Text(
            'Loans',
            style: GoogleFonts.inter(
              fontSize: 15.66,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
            ),
          ),

          // Back Button
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF0A1628),
                  size: 18,
                ),
              ),
            ),
          ),

          // Add Button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add loan flow initiated!')),
                );
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.add,
                  color: Color(0xFF0A1628),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hero Card (Total Outstanding)
  Widget _buildHeroCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B2545), Color(0xFF13315C)],
          ),
        ),
        child: Stack(
          children: [
            // Top Right Glow Overlay
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.5,
                    colors: [
                      const Color(0xFF2E75B6).withOpacity(0.4),
                      const Color(0xFF13315C).withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL OUTSTANDING',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹ 14,82,500',
                    style: GoogleFonts.fraunces(
                      fontSize: 38,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      letterSpacing: -0.96,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '2 active loans · Next EMI 05 Jul',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    color: Colors.white.withOpacity(0.15),
                    thickness: 1,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Monthly EMI
                      _buildHeroStatColumn(
                        value: '₹31,420',
                        label: 'MONTHLY EMI',
                        valueColor: Colors.white,
                      ),
                      // Debt-to-income
                      _buildHeroStatColumn(
                        value: '14%',
                        label: 'DEBT-TO-INCOME',
                        valueColor: const Color(0xFF86EFAC),
                      ),
                      // Missed EMIs
                      _buildHeroStatColumn(
                        value: '0',
                        label: 'MISSED EMIS',
                        valueColor: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStatColumn({
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15.75,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.65),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // Active Loans List
  Widget _buildActiveLoansList(BuildContext context) {
    return Column(
      children: [
        // Card 1: Home Loan
        _buildLoanCard(
          icon: Icons.home_outlined,
          title: 'Home Loan',
          subtitle: 'PSB - 4521  8.4% p.a.',
          repaidText: '₹7,17,500 repaid',
          totalText: '38% of ₹19,00,000',
          progress: 0.38,
          outstanding: '₹11,82,500',
          tenure: '11y 4m',
          interest: '₹2,84,200',
          nextEmiDate: 'Next EMI · 05 Jul',
          nextEmiAmount: '₹24,650',
        ),
        const SizedBox(height: 16),

        // Card 2: Vehicle Loan
        _buildLoanCard(
          icon: Icons.directions_car_outlined,
          title: 'Vehicle Loan',
          subtitle: 'HDFC - 8472 · 9.1% p.a.',
          repaidText: '₹4,90,000 repaid',
          totalText: '62% of ₹7,90,000',
          progress: 0.62,
          outstanding: '₹3,00,000',
          tenure: '2y 8m',
          interest: '₹86,400',
          nextEmiDate: 'Next EMI · 07 Jul',
          nextEmiAmount: '₹6,770',
        ),
      ],
    );
  }

  Widget _buildLoanCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String repaidText,
    required String totalText,
    required double progress,
    required String outstanding,
    required String tenure,
    required String interest,
    required String nextEmiDate,
    required String nextEmiAmount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Icon + Title/Subtitle + Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF2E75B6), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13.96,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'ON TIME',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Row 2: Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 6,
              width: double.infinity,
              color: const Color(0xFFE2E8F0),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2E75B6), Color(0xFF0B2545)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Row 3: Progress Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                repaidText,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF475569),
                ),
              ),
              Text(
                totalText,
                style: GoogleFonts.inter(
                  fontSize: 11.59,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: const Color(0xFFE2E8F0), thickness: 1),
          const SizedBox(height: 12),

          // Row 4: Stats Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLoanStatColumn('OUTSTANDING', outstanding),
              _buildLoanStatColumn('TENURE LEFT', tenure),
              _buildLoanStatColumn('INTEREST PAID', interest),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: const Color(0xFFE2E8F0), thickness: 1),
          const SizedBox(height: 12),

          // Row 5: Next EMI Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                nextEmiDate,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF475569),
                ),
              ),
              Text(
                nextEmiAmount,
                style: GoogleFonts.inter(
                  fontSize: 14.2,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B2545),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoanStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.6,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0A1628),
          ),
        ),
      ],
    );
  }

  // Insight Card
  Widget _buildInsightCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
            child: const Icon(
              Icons.trending_up_rounded,
              color: Color(0xFF2E75B6),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'FINIX INSIGHT',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E75B6),
                      letterSpacing: 0.72,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF0A1628),
                      height: 1.5,
                    ),
                    children: const [
                      TextSpan(text: 'A '),
                      TextSpan(
                        text: '₹50,000 part-prepayment',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0B2545),
                        ),
                      ),
                      TextSpan(text: ' on the vehicle loan could close it about '),
                      TextSpan(
                        text: '7 months early',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0B2545),
                        ),
                      ),
                      TextSpan(text: ' and save an estimated ₹14,200 interest. Your emergency fund stays intact.'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      SmoothPageRoute(
                        settings: const RouteSettings(name: '/simulation'),
                        builder: (context) => const MobileDeviceFrame(child: SimulationScreen()),
                      ),
                    );
                  },
                  child: Text(
                    'Run What-If →',
                    style: GoogleFonts.inter(
                      fontSize: 12.18,
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
