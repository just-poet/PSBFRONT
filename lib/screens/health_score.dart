import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/health_band.dart';
import 'smooth_route.dart';

class HealthScoreScreen extends StatefulWidget {
  const HealthScoreScreen({super.key});

  @override
  State<HealthScoreScreen> createState() => _HealthScoreScreenState();
}

class _HealthScoreScreenState extends State<HealthScoreScreen> {
  // /v1/health-score/pillars returns the same seven pillars this screen used to
  // hardcode, with the customer's real scores and an explanation per pillar.
  // The old copy ("14% of monthly income", "term life (Rs 1 Cr)") was fixed
  // narrative that contradicted the data for every user but the mock one.
  int _overall = 0;
  String _band = '';
  List<Map<String, dynamic>> _pillars = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final score = await ApiService.instance.getHealthScore();
    if (!mounted) return;
    setState(() {
      _overall = ((score['score300To900'] as num?) ??
              (score['overall_score'] as num?) ??
              0)
          .round();
      _band = (score['band'] ?? '').toString();
      _pillars =
          ((score['pillars'] as List?) ?? []).cast<Map<String, dynamic>>();
      _loading = false;
    });
  }

  /// The backend names pillars in PascalCase; these are the labels the design
  /// uses, kept in the same order the API returns them.
  static Map<String, ({String title, String subtitle, IconData icon})>
      _pillarMeta = {
    'Liquidity': (
      title: 'Liquidity',
      subtitle: 'Cash on hand vs monthly expenses',
      icon: Icons.opacity_outlined
    ),
    'DebtHealth': (
      title: 'Debt Health',
      subtitle: 'Debt-to-income ratio',
      icon: Icons.credit_card_outlined
    ),
    'SavingsBehaviour': (
      title: 'Savings',
      subtitle: 'Monthly saving rate',
      icon: Icons.home_outlined
    ),
    'InvestmentQuality': (
      title: tr('Investments'),
      subtitle: 'Portfolio diversification',
      icon: Icons.trending_up_outlined
    ),
    'ProtectionCoverage': (
      title: tr('Protection'),
      subtitle: 'Insurance coverage',
      icon: Icons.shield_outlined
    ),
    'GoalAlignment': (
      title: tr('Goals'),
      subtitle: 'Progress vs targets',
      icon: Icons.track_changes_outlined
    ),
    'FinancialBehaviour': (
      title: 'Behaviour',
      subtitle: 'Spending consistency',
      icon: Icons.person_outline
    ),
  };

  /// The API grades the overall score into a band; the gauge follows it rather
  /// than being permanently green.
  /// Shared with the dashboard card, so the two cannot disagree about which
  /// band a score falls in.
  HealthBand get band => HealthBand.fromApi(_band, _overall);

  Color get bandColour => band.colour;

  String get bandLabel => tr(band.label);

  static Color colourFor(int score) {
    if (score >= 75) return const Color(0xFF16A34A);
    if (score >= 55) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // color/surface/cloud
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header
            _buildHeader(context),
            
            // 2. Scrollable Body Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Score Gauge Section
                    _buildGaugeSection(),
                    
                    const SizedBox(height: 18),
                    
                    // Section Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        '7-Pillar Breakdown',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A1628), // color/text/ink
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Pillar Cards List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          if (_loading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else
                            for (var i = 0; i < _pillars.length; i++) ...[
                              if (i > 0) const SizedBox(height: 12),
                              Builder(builder: (context) {
                                final pillar = _pillars[i];
                                final name = (pillar['name'] ?? '').toString();
                                final meta = _pillarMeta[name];
                                final score =
                                    ((pillar['score'] as num?) ?? 0).round();
                                final why =
                                    (pillar['xai_explanation'] ?? '').toString();
                                final weight =
                                    ((pillar['weight'] as num?) ?? 0) * 100;
                                return _buildPillarCard(
                                  icon: meta?.icon ?? Icons.insights_outlined,
                                  title: meta?.title ?? name,
                                  subtitle: meta?.subtitle ??
                                      '${weight.round()}% of your score',
                                  score: score,
                                  progressColor: colourFor(score),
                                  descriptionSpans: [
                                    TextSpan(
                                      text: why.isNotEmpty
                                          ? why
                                          : 'Contributes '
                                              '${weight.round()}% of your overall score.',
                                    ),
                                  ],
                                );
                              }),
                            ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header Row containing Back, Title and Info
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
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
                Icons.chevron_left_rounded,
                color: Color(0xFF0A1628),
                size: 20,
              ),
            ),
          ),
          
          // Screen Title
          Text(
            tr('Health Score'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1628),
            ),
          ),
          
          // Info Button
          GestureDetector(
            onTap: () => _showInfoBottomSheet(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF0A1628),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Center gauge section
  Widget _buildGaugeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Gauge Ring Container
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(180, 180),
                  painter: HealthScoreGaugePainter(
                    score: _overall.toDouble(),
                    maxScore: 900,
                    progressColor: bandColour,
                    trackColor: const Color(0xFFEEF2F6),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _loading ? '—' : '$_overall',
                      style: GoogleFonts.fraunces(
                        fontSize: 52,
                        fontWeight: FontWeight.w400,
                        color: bandColour,
                        letterSpacing: -1.56,
                      ),
                    ),
                    Text(
                      '/ 900',
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 18),
          
          // Trend Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF13315C), // color/brand/trust
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _loading ? 'Loading…' : bandLabel,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: const Color(0xFFF8FAFC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pillar Card widget builder
  Widget _buildPillarCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int score,
    required Color progressColor,
    required List<TextSpan> descriptionSpans,
  }) {
    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon, Title details, and Score
          Row(
            children: [
              // Icon Container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF0B2545),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Title / Description Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Score Display
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$score',
                    style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: progressColor,
                    ),
                  ),
                  Text(
                    ' /100',
                    style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Progress Bar
          Container(
            height: 5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(999),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: score / 100.0,
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Bottom details / recommendation description
          Container(
            padding: const EdgeInsets.only(top: 11),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 6),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF0A1628),
                        height: 1.45,
                      ),
                      children: descriptionSpans,
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

  // About Health Score explanatory Bottom Sheet
  void _showInfoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('About Health Score'),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1628),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'The FINIX Health Score is a holistic indicator of your overall financial wellness, calculated out of 900. It updates monthly based on your data across 7 key pillars.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.5,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Liquidity', 'Your cushion of cash vs. fixed monthly obligations.'),
                _buildInfoRow('Debt Health', 'Your leverage ratio. Ideally kept under 35% of monthly income.'),
                _buildInfoRow('Savings', 'Your savings rate. Healthy target is 25% or more.'),
                _buildInfoRow('Investments', 'Your diversification level across distinct asset classes.'),
                _buildInfoRow('Protection', 'Your security net, spanning active health and life insurance plans.'),
                _buildInfoRow('Goals', 'Your savings rate progress compared to primary life goals.'),
                _buildInfoRow('Behaviour', 'Your budget discipline and spending volatility patterns.'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B2545),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      tr('Got it'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Row helper inside info bottom sheet
  Widget _buildInfoRow(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 12, height: 1.4),
          children: [
            TextSpan(
              text: '• $title: ',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A1628)),
            ),
            TextSpan(
              text: desc,
              style: const TextStyle(color: Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for circular progress gauge
class HealthScoreGaugePainter extends CustomPainter {
  final double score;
  final double maxScore;
  final Color progressColor;
  final Color trackColor;

  HealthScoreGaugePainter({
    required this.score,
    required this.maxScore,
    required this.progressColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 10.0;
    final double radius = size.width / 2;
    final center = Offset(radius, radius);
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round; // round cap for premium finish

    // Draw background track ring
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    // Draw sweep indicator ring starting from top (-pi / 2)
    double sweepAngle = (score / maxScore) * 2 * math.pi;
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant HealthScoreGaugePainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.maxScore != maxScore ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
