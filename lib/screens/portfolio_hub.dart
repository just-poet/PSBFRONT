import 'package:flutter/material.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'insurance.dart';
import 'tax_centre.dart';
import 'loans.dart';
import '../services/api_service.dart';

class PortfolioHubScreen extends StatefulWidget {
  const PortfolioHubScreen({super.key});

  @override
  State<PortfolioHubScreen> createState() => _PortfolioHubScreenState();
}

class _PortfolioHubScreenState extends State<PortfolioHubScreen> {
  bool _isLoading = false;
  double _totalPortfolioValue = 1842300.0;
  List<Map<String, dynamic>> _investments = [];
  Map<String, dynamic> _insuranceData = {};
  List<Map<String, dynamic>> _loans = [];

  @override
  void initState() {
    super.initState();
    _loadPortfolioData();
  }

  Future<void> _loadPortfolioData() async {
    if (_isLoading) return;
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final results = await Future.wait([
        ApiService.instance.getInvestments(),
        ApiService.instance.getInsurance(),
        ApiService.instance.getLoans(),
        ApiService.instance.getNetWorth(),
      ]);

      if (mounted) {
        setState(() {
          _investments = results[0] as List<Map<String, dynamic>>;
          _insuranceData = results[1] as Map<String, dynamic>;
          _loans = results[2] as List<Map<String, dynamic>>;

          // Compute total portfolio value
          final double totalInvestments = _investments.fold(0.0, (sum, item) => sum + ((item['currentValuePaise'] ?? 0) / 100));
          if (totalInvestments > 0) {
            _totalPortfolioValue = totalInvestments;
          } else {
            final Map<String, dynamic> nw = results[3] as Map<String, dynamic>;
            _totalPortfolioValue = (nw['netWorth'] ?? 248765000) / 100;
          }
          
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
    // Dynamically build insurance subtitle
    final policiesList = _insuranceData['policies'] as List?;
    final int policiesCount = policiesList?.length ?? 2;
    final double lifeCover = (_insuranceData['totalLifeCoverPaise'] ?? 10000000000) / 100;
    final double healthCover = (_insuranceData['totalHealthCoverPaise'] ?? 100000000) / 100;
    final double totalCoverCr = (lifeCover + healthCover) / 10000000;
    final String insuranceSubtitle = '$policiesCount policies · ₹${totalCoverCr.toStringAsFixed(2)} Cr cover';

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
                onRefresh: _loadPortfolioData,
                color: const Color(0xFF0B2545),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Card (Total Portfolio Value)
                      _buildHeroCard(),
                      const SizedBox(height: 24),

                      // Section Heading
                      Text(
                        'Manage your wealth',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A1628),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Investments Card
                      _buildInvestmentsCard(),
                      const SizedBox(height: 12),

                      // Grid: Insurance and Tax Centre
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  SmoothPageRoute(
                                    builder: (context) => const InsuranceScreen(),
                                  ),
                                );
                              },
                              child: _buildGridCard(
                                icon: Icons.shield_outlined,
                                iconColor: const Color(0xFF16A34A),
                                iconBgColor: const Color(0xFFE8F8F0),
                                title: 'Insurance',
                                subtitle: insuranceSubtitle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  SmoothPageRoute(
                                    builder: (context) => const TaxCentreScreen(),
                                  ),
                                );
                              },
                              child: _buildGridCard(
                                icon: Icons.receipt_long_outlined,
                                iconColor: const Color(0xFF2E75B6),
                                iconBgColor: const Color(0xFFEEF4FA),
                                title: 'Tax Centre',
                                subtitle: 'FY25-26 · save ₹46,800',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Loans Card
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            SmoothPageRoute(
                              builder: (context) => const LoansScreen(),
                            ),
                          );
                        },
                        child: _buildLoansCard(),
                      ),
                      const SizedBox(height: 16),

                      // Finix Insight Card
                      _buildInsightCard(),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
            'Portfolio Hub',
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

  // Hero Card with Gradient
  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF06182E),
            Color(0xFF0B2C56),
            Color(0xFF144580),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL PORTFOLIO VALUE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '₹ ${_formatCurrency(_totalPortfolioValue)}',
              style: GoogleFonts.fraunces(
                fontSize: 38,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_drop_up_rounded,
                  color: Color(0xFF4ADE80),
                  size: 18,
                ),
                const SizedBox(width: 2),
                Text(
                  '+₹42,180 · 2.34% this month',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4ADE80),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Investments Card (Full Width Dark)
  Widget _buildInvestmentsCard() {
    final double totalInvest = _investments.isNotEmpty
        ? _investments.fold(0.0, (sum, item) => sum + ((item['currentValuePaise'] ?? 0) / 100))
        : 1372000.0;
    final int holdings = _investments.isNotEmpty ? _investments.length : 12;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F243E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Investments',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$holdings holdings · ${holdings > 1 ? '2' : '0'} SIPs active',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${_formatCurrency(totalInvest)}',
                        style: GoogleFonts.fraunces(
                          fontSize: 26,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white60,
            size: 20,
          ),
        ],
      ),
    );
  }

  // Grid Card (Insurance / Tax Centre)
  Widget _buildGridCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Icon and chevron row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D1C2E),
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // Loans Card (Full Width White)
  Widget _buildLoansCard() {
    final double totalEmi = _loans.isNotEmpty
        ? _loans.fold(0.0, (sum, item) => sum + ((item['emiPaise'] ?? 0) / 100))
        : 52700.0;
    final int activeLoans = _loans.isNotEmpty ? _loans.length : 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F8F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.monetization_on_outlined,
                    color: Color(0xFF16A34A),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),

                // Text Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loans',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0D1C2E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'EMI Due: ₹${_formatCurrency(totalEmi)} · $activeLoans active loans',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF94A3B8),
            size: 18,
          ),
        ],
      ),
    );
  }

  // Finix Insight Box
  Widget _buildInsightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FA).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spark/Insight Icon
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              color: Color(0xFF2E75B6),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),

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
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E75B6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF44474E),
                      height: 1.4,
                    ),
                    children: const [
                      TextSpan(text: 'Your protection is strong, but '),
                      TextSpan(
                        text: '₹40,000',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B1B1E),
                        ),
                      ),
                      TextSpan(text: ' of 80C room is unused. Reviewing Tax before March may lower your liability.'),
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
