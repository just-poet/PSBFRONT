import 'package:flutter/material.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'regime_comparison.dart';
import 'add_proof.dart';
import 'simulation.dart';
import '../main.dart';
import '../services/api_service.dart';

class TaxCentreScreen extends StatefulWidget {
  const TaxCentreScreen({super.key});

  @override
  State<TaxCentreScreen> createState() => _TaxCentreScreenState();
}

class _TaxCentreScreenState extends State<TaxCentreScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _taxData = {};

  @override
  void initState() {
    super.initState();
    _loadTaxData();
  }

  Future<void> _loadTaxData() async {
    if (_isLoading) return;
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final data = await ApiService.instance.getTaxDashboard();
      if (mounted) {
        setState(() {
          _taxData = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCurrency(double amount) {
    final int value = amount.toInt();
    final String s = value.toString();
    if (s.length <= 3) return s;
    String lastThree = s.substring(s.length - 3);
    String other = s.substring(0, s.length - 3);
    String result = '';
    int count = 0;
    for (int i = other.length - 1; i >= 0; i--) {
      result = other[i] + result;
      count++;
      if (count == 2 && i > 0) {
        result = ',$result';
        count = 0;
      }
    }
    return '$result,$lastThree';
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
              child: RefreshIndicator(
                onRefresh: _loadTaxData,
                color: const Color(0xFF0B2545),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Projected Tax Card
                      _buildProjectedTaxCard(),
                      const SizedBox(height: 24),

                      // Regime Comparison Header
                      _buildSectionHeader(
                        title: 'Regime comparison',
                        actionText: 'How this works →',
                        onActionTap: () {
                          Navigator.push(
                            context,
                            SmoothPageRoute(
                              builder: (context) => const RegimeComparisonScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Regime Comparison Cards
                      _buildRegimeComparison(),
                      const SizedBox(height: 24),

                      // Your Deductions Header
                      _buildSectionHeader(
                        title: 'Your deductions',
                        actionText: 'Add proof →',
                        onActionTap: () {
                          Navigator.push(
                            context,
                            SmoothPageRoute(
                              builder: (context) => const AddProofScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Deductions List
                      _buildDeductionsList(),
                      const SizedBox(height: 16),

                      // FINIX Insight Card
                      _buildInsightCard(context),
                      const SizedBox(height: 20),
                    ],
                  ),
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
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.5),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered Title
          Text(
            'Tax Centre',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D1C2E),
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
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B2545).withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF475569),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Projected Tax Card
  Widget _buildProjectedTaxCard() {
    final int taxPayablePaise = _taxData['taxPayable'] ?? 11284000;
    final double taxPayableRupees = taxPayablePaise / 100;
    final String regime = _taxData['regime'] ?? 'old';
    final String formattedRegime = '${regime[0].toUpperCase()}${regime.substring(1)} regime';

    final int deductionsPaise = _taxData['deductions'] ?? 45000000;
    final double deductionsRupees = deductionsPaise / 100;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B2545),
            Color(0xFF13315C),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Radial glow background style in top right
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2E75B6).withOpacity(0.35),
                    const Color(0xFF13315C).withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROJECTED TAX · FY 2026–27',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '₹ ${_formatCurrency(taxPayableRupees)}',
                    style: GoogleFonts.fraunces(
                      fontSize: 38,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$formattedRegime · After current deductions',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                // Divider
                Container(
                  height: 0.5,
                  color: Colors.white.withOpacity(0.15),
                ),
                const SizedBox(height: 12),
                // Bottom metrics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTaxCardStat(
                      value: '₹${_formatCurrency(deductionsRupees)}',
                      label: 'DEDUCTIONS',
                      valueColor: const Color(0xFF4ADE80),
                    ),
                    _buildTaxCardStat(
                      value: '₹15,600',
                      label: 'STILL POSSIBLE',
                      valueColor: const Color(0xFFEEF4FA),
                    ),
                    _buildTaxCardStat(
                      value: '298 days',
                      label: 'TO 31 MAR',
                      valueColor: const Color(0xFFEEF4FA),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxCardStat({
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
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.65),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // Section Header
  Widget _buildSectionHeader({
    required String title,
    required String actionText,
    required VoidCallback onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0A1628),
          ),
        ),
        GestureDetector(
          onTap: onActionTap,
          child: Text(
            actionText,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E75B6),
            ),
          ),
        ),
      ],
    );
  }

  // Regime Comparison Row
  Widget _buildRegimeComparison() {
    return Row(
      children: [
        // Old Regime (Better for you)
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2E75B6), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B2545).withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      'Old Regime',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹1,12,840',
                      style: GoogleFonts.fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF0B2545),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'With ₹2,42,000 deductions',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              // "Better For You" badge
              Positioned(
                left: 12,
                top: -9,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E75B6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'BETTER FOR YOU',
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // New Regime
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B2545).withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  'New Regime',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹1,27,400',
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF0B2545),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No deductions · Lower slabs',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Deductions List
  Widget _buildDeductionsList() {
    return Column(
      children: [
        // Card 1: Section 80C
        _buildDeductionCard(
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFF2E75B6),
          iconBgColor: const Color(0xFFEEF4FA),
          title: 'Section 80C',
          subtitle: 'ELSS, PPF, LIC, EPF',
          currentVal: '₹1,28,000',
          maxVal: '₹1,50,000',
          progressValue: 128000 / 150000,
          progressBarGradient: const LinearGradient(
            colors: [Color(0xFF2E75B6), Color(0xFF0B2545)],
          ),
          footerLeft: '85% used',
          footerRight: '₹22,000 room left',
          footerRightColor: const Color(0xFFF59E0B),
        ),
        const SizedBox(height: 12),

        // Card 2: Section 80D
        _buildDeductionCard(
          icon: Icons.favorite_border_rounded,
          iconColor: const Color(0xFFC8A951),
          iconBgColor: const Color(0xFFFDF8EB),
          title: 'Section 80D',
          subtitle: 'Health insurance premium',
          currentVal: '₹25,000',
          maxVal: '₹25,000',
          progressValue: 1.0,
          progressBarColor: const Color(0xFFC8A951),
          footerLeft: 'Fully utilised',
          footerRight: '✦ Maxed out',
          footerRightColor: const Color(0xFFC8A951),
        ),
        const SizedBox(height: 12),

        // Card 3: Section 24(b)
        _buildDeductionCard(
          icon: Icons.home_outlined,
          iconColor: const Color(0xFF2E75B6),
          iconBgColor: const Color(0xFFEEF4FA),
          title: 'Section 24(b)',
          subtitle: 'Home loan interest',
          currentVal: '₹64,000',
          maxVal: '₹2,00,000',
          progressValue: 64000 / 200000,
          progressBarColor: const Color(0xFF2E75B6),
          footerLeft: '32% used',
          footerRight: 'Auto-tracked from EMI',
          footerRightColor: const Color(0xFF64748B),
        ),
        const SizedBox(height: 12),

        // Card 4: Section 80TTA
        _buildDeductionCard(
          icon: Icons.credit_card_outlined,
          iconColor: const Color(0xFF2E75B6),
          iconBgColor: const Color(0xFFEEF4FA),
          title: 'Section 80TTA',
          subtitle: 'Savings account interest',
          currentVal: '₹6,200',
          maxVal: '₹10,000',
          progressValue: 6200 / 10000,
          progressBarColor: const Color(0xFF2E75B6),
          footerLeft: '62% used',
          footerRight: 'Across 4 linked banks',
          footerRightColor: const Color(0xFF64748B),
        ),
      ],
    );
  }

  Widget _buildDeductionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String currentVal,
    required String maxVal,
    required double progressValue,
    Color? progressBarColor,
    Gradient? progressBarGradient,
    required String footerLeft,
    required String footerRight,
    required Color footerRightColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: currentVal,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    TextSpan(
                      text: ' / $maxVal',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Custom Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 6,
              width: double.infinity,
              color: const Color(0xFFE2E8F0),
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        width: constraints.maxWidth * progressValue,
                        height: 6,
                        decoration: BoxDecoration(
                          color: progressBarGradient == null ? progressBarColor : null,
                          gradient: progressBarGradient,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                footerLeft,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF475569),
                ),
              ),
              Text(
                footerRight,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: footerRightColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Insight Card
  Widget _buildInsightCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sparkle icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FA),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              color: Color(0xFF2E75B6),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FA),
                    borderRadius: BorderRadius.circular(4),
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
                // Text content
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFF0A1628),
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'A one-time '),
                      TextSpan(
                        text: '₹22,000 ELSS investment',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0B2545),
                        ),
                      ),
                      const TextSpan(
                          text:
                              ' before 31 Mar fills your remaining 80C room and may reduce projected tax by about '),
                      TextSpan(
                        text: '₹6,860',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0B2545),
                        ),
                      ),
                      const TextSpan(text: ' . Estimates, not guarantees.'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Link button
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Run simulation →',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E75B6),
                        ),
                      ),
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
