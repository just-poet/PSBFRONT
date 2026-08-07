import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:finix_dashboard/screens/smooth_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'protection_report.dart';
import 'coverage_analysis.dart';
import 'file_claim.dart';
import 'update_nominee.dart';
import 'documents_download.dart';
import '../services/api_service.dart';

class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key});

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen> {
  // Policies come from /v1/portfolio/insurance. The two cards below were fixed
  // to an LIC term plan and a Star Health floater, so every signed-in customer
  // saw the same cover regardless of what they actually hold.
  Map<String, dynamic> _insurance = const {};
  List<Map<String, dynamic>> _policies = const [];
  int _protectionScore = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      ApiService.instance.getInsurance(),
      ApiService.instance.getHealthScore(),
    ]);
    if (!mounted) return;
    final ins = results[0];
    final health = results[1];
    final pillars = (health['pillars'] as List?) ?? const [];
    final protection = pillars.cast<Map<String, dynamic>>().firstWhere(
          (p) => (p['name'] ?? '').toString() == 'ProtectionCoverage',
          orElse: () => const <String, dynamic>{},
        );
    setState(() {
      _insurance = ins;
      _policies = ((ins['policies'] as List?) ?? const [])
          .cast<Map<String, dynamic>>();
      _protectionScore = ((protection['score'] as num?) ?? 0).round();
      _loading = false;
    });
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

  /// Cover is quoted in crore/lakh on the hero, matching how Indian policies
  /// are actually sold.
  static String compactCover(num paise) {
    final rupees = paise / 100;
    if (rupees >= 10000000) {
      return '${(rupees / 10000000).toStringAsFixed(2)} Cr';
    }
    if (rupees >= 100000) return '${(rupees / 100000).toStringAsFixed(2)} L';
    return rupees.round().toString();
  }

  static String policyTitle(String type) {
    switch (type) {
      case 'term_life':
        return 'Term Life Insurance';
      case 'health':
        return 'Health Insurance';
      case 'motor':
        return 'Motor Insurance';
      case 'personal_accident':
        return 'Personal Accident Cover';
      default:
        if (type.isEmpty) return 'Insurance Policy';
        final words = type.split('_').map(
            (w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1));
        return '${words.join(' ')} Insurance';
    }
  }

  static IconData policyIcon(String type) {
    switch (type) {
      case 'health':
        return Icons.favorite_border_rounded;
      case 'motor':
        return Icons.directions_car_outlined;
      case 'personal_accident':
        return Icons.personal_injury_outlined;
      default:
        return Icons.shield_outlined;
    }
  }

  static String bandFor(int score) {
    if (score >= 80) return 'Strong';
    if (score >= 65) return 'Adequate';
    if (score >= 50) return 'Thin';
    return 'At risk';
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
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Card (Total Cover)
                    _buildHeroCard(),
                    const SizedBox(height: 24),

                    // Section Heading: Your policies
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr('Your policies'),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0A1628),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              SmoothPageRoute(
                                settings: const RouteSettings(name: '/documents_download'),
                                builder: (context) => const DocumentsDownloadScreen(),
                              ),
                            );
                          },
                          child: Text(
                            tr('Documents →'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E75B6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // One card per policy actually held by this customer.
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_policies.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Center(
                          child: Text(
                            tr('No active policies'),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      )
                    else
                      for (var i = 0; i < _policies.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        Builder(builder: (context) {
                          final pol = _policies[i];
                          final type = (pol['policyType'] ?? pol['type'] ?? '')
                              .toString();
                          final cover =
                              (pol['sumAssuredPaise'] as num?)?.toInt() ??
                                  (pol['coverAmountPaise'] as num?)?.toInt() ??
                                  0;
                          final premium =
                              (pol['premiumPaise'] as num?)?.toInt() ?? 0;
                          final insurer =
                              (pol['insurer'] ?? pol['provider'] ?? 'Insurer')
                                  .toString();
                          final id =
                              (pol['policyId'] ?? pol['id'] ?? '').toString();
                          final due =
                              (pol['nextDueDate'] ?? pol['dueDate'] ?? '')
                                  .toString();
                          return _buildPolicyCard(
                            icon: policyIcon(type),
                            title: policyTitle(type),
                            provider: '$insurer · Policy $id',
                            assuredAmount: money(cover),
                            assuredLabel: 'SUM ASSURED',
                            premiumText: 'Premium ${money(premium)}/mo',
                            renewalText:
                                due.isEmpty ? 'Renewal date pending' : 'Renews $due',
                          );
                        }),
                      ],
                    const SizedBox(height: 24),

                    // Section Heading: Coverage analysis
                    Text(
                      tr('Coverage analysis'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Coverage Gap Card
                    _buildCoverageGapCard(context),
                    const SizedBox(height: 12),

                    // Finix Insight Card
                    _buildInsightCard(context),
                    const SizedBox(height: 24),

                    // Section Heading: Quick actions
                    Text(
                      tr('Quick actions'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Action: File a claim
                    _buildQuickActionTile(
                      icon: Icons.assignment_outlined,
                      title: 'File a claim',
                      subtitle: 'Guided process · Avg 4 days settlement',
                      onTap: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(
                            builder: (context) => const FileClaimScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Quick Action: Update nominee
                    _buildQuickActionTile(
                      icon: Icons.person_add_alt_1_outlined,
                      title: 'Update nominee',
                      subtitle: 'Current: 1 nominee on both policies',
                      onTap: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(
                            builder: (context) => const UpdateNomineeScreen(),
                          ),
                        );
                      },
                    ),
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
            tr('Insurance'),
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
                  Icons.chevron_left_rounded,
                  color: Color(0xFF475569),
                  size: 24,
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
      height: 190,
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
        clipBehavior: Clip.antiAlias,
        children: [
          // Radial Gradient Mesh Glow decoration
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

          // Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL COVER · ${_policies.length} ACTIVE '
                  '${_policies.length == 1 ? 'POLICY' : 'POLICIES'}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 1.2,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '₹',
                            style: GoogleFonts.fraunces(
                              fontSize: 30,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: ' ${compactCover((_insurance['totalCoverPaise'] as num?) ?? 0)}',
                            style: GoogleFonts.fraunces(
                              fontSize: 37,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  'Protection pillar score $_protectionScore / 100 '
                  '· ${bandFor(_protectionScore)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Policy Card Helper
  Widget _buildPolicyCard({
    required IconData icon,
    required String title,
    required String provider,
    required String assuredAmount,
    required String assuredLabel,
    required String premiumText,
    required String renewalText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      provider,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tr('ACTIVE'),
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF16A34A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sum Assured Value
          Text(
            assuredAmount,
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF0B2545),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            assuredLabel,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),

          // Divider
          const Divider(color: Color(0xFFE2E8F0), thickness: 0.8, height: 1),
          const SizedBox(height: 12),

          // Footer Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                premiumText,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF475569),
                ),
              ),
              Text(
                renewalText,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0A1628),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Coverage Gap Card Helper
  Widget _buildCoverageGapCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('COVERAGE GAP'),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF59E0B),
                        letterSpacing: 0.72,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF0A1628),
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: 'You have no '),
                          TextSpan(
                            text: 'personal accident cover',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0B2545),
                            ),
                          ),
                          const TextSpan(
                            text: ' . With a vehicle loan active, a disability event could strain EMIs. A ₹50L PA cover costs about ',
                          ),
                          TextSpan(
                            text: '₹85/mo',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0B2545),
                            ),
                          ),
                          const TextSpan(
                            text: ' . This is observational, not a recommendation.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 46.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(
                    builder: (context) => const CoverageAnalysisScreen(),
                  ),
                );
              },
              child: Text(
                tr('Coverage →'),
                style: GoogleFonts.inter(
                  fontSize: 12,
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

  // Finix Insight Card Helper
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
            color: const Color(0xFF0B2545).withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FA),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.auto_awesome_outlined, color: Color(0xFF2E75B6), size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF4FA),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tr('FINIX INSIGHT'),
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E75B6),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF0A1628),
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: 'Your term cover is '),
                          TextSpan(
                            text: '14× annual income',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0B2545),
                            ),
                          ),
                          const TextSpan(
                            text: ' — above the 10× rule of thumb. Health cover of ₹10L is adequate today; review after any family addition.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 44.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(
                    builder: (context) => const ProtectionReportScreen(),
                  ),
                );
              },
              child: Text(
                tr('Full protection report →'),
                style: GoogleFonts.inter(
                  fontSize: 12,
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

  // Quick Action List Tile Helper
  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A1628),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF475569),
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
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Status Bar Widget (Consistent with Portfolio Hub)
// ---------------------------------------------------------------------
class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
