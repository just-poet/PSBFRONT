import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import 'loan_statement.dart';
import 'simulation.dart';
import '../main.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  // Loans come from /v1/portfolio/loans. The two cards below were hardcoded to
  // a PSB home loan and an HDFC vehicle loan, so a customer with different
  // borrowing — or none — still saw those two.
  List<Map<String, dynamic>> _loans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loans = await ApiService.instance.getLoans();
    if (!mounted) return;
    setState(() {
      _loans = loans;
      _loading = false;
    });
  }

  int get _totalEmiPaise => _loans.fold<int>(
      0, (sum, l) => sum + ((l['emiPaise'] as num?)?.toInt() ?? 0));

  int get _totalOutstandingPaise => _loans.fold<int>(
      0, (sum, l) => sum + ((l['outstandingPaise'] as num?)?.toInt() ?? 0));

  int get _longestTenureMonths => _loans.fold<int>(
      0,
      (max, l) => ((l['remainingMonths'] as num?)?.toInt() ?? 0) > max
          ? (l['remainingMonths'] as num).toInt()
          : max);

  /// EMI-weighted so a large home loan dominates a small personal one.
  String get _avgRateLabel {
    if (_loans.isEmpty || _totalEmiPaise == 0) return '--';
    var weighted = 0.0;
    for (final l in _loans) {
      final emi = (l['emiPaise'] as num?)?.toDouble() ?? 0;
      final rate = (l['interestRate'] as num?)?.toDouble() ?? 0;
      weighted += emi * rate;
    }
    return '${(weighted / _totalEmiPaise).toStringAsFixed(2)}%';
  }

  static String money(num paise) {
    final n = (paise / 100).round().abs().toString();
    if (n.length <= 3) return '₹$n';
    final last3 = n.substring(n.length - 3);
    var rest = n.substring(0, n.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    return '₹${groups.join(',')},$last3';
  }

  static IconData iconFor(String loanType) {
    switch (loanType.toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'car':
      case 'vehicle':
      case 'auto':
        return Icons.directions_car_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'personal':
        return Icons.person_outline;
      default:
        return Icons.account_balance_outlined;
    }
  }

  static String titleFor(String loanType) {
    if (loanType.isEmpty) return 'Loan';
    final t = loanType[0].toUpperCase() + loanType.substring(1);
    return '$t Loan';
  }

  static String tenureFor(int months) {
    if (months <= 0) return '--';
    final y = months ~/ 12;
    final m = months % 12;
    return y > 0 ? '${y}y ${m}m' : '${m}m';
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
                          tr('Active loans'),
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
                            tr('Statements →'),
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
            tr('Loans'),
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
                    tr('TOTAL OUTSTANDING'),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    money(_totalOutstandingPaise),
                    style: GoogleFonts.fraunces(
                      fontSize: 38,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      letterSpacing: -0.96,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _loading
                        ? 'Loading your loans…'
                        : '${_loans.length} active '
                            '${_loans.length == 1 ? 'loan' : 'loans'}',
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
                        value: money(_totalEmiPaise),
                        label: 'MONTHLY EMI',
                        valueColor: Colors.white,
                      ),
                      // Was "DEBT-TO-INCOME 14%", but no endpoint returns the
                      // customer's income, so that ratio could only ever be a
                      // constant. The EMI-weighted average rate is derivable.
                      _buildHeroStatColumn(
                        value: _avgRateLabel,
                        label: 'AVG RATE',
                        valueColor: const Color(0xFF86EFAC),
                      ),
                      // Was "MISSED EMIS 0" — repayment history is not exposed
                      // by the loans API, so a hardcoded zero would be a claim
                      // about the customer's record that nothing backs.
                      _buildHeroStatColumn(
                        value: tenureFor(_longestTenureMonths),
                        label: 'LONGEST TENURE',
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
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loans.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            tr('No active loans'),
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < _loans.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          Builder(builder: (context) {
            final l = _loans[i];
            final outstanding = (l['outstandingPaise'] as num?)?.toInt() ?? 0;
            final emi = (l['emiPaise'] as num?)?.toInt() ?? 0;
            final months = (l['remainingMonths'] as num?)?.toInt() ?? 0;
            final rate = (l['interestRate'] as num?)?.toDouble() ?? 0;

            // The API exposes only what is still owed — outstanding, EMI, rate
            // and remaining months. The original principal and the amount
            // already repaid are NOT available, so the card no longer claims
            // "X repaid, N% of Y"; that figure would be invented. What can be
            // derived honestly is the split of the remaining payments between
            // principal and interest, which is what the bar now shows.
            final totalPayable = emi * months;
            final interestLeft = (totalPayable - outstanding).clamp(0, 1 << 62);
            final principalShare =
                totalPayable > 0 ? outstanding / totalPayable : 0.0;

            return _buildLoanCard(
              icon: iconFor((l['loanType'] ?? '').toString()),
              title: titleFor((l['loanType'] ?? '').toString()),
              subtitle: '${l['lender'] ?? 'Lender'} · '
                  '${rate.toStringAsFixed(2)}% p.a.',
              repaidText: '${money(outstanding)} principal left',
              totalText: totalPayable > 0
                  ? 'of ${money(totalPayable)} still payable'
                  : 'schedule unavailable',
              progress: principalShare.toDouble(),
              outstanding: money(outstanding),
              tenure: tenureFor(months),
              interest: money(interestLeft),
              nextEmiDate: 'EMI · monthly',
              nextEmiAmount: money(emi),
            );
          }),
        ],
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
                  tr('ON TIME'),
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
                    tr('FINIX INSIGHT'),
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
                    tr('Run What-If →'),
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
